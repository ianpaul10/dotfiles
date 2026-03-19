---
name: browser-run
description: 'Run plain-language browser steps with optional per-step assertions. Accepts a steps file or inline steps. Flags: --local (headed), --record (video).'
argument-hint: "[--local] [--record] <steps-file | \"url | step1 >> assert1 | step2 | step3 >> assert3\">"
---

# Browser Run

Execute plain-language browser steps with optional per-step assertions using `agent-browser`.

| Flag | Purpose |
|------|---------|
| `--local` | **Headed mode** — shows browser window |
| `--record` | **Record session** — captures WebM video |

**Arguments:** `$ARGUMENTS`

## Flag Detection

Parse `$ARGUMENTS` for flags:
- `--local`: use **headed mode** (`--headed` on all agent-browser commands)
- `--record`: enable **video recording**
- Strip flags from arguments before parsing steps

## Input Parsing

After stripping flags, detect input mode from remaining argument:

**File mode** — if argument ends in `.md`, `.yaml`, `.txt`, or resolves as a file path:
```
/browser-run path/to/steps.md
```

Steps file format:
```
url: https://example.com/path

1. Click the Login button
2. Fill email with "test@example.com" >> email field shows test@example.com
3. Click Submit >> dashboard heading is visible
```

- `url:` line sets the starting URL
- Numbered steps are the instructions
- `>>` within a step separates instruction from assertion (assertion is optional)

**Inline mode** — everything else:
```
/browser-run "https://example.com | click login | fill email >> email shows value | click submit >> dashboard visible"
```

- `|` separates tokens
- First token: starting URL if it looks like a URL (`http://` or `https://`), otherwise step 1
- `>>` within a token separates instruction from assertion

Parse each step into: `{ n, instruction, assertion? }`

## Recording (`--record`)

When `--record` is present, wrap the entire session in video:

```bash
# Create results dir first
RUN_ID="$(date +%Y%m%d_%H%M%S)"
RESULTS_DIR="$HOME/.claude/browser-run/results/$RUN_ID"
mkdir -p "$RESULTS_DIR/steps"
VIDEO_PATH="$RESULTS_DIR/session.webm"
```

```bash
# Start recording BEFORE first navigation
agent-browser record start "$RESULTS_DIR/session.webm"
```

```bash
# Stop AFTER all steps complete
agent-browser record stop
```

Include `"video": "session.webm"` in `results.json` and report output when recording.

## Setup

```bash
RUN_ID="$(date +%Y%m%d_%H%M%S)"
RESULTS_DIR="$HOME/.claude/browser-run/results/$RUN_ID"
mkdir -p "$RESULTS_DIR/steps"
```

## Auth — Session Persistence

Use `--session-name browser-run` for cookie persistence.

### Open browser

**Default (headless):**
```bash
agent-browser --session-name browser-run open "<URL>"
agent-browser wait --load networkidle --timeout 30000
```

**With `--local` flag:**
```bash
agent-browser --headed --session-name browser-run open "<URL>"
agent-browser wait --load networkidle --timeout 30000
```

### Check authentication

```bash
CURRENT_URL=$(agent-browser get url)
```

If URL contains `/login` or `/auth` and headed mode is not already active:
```bash
agent-browser close
agent-browser --headed --session-name browser-run open "<URL>"
```
Tell the user: "A browser window appeared. Please log in, then let me know when you're ready."

After login confirmation, re-navigate to the target URL (headless if no `--local`).

## Execute Loop

For each step `{ n, instruction, assertion? }`:

### 1. Execute instruction (DOM-first)

Discovery order:
1. **`agent-browser snapshot`** → find element by ref, then click/fill/etc.
2. **`agent-browser eval`** → for web components or elements not in accessibility tree
3. **`agent-browser find`** → find by role/name and act

Always take a screenshot after each step:
```bash
agent-browser screenshot "$RESULTS_DIR/steps/<NN>-<slug>.png"
```

