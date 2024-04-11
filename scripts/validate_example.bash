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

copied_files=(
    ".bazelignore"
    ".bazelrc"
)

for copied_file in "${copied_files[@]}"; do
    cp "${copied_file}" examples
done

cd examples

"${BAZEL_EXECUTABLE[@]}" test //...
