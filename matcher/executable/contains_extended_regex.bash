#!/usr/bin/env bash
#
# Matcher executable for `contains_extended_regex`.
#
# Args:
#   $1: Pattern string
#   $2: Text file path to investigate

set -euo pipefail
grep -Eq "$1" "$2"
