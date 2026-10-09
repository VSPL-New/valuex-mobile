#!/usr/bin/env bash
# Usage: tool/check_coverage.sh <lcov.info> <min-percent>
# Line coverage over hand-written code (generated and l10n files excluded).
set -euo pipefail

file="${1:?lcov file}"
min="${2:?minimum percent}"

awk -v min="$min" '
  /^SF:/ { skip = ($0 ~ /\.g\.dart|\.freezed\.dart|\/l10n\//) }
  !skip && /^LF:/ { split($0, a, ":"); lf += a[2] }
  !skip && /^LH:/ { split($0, a, ":"); lh += a[2] }
  END {
    pct = lf ? 100 * lh / lf : 0
    printf "Line coverage: %.1f%% (%d/%d), minimum %s%%\n", pct, lh, lf, min
    exit (pct + 0 < min + 0)
  }
' "$file"
