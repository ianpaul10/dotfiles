#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$SCRIPT_DIR/gsget"
TEST_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TEST_TMPDIR"' EXIT

mkdir -p "$TEST_TMPDIR/bin"

cat > "$TEST_TMPDIR/bin/git" <<'EOF'
#!/bin/bash
[[ -n "${GIT_LOG:-}" ]] && echo "$*" >> "$GIT_LOG"
case "$*" in
  "rev-parse --is-inside-work-tree")
    [[ "${IN_REPO:-1}" == "1" ]] || exit 1
    ;;
  "fetch origin")
    if [[ "${FETCH_FAILS:-}" == "1" ]]; then exit 1; fi
    ;;
  "switch feature/x")
    if [[ -n "${SWITCH_ERR:-}" ]]; then
      printf '%s\n' "$SWITCH_ERR" >&2
      exit 1
    fi
    printf "switched to a new branch 'feature/x'\n"
    ;;
  "show-ref --verify --quiet refs/remotes/origin/feature/x")
    [[ "${HAS_ORIGIN_BRANCH:-1}" == "1" ]] || exit 1
    ;;
  "merge --ff-only origin/feature/x")
    if [[ "${FF_FAILS:-}" == "1" ]]; then exit 1; fi
    ;;
  "config --get branch.feature/x.wgh-parent")
    [[ -n "${WGH_PARENT:-}" ]] || exit 1
    printf '%s\n' "$WGH_PARENT"
    ;;
  "worktree list")
    printf '%s\n' "/other/tree  abc1234 [feature/x]"
    ;;
esac
EOF

cat > "$TEST_TMPDIR/bin/gs" <<'EOF'
#!/bin/bash
printf 'GS_SUMMARY\n'
EOF

chmod +x "$TEST_TMPDIR/bin/git" "$TEST_TMPDIR/bin/gs"

run_gsget() {
  (cd "$TEST_TMPDIR" && PATH="$TEST_TMPDIR/bin:$PATH" "$SCRIPT" "$@")
}

expect() {
  local expected=$1 out
  shift
  out=$(run_gsget "$@" 2>&1 || true)
  if ! printf '%s\n' "$out" | grep -q "$expected"; then
    echo "FAIL: expected output to contain: $expected" >&2
    echo "--- actual output ---" >&2
    printf '%s\n' "$out" >&2
    exit 1
  fi
}

# 1. no args → usage, non-zero
if run_gsget >/dev/null 2>&1; then
  echo "FAIL: should exit non-zero without args" >&2
  exit 1
fi
if ! (run_gsget 2>&1 || true) | grep -q "usage: gsget <branch>"; then
  echo "FAIL: should print usage" >&2
  exit 1
fi

# 2. happy path: fetch, switch, ff-merge, then gs summary
GIT_LOG="$TEST_TMPDIR/calls.log"
export GIT_LOG
: > "$GIT_LOG"
GS="$TEST_TMPDIR/bin/gs" run_gsget feature/x | grep -q "GS_SUMMARY"
for cmd in "fetch origin" "switch feature/x" "merge --ff-only origin/feature/x"; do
  if ! grep -qx "$cmd" "$GIT_LOG"; then
    echo "FAIL: expected git call: $cmd" >&2
    exit 1
  fi
done

# 3. untracked by dt → hint
WGH_PARENT= expect "dt track" feature/x

# 4. branch checked out in another worktree → point at it, non-zero
export SWITCH_ERR="fatal: 'feature/x' is already used by worktree at '/other/tree'"
if run_gsget feature/x >/dev/null 2>&1; then
  echo "FAIL: should exit non-zero when branch is checked out elsewhere" >&2
  exit 1
fi
out=$(run_gsget feature/x 2>&1 || true)
if ! printf '%s\n' "$out" | grep -q "/other/tree"; then
  echo "FAIL: should mention the worktree holding the branch" >&2
  exit 1
fi
unset SWITCH_ERR

# 5. diverged from origin → warns, does not rewrite
FF_FAILS=1 expect "diverged" feature/x

# 6. not a repo → non-zero
export IN_REPO=0
if run_gsget feature/x >/dev/null 2>&1; then
  echo "FAIL: should exit non-zero outside a repo" >&2
  exit 1
fi
unset IN_REPO

echo "gsget: all tests passed"
