#
# Matcher executable for `has_substr`.
#
# Args:
#   $1: Text file containing a pattern string
#   $2: Text file where the matcher searches for a pattern string

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "ERROR: Incorrect number of arguments" >&2
  exit 1
fi

grep -Fq "$(cat "$1")" "$2"
