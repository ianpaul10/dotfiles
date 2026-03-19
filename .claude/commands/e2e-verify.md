---
name: e2e-verify
description: 'Verify frontend changes on admin-web using agent-browser. Supports preview deployments and local dev assets. Use when: pushing frontend changes, user says "verify my changes", checking preview deployment, visual regression testing, after completing UI work. Flags: --local for local vite assets, --record for video recording.'
argument-hint: "[--local] [--record] [url-or-path]"
---

# E2E Verification for Admin-Web

Verify frontend changes using `agent-browser`.

| Flag | Purpose |
|------|---------|
| (none) | **Preview mode** — headless browser, `https://{SHA}.preview.admin.shopify.com/store/overroasted` |
| `--local` | **Local mode** — headed browser, production admin URL, local vite assets |
| `--record` | **Record session** — captures WebM video of the entire verification session |

Flags can be combined: `--local --record` records a local verification session.

**Arguments:** `$ARGUMENTS`

**Store:** Overroasted (handle: `overroasted`)

## Flag Detection

Parse `$ARGUMENTS` for flags:
- `--local`: use **local mode** (headed browser, production admin URL, local vite assets)
- `--record`: enable **video recording** (start recording before first navigation, stop after report)
- Neither: use **preview mode** (headless browser, preview URL from commit SHA)

## Recording (`--record`)

When `--record` flag is present, wrap the entire verification session in a video recording.

### Start recording (after browser opens, BEFORE first navigation)

```bash
# Create results dir first (needed for video path)
RUN_ID="$(date +%Y%m%d_%H%M%S)_$SHORT_SHA"
RESULTS_DIR="$HOME/.claude/projects/-Users-edwinchan-world-trees-root-src-areas-clients-admin-web/e2e/results/$RUN_ID"
mkdir -p "$RESULTS_DIR/setup" "$RESULTS_DIR/verify"

VIDEO_PATH="$RESULTS_DIR/session.webm"

# Start recording BEFORE navigating
agent-browser record start "$VIDEO_PATH"
```

### Stop recording (after all verification steps, BEFORE closing browser)

```bash
agent-browser record stop
```

The video is saved to `$RESULTS_DIR/session.webm`. Include the path in the report output.

### Recording + report integration

When recording is active, the report should include:
- Video path in `results.json`: `"video": "session.webm"`
- Video path in `summary.md`: `**Video**: \`session.webm\``
- Video path in conversation output: `Video: <RESULTS_DIR>/session.webm`

The video can be attached to PR descriptions for tophat evidence.

## Local Mode (`--local`)

**Prerequisites:** User must have `dev server` (or `dev prod vite`) running locally.

**Key differences from preview mode:**
- Uses `--headed` flag on ALL `agent-browser` commands (headless cannot reach localhost)
- Navigates to `https://admin.shopify.com/store/overroasted/{path}` (NOT preview URL)
- Enables "Use local vite assets" in DevUI Settings > Assets section
- Tests the current working directory code (no push needed)

### Local mode startup sequence

```bash
# 1. Launch in headed mode with session persistence
agent-browser --headed --session-name shopify-admin-e2e open "https://admin.shopify.com/store/overroasted"
agent-browser wait --load networkidle --timeout 30000

# 2. Check if authenticated (if not, user logs in via the visible browser window)

# 3. Enable local vite assets in DevUI:
#    - Open DevUI (click performance indicator in bottom-right)
#    - Go to Settings tab (gear icon)
#    - Under "Assets", select "Use local vite assets" radio button
#    - Click "(refresh required)" to reload

# 4. Enable feature flags if needed (same DevUI flow as preview mode)

# 5. Navigate to the target page and verify
```

**IMPORTANT:** In local mode, ALL `agent-browser` commands must use the existing headed session. Do NOT close and reopen the browser between steps — the headed session persists local asset selection and flag overrides.

## When to Use

- After pushing any frontend changes to admin-web (preview mode)
- When running `dev server` locally and testing unpushed changes (local mode with `--local`)
- Before moving from Phase 5 (Test) to Phase 6 (Review) in admin-web-feature workflow
- When a user asks to "verify", "check", or "test" their UI changes
- After resolving a UI bug to confirm the fix
- Agents MUST use this skill to verify any UI-visible changes before claiming completion

## Core Principles

