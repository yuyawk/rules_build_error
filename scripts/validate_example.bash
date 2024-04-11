#!/usr/bin/env bash
#
# Validate example directory

set -euo pipefail

BAZEL_VERSION_DEFAULT="7.1.1"

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

if [[ ! -f .bazeliskrc ]]; then
    echo "WARN: .bazeliskrc not found." >&2
    echo "WARN: Creating it with a default version ${BAZEL_VERSION_DEFAULT}." >&2
    echo "USE_BAZEL_VERSION=7.1.1" > .bazeliskrc
fi

"${BAZEL_EXECUTABLE[@]}" test //...