### 2. Verify assertion (if present)

Assertion verification hierarchy:
1. **`eval`** — check DOM property, attribute, text content, or value
2. **`snapshot`** — check accessibility tree for expected text/role
3. **`getComputedStyle`** — for CSS/visual assertions

```bash
# Text content assertion
agent-browser eval "document.querySelector('<selector>')?.textContent?.includes('<expected>')"

# Input value assertion
agent-browser eval "document.querySelector('input[name=\"title\"]')?.value"

# Visibility assertion
agent-browser snapshot | grep -i "<expected text>"

# CSS assertion
agent-browser eval "window.getComputedStyle(document.querySelector('<selector>')).backgroundColor"
```

Record result:
- `PASS` — assertion verified
- `FAIL` — assertion failed (capture actual value)
- No assertion → `EXECUTED`

If instruction fails entirely: record `ERROR`, capture screenshot, continue to next step.

## Results

### results.json schema

```json
{
  "runId": "<timestamp>",
  "url": "<starting URL>",
  "timestamp": "<ISO date>",
  "result": "PASS|FAIL",
  "video": "session.webm",
  "steps": [
    {
      "n": 1,
      "instruction": "Click the Login button",
      "assertion": null,
      "result": "EXECUTED",
      "screenshot": "steps/01-click-login.png"
    },
    {
      "n": 2,
      "instruction": "Fill email with test@example.com",
      "assertion": "email field shows test@example.com",
      "result": "PASS",
      "evidence": { "type": "eval", "actual": "test@example.com" },
      "screenshot": "steps/02-fill-email.png"
    }
  ]
}
```

Step results:
- `EXECUTED` — no assertion, step ran without error
- `PASS` — assertion verified
- `FAIL` — assertion failed (include actual vs expected in `evidence`)
- `ERROR` — instruction could not be executed

Overall `result`: `PASS` if all assertions passed, `FAIL` if any assertion failed or errored.

### summary.md

```bash
cat > "$RESULTS_DIR/summary.md" << EOF
# Browser Run Report

- **Run ID**: $RUN_ID
- **URL**: $START_URL
- **Date**: $(date -u +"%Y-%m-%d %H:%M UTC")
- **Result**: $OVERALL_RESULT

## Steps

$STEP_RESULTS

## Evidence

Screenshots in \`steps/\`. Structured data in \`results.json\`.
EOF
```

### Conversation output

```
Browser Run: [PASS/FAIL]
Run ID: <RUN_ID>
Results: <RESULTS_DIR>

Steps:
- [x] 1. Click Login — EXECUTED
- [x] 2. Fill email — PASS (actual: "test@example.com")
- [ ] 3. Click Submit — FAIL: expected "dashboard heading" not found
```

## Core Principles

1. **DOM first, screenshots second** — Use `snapshot` and `eval` for discovery and assertions. Screenshots are evidence only.
2. **Separate Bash calls** — NEVER chain variable assignments with `agent-browser` using `&&`. Set variables in one Bash call, run each `agent-browser` command as its own separate Bash call.
3. **Inline literal paths** — Use literal expanded paths in agent-browser calls, not shell variables, when possible.
4. **Continue on error** — If a step errors, record it and continue to the next step rather than aborting.
5. **Session persistence** — Always use `--session-name browser-run` so auth cookies persist across runs.

## Quick Reference

| Command | Purpose |
|---------|---------|
| `snapshot` | Accessibility tree — find elements by ref |
| `eval "<js>"` | Run JS — DOM queries, computed styles, values |
| `click "@eN"` | Click element by snapshot ref |
| `find role button --name "X" click` | Click by accessible name |
| `screenshot <path>` | Capture viewport as evidence |
| `get url` | Check current URL |
| `wait --load networkidle` | Wait for page load |
| `--session-name browser-run` | Persist auth cookies |
| `--headed` | Show browser window |
| `record start <path.webm>` | Start video recording |
| `record stop` | Stop and save video |