1. **DOM first, screenshots second** — Use `snapshot` and `eval` for element discovery and assertions. Take screenshots only for evidence or when DOM inspection fails.
2. **Computed styles prove CSS changes** — For visual changes like hover effects, backgrounds, borders: verify via `getComputedStyle()`, not pixel comparison.
3. **Auto-detect feature flags** — Grep changed files for `useBeta`/`FLAG_` patterns and enable flags via DevUI before testing.
4. **Web components need eval** — Shopify admin uses `<s-internal-*>` web components that don't appear in `snapshot`. Use `agent-browser eval` with `document.querySelector` to find and interact with them.
5. **Separate Bash calls** — NEVER chain variable assignments with `agent-browser` commands using `&&`. Set up variables (RESULTS_DIR, etc.) in one Bash call, then run each `agent-browser` command as its own separate Bash call. This ensures permission rules like `Bash(agent-browser:*)` can match. Inline literal paths instead of using variable references when possible.

## Workflow

```
1. CONTEXT    → Understand what changed (PR files, commit message)
2. CRITERIA   → Define testable acceptance criteria
3. FLAGS      → Auto-detect and enable required feature flags
4. PREPARE    → Get preview URL, ensure deployment is live
5. AUTH       → Establish authenticated session
6. VERIFY     → DOM-first interaction and assertions
7. EVIDENCE   → Capture organized artifacts
8. REPORT     → Structured pass/fail with evidence paths
```

---

## Step 1: CONTEXT — Understand What Changed

Before defining criteria, understand the PR scope:

```bash
# Get PR info
gh pr view <PR_NUMBER> --json title,body,files,headRefName

# Or from current branch
git log --oneline -1
git diff main --name-only
```

From the changed files, identify:
- **Which component** was modified (the target to test)
- **Which route/page** renders that component (the URL to navigate to)
- **What type of change** (CSS, interaction, new component, data display)

### Auto-detect feature flags

Search changed files AND their imports for beta flag usage:

```bash
# Get changed files relative to main
CHANGED_FILES=$(git diff main --name-only | grep -E '\.(tsx?|css)$')

# Search those files and their parent directories for flag usage
grep -rn 'useBeta\|FLAG_' $CHANGED_FILES $(dirname $CHANGED_FILES | sort -u) 2>/dev/null | grep -v node_modules | grep -v '.test.'
```

If flags are found (e.g., `FLAG_MULTI_CHANNELS_UI`), look up the flag name in `packages/util/beta/beta-names.ts`:

```bash
grep 'FLAG_MULTI_CHANNELS_UI' packages/util/beta/beta-names.ts
# → export const FLAG_MULTI_CHANNELS_UI: Beta<'f_multi_channels_ui'> = beta('f_multi_channels_ui');
```

The string inside `beta('...')` is the flag name to enable in DevUI.

---

## Step 2: CRITERIA — Define Acceptance Criteria

Write 3-8 specific, testable criteria. Each criterion should specify:
- **What to check** (element, style, behavior)
- **How to verify** (DOM query, computed style, interaction result)

Example for a CSS hover change:
```
- [ ] Button background is transparent when not hovered (getComputedStyle → rgba(0,0,0,0))
- [ ] Button background changes on hover (getComputedStyle → non-transparent)
- [ ] Button click still triggers expected action (expand/collapse/navigate)
- [ ] No JS errors in console during interaction
```

If the user didn't specify criteria, derive from: PR description, commit message, changed component purpose.

---

## Step 3: FLAGS — Enable Feature Flags via DevUI

Skip this step if no flags were detected in Step 1.

### DevUI flag toggle recipe

