#!/usr/bin/env bash
#
# Execute all tests

set -euo pipefail
bazelisk test //...
