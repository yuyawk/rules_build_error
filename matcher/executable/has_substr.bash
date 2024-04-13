#!/usr/bin/env bash
#
# Matcher executable for `has_substr`.
#
# Args:
#   $1: Pattern string
#   $2: Text file path to investigate

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "ERROR: Incorrect number of arguments" >&2
  exit 1
fi

grep -Fq "$1" "$2"
