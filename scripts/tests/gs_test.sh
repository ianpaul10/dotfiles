#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$SCRIPT_DIR/gs"
TEST_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TEST_TMPDIR"' EXIT

mkdir -p "$TEST_TMPDIR/bin"

cat > "$TEST_TMPDIR/bin/git" <<'EOF'
#!/bin/bash
case "$*" in
  "rev-parse --is-inside-work-tree")
    [[ "${IN_REPO:-1}" == "1" ]] || exit 1
    ;;
  "symbolic-ref --quiet --short HEAD")
    if [[ -n "${DETACHED:-}" ]]; then exit 1; fi
    printf '%s\n' "${BRANCH:-feature/x}"
    ;;
  "rev-parse --short HEAD")
    printf 'abc1234\n'
    ;;
  "for-each-ref"*)
    printf '%s\t%s\n' "${UPSTREAM-origin/feature/x}" "${UPSTREAM_TRACK:-}"
    ;;
  "fetch origin")
    if [[ "${FETCH_FAILS:-}" == "1" ]]; then exit 1; fi
    ;;
  "status --porcelain")
    cat "${STATUS_FILE:-/dev/null}"
    ;;
  "rev-list --left-right --count HEAD...origin/main")
    printf '%s\n' "${VS_ORIGIN_MAIN:-0$(printf '\t')0}"
    ;;
  "merge-base HEAD origin/main")
    printf '3d41c98abc\n'
    ;;
  "rev-parse --short 3d41c98abc")
    printf '3d41c98\n'
    ;;
  "show-ref --verify --quiet refs/heads/main")
    [[ "${HAS_LOCAL_MAIN:-1}" == "1" ]] || exit 1
    ;;
  "rev-list --left-right --count HEAD...main")
    printf '%s\n' "${VS_MAIN:-0$(printf '\t')0}"
    ;;
  "config --get branch.feature/x.wgh-parent")
    [[ -n "${WGH_PARENT:-}" ]] || exit 1
    printf '%s\n' "$WGH_PARENT"
    ;;
  "config --get branch.feature/x.iprBase")
    [[ -n "${IPR_BASE:-}" ]] || exit 1
    printf '%s\n' "$IPR_BASE"
    ;;
  "rev-parse --git-dir")
    printf '%s\n' "${GIT_DIR_PATH:-/repo/.git}"
    ;;
  "status")
    printf 'FALLBACK_STATUS\n'
    ;;
  *)
    echo "unexpected git arguments: $*" >&2
    exit 1
    ;;
esac
EOF

chmod +x "$TEST_TMPDIR/bin/git"

# simulate the GNU-stat dev-shell environment that broke gs: -f %m prints
# filesystem garbage (including the literal text "File:") and exits 1
mkdir -p "$TEST_TMPDIR/repo/.git"
touch "$TEST_TMPDIR/repo/.git/FETCH_HEAD"
cat > "$TEST_TMPDIR/bin/stat" <<'EOF'
#!/bin/bash
case "$1" in
  -c) printf '1000000000\n' ;;          # GNU form: clean epoch
  -f) printf '  File: "/repo/.git/FETCH_HEAD"\nFS junk...\n1000000000\n' ;; # BSD form: garbage
esac
EOF
chmod +x "$TEST_TMPDIR/bin/stat"

run_gs() {
  (cd "$TEST_TMPDIR" && PATH="$TEST_TMPDIR/bin:$PATH" "$SCRIPT" "$@")
}

expect() {
  local expected=$1 out
  out=$(run_gs 2>/dev/null || true)
  if ! printf '%s\n' "$out" | grep -qF "$expected"; then
    echo "FAIL: expected output to contain: $expected" >&2
    echo "--- actual output ---" >&2
    printf '%s\n' "$out" >&2
    exit 1
  fi
}

expect_not() {
  local expected=$1 out
  out=$(run_gs 2>/dev/null || true)
  if printf '%s\n' "$out" | grep -qF "$expected"; then
    echo "FAIL: expected output NOT to contain: $expected" >&2
    exit 1
  fi
}

expect_fresh() {
  local expected=$1 out
  out=$(run_gs --fresh 2>/dev/null || true)
  if ! printf '%s\n' "$out" | grep -qF "$expected"; then
    echo "FAIL: expected --fresh output to contain: $expected" >&2
    echo "--- actual output ---" >&2
    printf '%s\n' "$out" >&2
    exit 1
  fi
}

# 1. in-sync branch, clean worktree, dt-tracked
WGH_PARENT=main expect "branch    feature/x → origin/feature/x [synced]"
WGH_PARENT=main expect "worktree  clean"
WGH_PARENT=main expect "dt        in a dt stack (parent: main)"
WGH_PARENT=main expect "suggest   all good"

# 2. behind origin/main, clean → suggest rebase
VS_ORIGIN_MAIN=$'2\t5709' expect "vs origin/main   ↑2 ↓5709 · base 3d41c98"
VS_ORIGIN_MAIN=$'2\t5709' expect "suggest   git rebase origin/main (2 local commits)"

# 3. dirty worktree
printf ' M a.txt\nM  b.txt\n?? c.txt\n' > "$TEST_TMPDIR/dirty"
STATUS_FILE="$TEST_TMPDIR/dirty" expect "worktree  1 staged · 1 modified · 1 untracked"
STATUS_FILE="$TEST_TMPDIR/dirty" VS_ORIGIN_MAIN=$'2\t5709' expect "commit or stash, then git rebase origin/main"

# 4. ahead only → suggest push
VS_ORIGIN_MAIN=$'3\t0' expect "suggest   git push"

# 5. untracked by dt → hint
VS_ORIGIN_MAIN=$'0\t0' expect "dt        not in a dt stack"
VS_ORIGIN_MAIN=$'0\t0' expect "consider 'dt track' so dt sync maintains this branch"

# 6. iPR base override shown
IPR_BASE=origin/river/proto/wren/main expect "iPR base override: origin/river/proto/wren/main"

# 6b. upstream ahead token passes through
UPSTREAM_TRACK='[ahead 1]' expect "[ahead 1]"

# 6c. no upstream
UPSTREAM= expect "[no upstream]"

# 6d. --fresh fetches origin first, then shows the normal output
expect_fresh "fetching origin"
expect_fresh "branch    feature/x → origin/feature/x [synced]"

# 6e. GNU stat present in PATH → fetch line renders instead of crashing on
# the "File:" garbage (regression for the birch unbound-variable crash)
GIT_DIR_PATH="$TEST_TMPDIR/repo/.git" expect "d ago — run 'git fetch origin'"

# 7. no local main → section skipped
HAS_LOCAL_MAIN=0 expect_not "vs main          in sync"

# 8. detached HEAD → note, then plain git status
DETACHED=1 expect "detached HEAD"
DETACHED=1 expect "FALLBACK_STATUS"

# 9. not a repo → delegates to git status
IN_REPO=0 expect "FALLBACK_STATUS"

echo "gs: all tests passed"
