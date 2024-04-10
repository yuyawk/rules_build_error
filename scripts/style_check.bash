#!/usr/bin/env bash
#
# Code style checker (linter and formatter)

set -euo pipefail

# Bazel executable with some arguments
BAZEL_EXECUTABLE=(
    "env"
    "-i"
    BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN=1
    BAZELISK_HOME=.cache/bazelisk
    "HOME=${HOME}"
    "PATH=${PATH}"
    bazelisk
)

buildifier_targets="$(
    git ls-files | \
        grep -E '.bzl$|.bazel$|BUILD$|WORKSPACE$|WORKSPACE.bzlmod$' | \
        xargs -I{} echo "$(pwd)/{}"
)"

"${BAZEL_EXECUTABLE[@]}" run -- @buildifier_prebuilt//:buildifier -lint=fix ${buildifier_targets}
