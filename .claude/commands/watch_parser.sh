git diff --unified=0 | \
  awk '
    /^--- a\// { file = substr($2, 3); next }
    /^+++ b\// { next }
    /^[+-]/ {
      line_number++;
      if ($0 ~ /AI[!?]/) {
        print file ":" line_number ":" $0;
      }
      next;
    }
    /^ / { line_number++ }
  '
