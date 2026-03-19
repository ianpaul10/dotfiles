#!/usr/bin/env python3
"""
pi-watch: File watcher that detects AI comment triggers and emits events for pi.

Usage:
    python3 watch.py [directory] [--loop]

    directory   Root directory to watch (default: current working directory)
    --loop      Keep emitting events instead of exiting after the first one
                (default: one-shot — exit after first trigger, for use by pi)

Output:
    A single JSON object to stdout when an AI trigger is detected.
    Progress/status messages go to stderr so they don't pollute pi's JSON parsing.

Event schema:
    {
        "action":       "code" | "ask",
        "trigger_file": "/abs/path/to/file",
        "ai_files": {
            "/abs/path/to/file": {
                "line_nums": [12, 34],
                "comments":  ["# AI: context", "# implement this AI!"]
            }
        }
    }

    action:       "code"  → triggered by AI!  → pi should edit files
                  "ask"   → triggered by AI?   → pi should answer in text
    trigger_file: the file that contained the AI! or AI? that fired
    ai_files:     ALL files in the project that have ANY AI comment (for context)
"""

import json
import re
import sys
import time
from pathlib import Path


# ---------------------------------------------------------------------------
# Comment detection
# ---------------------------------------------------------------------------

# Matches single-line comments in #, //, --, ; styles that contain an AI marker.
# Mirrors Aider's pattern but deduplicates the alternation:
#   - "ai..." at the start of the comment body  (e.g.  # AI do this,  # AI! fix it)
#   - "...ai" / "...ai!" / "...ai?" at the end  (e.g.  # fix this AI!,  // refactor AI?)
AI_COMMENT_RE = re.compile(
    r"(?:#|//|--|;+)\s*(ai\b.*|.*\bai[?!]?)\s*$",
    re.IGNORECASE,
)


def _parse_ai_comments(path: Path):
    """
    Scan a file for AI comments.

    Returns:
        (line_nums, comments, action)
        line_nums : list[int]  — 1-based line numbers of AI comments
        comments  : list[str]  — the matched comment text for each line
        action    : None | '!' | '?'
                    '!' if any comment is an AI! trigger
                    '?' if any comment is an AI? trigger (and no AI! found)
    """
    try:
        content = path.read_text(errors="replace")
    except Exception:
        return [], [], None

    line_nums: list[int] = []
    comments: list[str] = []
    action = None

    for i, line in enumerate(content.splitlines(), 1):
        m = AI_COMMENT_RE.search(line)
        if not m:
            continue
        comment = m.group(0).strip()
        if not comment:
            continue

        line_nums.append(i)
        comments.append(comment)

        # Normalise: strip leading comment chars and spaces to isolate the text
        body = comment.lower().lstrip("#/- ;").strip()

        if body.startswith("ai!") or body.endswith("ai!"):
            action = "!"  # AI! always wins
        elif (body.startswith("ai?") or body.endswith("ai?")) and action != "!":
            action = "?"

    return line_nums, comments, action


# ---------------------------------------------------------------------------
# File system helpers
# ---------------------------------------------------------------------------

# Directories whose contents we never watch
IGNORE_DIRS: set[str] = {
    ".git", ".aider", "__pycache__", "node_modules", ".venv", "venv",
    "vendor", ".cache", ".next", "dist", "build", ".tox", ".eggs",
    ".mypy_cache", ".pytest_cache", "coverage", ".idea", ".vscode",
    ".pi", ".agents",
}

# File extensions we never watch
IGNORE_EXTENSIONS: set[str] = {
    ".pyc", ".pyo", ".swp", ".swo", ".bak", ".tmp", ".temp",
    ".orig", ".log", ".svg", ".pdf", ".png", ".jpg", ".jpeg",
    ".gif", ".webp", ".ico", ".woff", ".woff2", ".ttf", ".eot",
    ".lock", ".db", ".sqlite", ".bin", ".exe", ".dll", ".so",
}

MAX_FILE_SIZE = 1 * 1024 * 1024  # 1 MB


