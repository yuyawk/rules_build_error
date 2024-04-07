#!/usr/bin/env bash
#
# Matcher executable for `contains_basic_regex`.
#
# Args:
#   $1: Pattern string
#   $2: Text file path to investigate

set -euo pipefail
grep -Gq "$1" "$2"
