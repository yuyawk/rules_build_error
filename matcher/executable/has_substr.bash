#!/usr/bin/env bash
#
# Matcher executable for `has_substr`.
#
# Args:
#   $1: Pattern string
#   $2: Text file path to investigate

set -euo pipefail
grep -Fq "$1" "$2"