def _should_ignore(path: Path, root: Path) -> bool:
    """Return True if this file should be skipped."""
    try:
        rel = path.relative_to(root)
    except ValueError:
        return True

    # Skip hidden dirs and known noisy dirs at any depth
    for part in rel.parts:
        if part in IGNORE_DIRS:
            return True
        if part.startswith(".") and part not in (".", ".."):
            return True  # hidden files/dirs

    if path.suffix.lower() in IGNORE_EXTENSIONS:
        return True

    try:
        if path.stat().st_size > MAX_FILE_SIZE:
            return True
    except OSError:
        return True

    return False


def _snapshot_mtimes(root: Path) -> dict[str, float]:
    """Return {abs_path_str: mtime} for every watchable file under root."""
    mtimes: dict[str, float] = {}
    try:
        for path in root.rglob("*"):
            if not path.is_file():
                continue
            if _should_ignore(path, root):
                continue
            try:
                mtimes[str(path)] = path.stat().st_mtime
            except OSError:
                pass
    except Exception:
        pass
    return mtimes


def _collect_ai_files(root: Path) -> dict:
    """
    Walk the whole tree and return metadata for every file that has
    at least one AI comment (used to build the event payload).
    """
    result: dict = {}
    try:
        for path in root.rglob("*"):
            if not path.is_file():
                continue
            if _should_ignore(path, root):
                continue
            line_nums, comments, _ = _parse_ai_comments(path)
            if line_nums:
                result[str(path)] = {
                    "line_nums": line_nums,
                    "comments": comments,
                }
    except Exception:
        pass
    return result


# ---------------------------------------------------------------------------
# Main watcher loop
# ---------------------------------------------------------------------------

POLL_INTERVAL = 0.5  # seconds


def watch(root: Path, one_shot: bool = True) -> None:
    """
    Poll `root` for file changes. When a file is saved with an AI! or AI?
    comment, emit a JSON event to stdout and (if one_shot) exit.
    """
    print(f"[pi-watch] Watching: {root}", file=sys.stderr, flush=True)
    print(
        "[pi-watch] Save a file with AI! to trigger edits, AI? to ask a question.",
        file=sys.stderr,
        flush=True,
    )
    if one_shot:
        print(
            "[pi-watch] One-shot mode: will exit after the first trigger.",
            file=sys.stderr,
            flush=True,
        )

    prev_mtimes = _snapshot_mtimes(root)

    while True:
        time.sleep(POLL_INTERVAL)

        try:
            curr_mtimes = _snapshot_mtimes(root)
        except Exception:
            continue

        # Files that are new or have a changed mtime
        changed: set[str] = {
            p for p, mt in curr_mtimes.items()
            if prev_mtimes.get(p) != mt
        }
        prev_mtimes = curr_mtimes

        if not changed:
            continue

        # Check each changed file for a trigger comment (AI! or AI?)
        trigger_action: str | None = None
        trigger_file: str | None = None

        for path_str in sorted(changed):  # sorted for determinism
            _, _, action = _parse_ai_comments(Path(path_str))
            if action in ("!", "?"):
                trigger_action = action
                trigger_file = path_str
                break  # first trigger wins; pi will loop back for more

        if not trigger_action:
            # Changed files had plain AI comments only — no trigger yet
            continue

        # Collect ALL files in the project that have any AI comment for context
        ai_files = _collect_ai_files(root)

        event = {
            "action": "code" if trigger_action == "!" else "ask",
            "trigger_file": trigger_file,
            "ai_files": ai_files,
        }

        print(json.dumps(event), flush=True)

        if one_shot:
            break
        # In --loop mode: keep going after emitting the event


def main() -> None:
    args = [a for a in sys.argv[1:] if a != "watch.py"]
    loop_mode = "--loop" in args
    args = [a for a in args if not a.startswith("--")]

    root = Path(args[0]).resolve() if args else Path.cwd().resolve()

    if not root.exists():
        print(f"[pi-watch] Error: directory does not exist: {root}", file=sys.stderr)
        sys.exit(1)

    try:
        watch(root, one_shot=not loop_mode)
    except KeyboardInterrupt:
        print("\n[pi-watch] Stopped.", file=sys.stderr)


if __name__ == "__main__":
    main()