```bash
# 1. Open DevUI
agent-browser eval "document.querySelector('button[interestfor=\"devui-tab-settings\"]')?.closest('[class*=Tab]') || 'devui not found'"

# If DevUI is collapsed, open it:
agent-browser eval "(() => {
  var btn = [...document.querySelectorAll('button')].find(b => b.textContent.includes('Open developer UI'));
  if (btn) { btn.click(); return 'opened'; }
  return 'already open or not found';
})()"

# 2. Click Settings tab
agent-browser eval "document.querySelector('button[interestfor=\"devui-tab-settings\"]').click()"

# 3. Open Beta overrides (note: button text uses Greek β)
agent-browser eval "(() => {
  var btn = [...document.querySelectorAll('button')].find(b => b.textContent.includes('eta overrides'));
  if (btn) { btn.click(); return 'opened'; }
  return 'not found';
})()"

# 4. Filter for the flag
agent-browser find placeholder "Filter beta flags" fill "<flag_name>"

# 5. Enable the flag (Polaris checkbox needs dispatchEvent)
agent-browser eval "(() => {
  var cbs = document.querySelectorAll('input[type=checkbox]');
  var target = [...cbs].find(cb => {
    var label = cb.closest('label, div')?.textContent || '';
    return label.includes('<flag_name>');
  });
  if (target && !target.checked) {
    target.dispatchEvent(new MouseEvent('click', {bubbles: true}));
    return 'enabled';
  }
  return target?.checked ? 'already enabled' : 'not found';
})()"

# 6. Reload to apply
agent-browser reload
agent-browser wait --load networkidle --timeout 30000
```

Replace `<flag_name>` with the actual flag (e.g., `multi_channels_ui`).

---

## Step 4: PREPARE — Preview URL and Deployment

### Get identifiers

```bash
COMMIT_SHA=$(git rev-parse HEAD)
SHORT_SHA=$(git rev-parse --short HEAD)
BRANCH=$(git rev-parse --abbrev-ref HEAD)
```

If testing a PR, use the PR's pushed commit SHA (from `gh pr view`), not local HEAD.

### Generate preview URL

```bash
PREVIEW_BASE="https://$COMMIT_SHA.preview.admin.shopify.com"
PREVIEW_URL="$PREVIEW_BASE/store/overroasted"
```

Append the specific admin path being tested (e.g., `/products/15000621809686`).

### Ensure deployment

```bash
dev preview check        # Check if deployed
dev preview wait         # Trigger build + wait (10-20 min)
```

---

## Step 5: AUTH — Session Persistence

Use `--session-name shopify-admin-e2e` for cookie persistence across runs.

### Navigate to preview

```bash
agent-browser --session-name shopify-admin-e2e open "$PREVIEW_URL"
agent-browser wait --load networkidle --timeout 30000
```

### Check if authenticated

```bash
CURRENT_URL=$(agent-browser get url)
```

If URL contains `/login` or `/auth` → session expired, need login.

### Login flow (when needed)

Launch in **headed mode** so the user can complete login (including MFA):

```bash
agent-browser close
agent-browser --headed --session-name shopify-admin-e2e open "https://admin.shopify.com/store/overroasted"
```

Tell the user: "A browser window appeared. Please log in. Let me know when you're on the admin dashboard."

After login confirmation, navigate to the preview:

```bash
agent-browser open "$PREVIEW_URL/{admin_path}"
agent-browser wait --load networkidle --timeout 30000
```

The session is now saved. All subsequent runs use headless with `--session-name shopify-admin-e2e`.

---

## Step 6: VERIFY — DOM-First Assertions

### Discovery order

1. **`agent-browser snapshot`** — accessibility tree with refs. Covers standard HTML elements.
2. **`agent-browser eval`** — for web components (`<s-internal-*>`) and elements not in the accessibility tree.
3. **`agent-browser screenshot`** — visual fallback when DOM inspection is insufficient.

### Finding elements

**Standard elements** (buttons, links, inputs, headings):
```bash
agent-browser snapshot | grep -i "keyword"
agent-browser click "@e42"
```

**Web components** (`<s-internal-button>`, `<s-internal-icon>`, etc.):
```bash
agent-browser eval "document.querySelector('s-internal-button[accessibilitylabel=\"Manage publishing\"]').click()"
```

**Position-based discovery** (when name/label unknown):
```bash
agent-browser eval "JSON.stringify([...document.querySelectorAll('button, a')].filter(b => {
  var r = b.getBoundingClientRect();
  return r.x > 1100 && r.y > 230 && r.y < 280;
}).map(b => ({label: b.getAttribute('aria-label'), text: b.textContent.trim().substring(0, 40)})))"
```

### Verifying CSS changes

For hover/focus effects, assert via computed styles:

```bash
# Verify non-hover state
agent-browser mouse move 0 0
agent-browser eval "window.getComputedStyle(document.querySelector('<selector>')).backgroundColor"

# Trigger hover
agent-browser hover "<selector>"
agent-browser wait 300

# Verify hover state
agent-browser eval "window.getComputedStyle(document.querySelector('<selector>')).backgroundColor"
```

