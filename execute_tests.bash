#!/usr/bin/env bash
#
# Execute all tests

set -euo pipefail

# Bazel executable with some arguments
BAZEL_EXECUTABLE=(
    "env"
    "-i"
    BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN=1
    "HOME=${HOME}"
    "PATH=${PATH}"
    bazelisk
)

check_bazel_build_error() {
    # Check bazel build error for a particular target
    #
    # Args:
    #   $1: label to check
    local label
    label=$1

    # Before executing `bazel build`, check if the target exists with `bazel query`
    "${BAZEL_EXECUTABLE[@]}" query "${label}"

    # Check build error
    if "${BAZEL_EXECUTABLE[@]}" build "${label}"; then
        echo "Target '${label}' must fail to build, but succeeded" >&2
        exit 1
    else
        echo "OK! It has failed as intended."
    fi
}

echo "Executing the test cases which should succeed in straightforward 'bazel test'"
"${BAZEL_EXECUTABLE[@]}" test //...

echo "Executing the test cases which should fail at 'bazel build'"
check_bazel_build_error //tests/cc/cpp_successful_build:plain
check_bazel_build_error //tests/cc/cpp_successful_build:with_basic_regex_matcher
check_bazel_build_error //tests/cc/cpp_successful_build:with_extended_regex_matcher
check_bazel_build_error //tests/cc/cpp_successful_build:with_substr_matcher
check_bazel_build_error //tests/cc/cpp_successful_build_with_deps:plain
check_bazel_build_error //tests/cc/cpp_successful_build_with_deps:with_basic_regex_matcher
check_bazel_build_error //tests/cc/cpp_successful_build_with_deps:with_extended_regex_matcher
check_bazel_build_error //tests/cc/cpp_successful_build_with_deps:with_substr_matcher
