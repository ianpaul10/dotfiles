#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$SCRIPT_DIR/gh-pr-at"
TEST_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TEST_TMPDIR"' EXIT

mkdir -p "$TEST_TMPDIR/bin"

cat > "$TEST_TMPDIR/bin/git" <<'EOF'
#!/bin/bash
case "$*" in
  "rev-parse --show-toplevel")
    printf '/repo\n'
    ;;
  "-C /repo blame "*)
    printf '%s 1 1 1\n' "${BLAME_SHA:?}"
    ;;
  *)
    echo "unexpected git arguments: $*" >&2
    exit 1
    ;;
esac
EOF

cat > "$TEST_TMPDIR/bin/gh" <<'EOF'
#!/bin/bash
if [[ -n "${GH_PR_NUMBER:-}" ]]; then
  printf '%s\n' "$GH_PR_NUMBER"
fi
EOF

cat > "$TEST_TMPDIR/bin/gs" <<'EOF'
#!/bin/bash
: > "${GS_CALLED:?}"
if [[ -n "${GS_PR_NUMBER:-}" ]]; then
  printf '[{"number":%s}]\n' "$GS_PR_NUMBER"
else
  printf '[]\n'
fi
EOF

chmod +x "$TEST_TMPDIR/bin/git" "$TEST_TMPDIR/bin/gh" "$TEST_TMPDIR/bin/gs"

export PATH="$TEST_TMPDIR/bin:/usr/bin:/bin"
export BLAME_SHA="97db9d6053ab39f7483c2447d1b6375c5306912e"
export GS_CALLED="$TEST_TMPDIR/gs-called"

export GH_PR_NUMBER=891331
export GS_PR_NUMBER=2076943
output="$($SCRIPT areas/example.rb:10)"
[[ "$output" == "https://github.com/shop/world/pull/891331" ]] || {
  echo "expected GitHub URL, got: $output" >&2
  exit 1
}
[[ ! -e "$GS_CALLED" ]] || {
  echo "expected GitHub result to skip gs fallback" >&2
  exit 1
}

export GH_PR_NUMBER=""
rm -f "$GS_CALLED"
output="$($SCRIPT /repo/areas/example.rb:10)"
[[ "$output" == "https://meteorite.shopify.io/repos/shop/world/pulls/2076943" ]] || {
  echo "expected Meteorite URL, got: $output" >&2
  exit 1
}
[[ -e "$GS_CALLED" ]] || {
  echo "expected gs fallback to be queried" >&2
  exit 1
}

printf 'gh-pr-at tests passed\n'