Capture the results in structured format for the report.

### Verifying interactions

```bash
# Click and verify state change
agent-browser click "<selector>"
agent-browser wait 500

# Check: did aria-expanded change?
agent-browser eval "document.querySelector('<selector>').getAttribute('aria-expanded')"

# Check: did child elements appear?
agent-browser snapshot | grep "expected-child-text"
```

### Checking for errors

```bash
# Only JS errors, not CSP/debug/warning noise
agent-browser eval "(() => {
  var errors = [];
  var origError = console.error;
  console.error = function() { errors.push([...arguments].join(' ')); origError.apply(console, arguments); };
  return errors;
})()"
```

Or after the test:
```bash
agent-browser errors
```

Filter out known noise: CSP warnings, bugsnag debug, Polaris deprecation warnings.

---

## Step 7: EVIDENCE — Organized Artifacts

### Create results directory

```bash
RUN_ID="$(date +%Y%m%d_%H%M%S)_$SHORT_SHA"
RESULTS_DIR="$HOME/.claude/projects/-Users-edwinchan-world-trees-root-src-areas-clients-admin-web/e2e/results/$RUN_ID"
mkdir -p "$RESULTS_DIR/setup" "$RESULTS_DIR/verify"
```

### Directory structure

```
<run-id>/
├── setup/              # DevUI, flag toggling, navigation screenshots
│   ├── 01-page-load.png
│   ├── 02-flag-enabled.png
│   └── ...
├── verify/             # Actual verification evidence
│   ├── 01-before.png
│   ├── 02-during-hover.png
│   ├── 03-after-click.png
│   └── ...
├── results.json        # Structured test results (machine-readable)
├── summary.md          # Human-readable report
├── snapshot.txt        # Final accessibility tree
└── errors.txt          # Filtered JS errors only (omit if none)
```

### results.json — Structured data

Capture verification data in JSON, not just screenshots:

```json
{
  "runId": "<RUN_ID>",
  "commit": "<COMMIT_SHA>",
  "branch": "<BRANCH>",
  "previewUrl": "<PREVIEW_URL>",
  "timestamp": "<ISO_DATE>",
  "flags": ["f_multi_channels_ui"],
  "result": "PASS",
  "criteria": [
    {
      "description": "Hover background appears on chevron button",
      "result": "PASS",
      "evidence": {
        "type": "computed_style",
        "selector": "button[aria-label='Expand Test Sales Channel']",
        "property": "backgroundColor",
        "expected": "non-transparent",
        "actual": "rgba(0, 0, 0, 0.05)",
        "screenshot": "verify/02-during-hover.png"
      }
    }
  ],
  "errors": []
}
```

### What to capture

| Artifact | When | Directory |
|----------|------|-----------|
| Page load screenshot | After navigation | `setup/` |
| Flag enabled confirmation | After DevUI toggle | `setup/` |
| Before-state screenshot | Before interaction | `verify/` |
| During-state screenshot | During hover/focus | `verify/` |
| After-state screenshot | After click/submit | `verify/` |
| Computed styles | For CSS changes | `results.json` |
| Accessibility snapshot | Final page state | root |
| JS errors | Filtered (no CSP/debug noise) | root |

### Filtering console output

Only capture actual errors, not noise:

```bash
agent-browser errors 2>&1 | grep -v "Content Security Policy" | grep -v "bugsnag" | grep -v "deprecated parameters" > "$RESULTS_DIR/errors.txt"

# Only create the file if there are actual errors
if [ ! -s "$RESULTS_DIR/errors.txt" ]; then
  rm "$RESULTS_DIR/errors.txt"
fi
```

---

## Step 8: REPORT — Output Summary

### Write summary.md

Generate the summary programmatically (do NOT use single-quoted heredoc with variables):

```bash
cat > "$RESULTS_DIR/summary.md" << EOF
# E2E Verification Report

- **Run ID**: $RUN_ID
- **Commit**: $COMMIT_SHA
- **Branch**: $BRANCH
- **Preview URL**: $PREVIEW_URL
- **Date**: $(date -u +"%Y-%m-%d %H:%M UTC")
- **Feature Flags**: ${FLAGS_ENABLED:-none}
- **Result**: $RESULT

## Acceptance Criteria

$CRITERIA_RESULTS

## Evidence

See \`verify/\` for screenshots and \`results.json\` for structured data.
EOF
```

