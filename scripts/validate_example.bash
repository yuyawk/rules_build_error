#!/usr/bin/env bash
#
# Validate example directory

set -euo pipefail

# Bazel executable with some arguments
BAZEL_EXECUTABLE=(
    "env"
    "-i"
    BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN=1
    BAZELISK_HOME=../.cache/bazelisk
    "HOME=${HOME}"
    "PATH=${PATH}"
    bazelisk
)

cd examples

"${BAZEL_EXECUTABLE[@]}" test //...
