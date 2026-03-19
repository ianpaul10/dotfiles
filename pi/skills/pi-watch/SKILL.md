---
name: pi-watch
description: Watches source files in the current project for AI-tagged comments and responds automatically. Use this when the user wants to write AI instructions directly in their code using comments (# AI!, # AI?, // AI!, etc.) and have pi respond or edit inline — similar to Aider's --watch-files mode. Activate with phrases like "start watching", "watch for AI comments", or "/skill:pi-watch".
---

# pi-watch

Watch the working directory for files saved with AI comment triggers, then respond inline — editing code for `AI!` or answering questions for `AI?`.

## Comment Syntax

Works in any file. Supports single-line comment prefixes: `#`  `//`  `--`  `;`

| Comment | What pi does |
|---------|--------------|
| `# AI some context` | Context note — collected but does **not** trigger by itself |
| `# AI? what does this do?` | **Answer** — pi responds in text and removes the comment |
| `# AI! implement this` | **Edit** — pi makes the changes and removes ALL AI comments |

Case-insensitive. The trigger marker can appear at the start **or** end of the comment:

```python
# AI: also update the helper below      ← plain context, gathered alongside AI!

def process(data):
    pass  # clean up error handling AI!  ← this triggers the edit
```

```javascript
// AI! add input validation
function save(user) {
    db.insert(user);  // handle duplicate keys AI
}
```

## The Watch Loop

Run this loop continuously until the user explicitly asks you to stop or presses Ctrl+C.

---

### Step 1 — Start the watcher (blocking)

`watch.py` is located in **the same directory as this SKILL.md**. Resolve its absolute path and pass the user's current working directory as the watch target:

```bash
python3 /abs/path/to/skill/watch.py /path/to/project/root
```

This command **blocks silently** (status goes to stderr) until it detects a saved file with an `AI!` or `AI?` comment. When triggered it prints a single JSON object to stdout and exits. Pi's bash tool will return that output naturally.

If the user hasn't specified a directory, use `$PWD` (the directory pi was launched from).

---

### Step 2 — Parse the event

The JSON output has this shape:

```json
{
  "action": "code" | "ask",
  "trigger_file": "/abs/path/to/file.py",
  "ai_files": {
    "/abs/path/to/file.py": {
      "line_nums": [12, 34],
      "comments":  ["# AI: keep the route signature", "# refactor to helper AI!"]
    },
    "/abs/path/to/other.py": {
      "line_nums": [7],
      "comments":  ["# AI: see this related function too"]
    }
  }
}
```

- `action` — what to do (`"code"` = edit files, `"ask"` = answer a question)
- `trigger_file` — the file that contained the `AI!` or `AI?` that fired
- `ai_files` — **every** file in the project that has any AI comment; use these as your full instruction set and context

---

### Step 3 — Read files for context

Use the `read` tool to read every file listed in `ai_files`. Also read any additional files that appear relevant given the comments (imports, related modules, tests, etc.).

---

### Step 4 — Act

#### `action: "ask"` — Answer a question

1. Identify the `AI?` comment(s) — these are the questions
2. Answer clearly and directly in your **text response**
3. Edit the file to remove the `AI?` comment(s):
   - Whole-line comment → delete the line entirely
   - AI? appended to a code line (e.g. `return x  # AI? why x?`) → strip only the comment portion, preserve the code
4. Do **not** modify any other code

#### `action: "code"` — Make changes

1. Treat **all** AI comments across all files in `ai_files` as your combined instructions. Plain `AI` comments are context/sub-instructions; `AI!` is the primary trigger.
2. Implement the requested changes across all relevant files using the `edit` or `write` tools
3. After all edits are complete, **remove every AI comment** from every file you touched:
   - Whole-line comment → delete the line entirely
   - Inline comment appended to code (e.g. `fn foo() // AI!`) → strip only the comment portion, keep the code
4. Double-check: re-read the affected files to confirm no AI comments remain

---

### Step 5 — Loop

Go back to **Step 1** and run the watcher again. Keep looping — pi is now in watch mode. Acknowledge each completed action briefly (e.g. `"Done — watching for next trigger…"`) then immediately re-run the watcher.

---

## Full Example

User adds this to `routes.py` and saves the file:

```python
@app.route('/factorial/<int:n>')
def factorial(n):
    # AI: keep the existing route signature and return format
    result = 1
    for i in range(1, n + 1):
        result *= i
    # refactor body into a compute_factorial() helper AI!
    return jsonify(result=result)
```

**Pi receives this event:**
```json
{
  "action": "code",
  "trigger_file": "/project/routes.py",
  "ai_files": {
    "/project/routes.py": {
      "line_nums": [3, 8],
      "comments": [
        "# AI: keep the existing route signature and return format",
        "# refactor body into a compute_factorial() helper AI!"
      ]
    }
  }
}
```

**Pi should:**
1. Read `routes.py` for full context
2. Extract a `compute_factorial(n)` function, update the route to call it
3. Remove both AI comment lines from the file
4. Confirm done and loop back to watching

---

## Rules & Edge Cases

- **Plain `AI` comments never trigger alone** — they only contribute context when `AI!` or `AI?` fires in the same save
- **Multi-file coordination**: scatter `# AI` context comments across any files; trigger with a single `AI!` somewhere — all files are collected
- **After `code`**: ALL AI comments are cleaned up, including plain context ones
- **After `ask`**: only the `AI?` comment is removed; plain `AI` context comments can stay
- **Ignored paths**: `.git/`, `node_modules/`, `.venv/`, hidden dirs, binary files, files over 1 MB are never watched
- **Loop until told to stop**: pi stays in watch mode permanently; the user must explicitly say "stop watching" or hit Ctrl+C to exit