### Conversation output

```
E2E Verification: [PASS/FAIL]
Run ID: <RUN_ID>
Results: <RESULTS_DIR>

Criteria:
- [x] Criterion 1 — PASS (evidence: computed bg = rgba(...))
- [ ] Criterion 2 — FAIL: <reason>
```

---

## Quick Reference

### agent-browser commands used most

| Command | Purpose |
|---------|---------|
| `snapshot` | Accessibility tree — find elements by ref |
| `eval "<js>"` | Run JS — web components, computed styles, DOM queries |
| `click "@eN"` | Click element by snapshot ref |
| `hover "<selector>"` | Trigger CSS :hover state |
| `screenshot <path>` | Capture viewport |
| `screenshot <path> --full` | Capture full page |
| `get url` | Check current URL (auth detection) |
| `wait --load networkidle` | Wait for page to finish loading |
| `errors` | Get JS errors from console |
| `mouse move 0 0` | Move mouse away (clear hover state) |
| `find role button --name "X" click` | Click by accessible name |
| `--session-name shopify-admin-e2e` | Persist auth cookies |
| `--headed` | Show browser window (for login) |
| `reload` | Reload page (apply flag changes) |
| `record start <path.webm>` | Start video recording (WebM) |
| `record stop` | Stop and save video recording |

### Selector priority

1. **Snapshot ref**: `@e42` (from `snapshot` output)
2. **aria-label**: `button[aria-label="Expand Hydrogen"]`
3. **Web component attr**: `s-internal-button[accessibilitylabel="Manage publishing"]`
4. **Position-based eval**: `getBoundingClientRect()` filtering
5. **CSS selector**: `"[data-testid='save-btn']"` (last resort)

### DevUI tab IDs

Navigate directly via `interestfor` attribute:
```bash
agent-browser eval "document.querySelector('button[interestfor=\"devui-tab-settings\"]').click()"
```

| Tab ID | Name |
|--------|------|
| `devui-tab-settings` | Settings (Beta overrides live here) |
| `devui-tab-performance` | Page Health |
| `devui-tab-accessibility` | Accessibility |
| `devui-tab-sandbox` | Sandbox |
| `devui-tab-pageContext` | Quick Copy Page Context |
| `devui-tab-ubercorn` | Ubercorn |

### Known quirks

- **"βeta overrides" uses Greek β** — search for `eta overrides` to match regardless
- **Polaris checkboxes need dispatchEvent** — `agent-browser check` may timeout; use `eval` with `dispatchEvent(new MouseEvent('click', {bubbles: true}))`
- **Web components (`<s-internal-*>`) are invisible to `snapshot`** — always fall back to `eval` + `querySelector` for these
- **CSP warnings are noise** — filter out `Content Security Policy`, `bugsnag`, `deprecated parameters` from error output
- **Headless mode cannot reach localhost** — Chromium sandbox blocks localhost in headless mode. Use `--headed` (or `--local` flag) for local asset testing. Neither `--headless=new`, `--disable-features=NetworkServiceSandbox`, nor UA spoofing fixes this.
- **`dev preview` may fail in worktree setups** — `gt submit` doesn't always update local remote tracking refs. Use `devx ci trigger` or the preview URL directly if `dev preview` says "commit not pushed."

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Preview returns 404 | Deployment not ready. Run `dev preview wait` |
| Login redirect | Use `--headed` mode, ask user to log in manually |
| Element not found in snapshot | Try `eval` — it may be a web component |
| Hover style not showing | Verify selector targets the right element, check with `getComputedStyle` |
| Polaris checkbox won't toggle | Use `dispatchEvent(new MouseEvent('click', {bubbles: true}))` |
| agent-browser not found | `npm install -g agent-browser && agent-browser install` |
| Chromium version mismatch | `npx playwright@latest install chromium` |
| Local Asset Server Error (headless) | Headless Chromium cannot reach localhost. Use `--local` flag or `--headed` |
| `dev preview` says "commit not pushed" | Run `git fetch origin <branch>:<refs/remotes/origin/branch>` or use `devx ci trigger` |
