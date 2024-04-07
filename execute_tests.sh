#!/usr/bin/env bash
#
# Execute all tests

set -euo pipefail

check_bazel_build_error() {
    # Check bazel build error for a particular target
    #
    # Args:
    #   $1: label to check
    local label
    label=$1

    # Before executing `bazelisk build`, check if the target exists with `bazelisk query`
    bazelisk query "${label}"

    # Check build error
    if bazelisk build "${label}"; then
        echo "Target '${label}' must fail to build, but succeeded" >&2
        exit 1
    else
        echo "OK! It has failed as intended."
    fi
}

echo "Executing the test cases which should pass straightforward 'bazelisk test'"
bazelisk test //...

echo "Executing the test cases which should fail at 'bazelisk build'"
check_bazel_build_error //tests/cc/cpp_successful_build:plain
check_bazel_build_error //tests/cc/cpp_successful_build:with_basic_regex_matcher
check_bazel_build_error //tests/cc/cpp_successful_build:with_extended_regex_matcher
check_bazel_build_error //tests/cc/cpp_successful_build:with_substr_matcher
check_bazel_build_error //tests/cc/cpp_successful_build_with_deps:plain
check_bazel_build_error //tests/cc/cpp_successful_build_with_deps:with_basic_regex_matcher
check_bazel_build_error //tests/cc/cpp_successful_build_with_deps:with_extended_regex_matcher
check_bazel_build_error //tests/cc/cpp_successful_build_with_deps:with_substr_matcher
