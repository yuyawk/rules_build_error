#!/usr/bin/env bash
#
# Execute all tests

set -euo pipefail

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
source "${SCRIPT_DIR}/common.bash"

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

cd "${REPO_ROOT_DIR}"

echo "Executing the test cases which should succeed in straightforward 'bazel test'"
"${BAZEL_EXECUTABLE[@]}" test //...

echo "Executing the test cases which should fail at 'bazel build'"
check_bazel_build_error //tests/cc/cpp_successful_build:plain
check_bazel_build_error //tests/cc/cpp_successful_build:plain.test
check_bazel_build_error //tests/cc/cpp_successful_build:with_basic_regex_matcher
check_bazel_build_error //tests/cc/cpp_successful_build:with_basic_regex_matcher.test
check_bazel_build_error //tests/cc/cpp_successful_build:with_extended_regex_matcher
check_bazel_build_error //tests/cc/cpp_successful_build:with_extended_regex_matcher.test
check_bazel_build_error //tests/cc/cpp_successful_build:with_substr_matcher
check_bazel_build_error //tests/cc/cpp_successful_build:with_substr_matcher.test
check_bazel_build_error //tests/cc/cpp_successful_build_with_deps:plain
check_bazel_build_error //tests/cc/cpp_successful_build_with_deps:plain.test
check_bazel_build_error //tests/cc/cpp_successful_build_with_deps:with_basic_regex_matcher
check_bazel_build_error //tests/cc/cpp_successful_build_with_deps:with_basic_regex_matcher.test
check_bazel_build_error //tests/cc/cpp_successful_build_with_deps:with_extended_regex_matcher
check_bazel_build_error //tests/cc/cpp_successful_build_with_deps:with_extended_regex_matcher.test
check_bazel_build_error //tests/cc/cpp_successful_build_with_deps:with_substr_matcher
check_bazel_build_error //tests/cc/cpp_successful_build_with_deps:with_substr_matcher.test
check_bazel_build_error //tests/cc/cpp_compile_error:incorrect_matcher
check_bazel_build_error //tests/cc/cpp_compile_error:incorrect_matcher.test
check_bazel_build_error //tests/cc/cpp_inline_src:incorrect_matcher
check_bazel_build_error //tests/cc/cpp_inline_src:incorrect_matcher.test
check_bazel_build_error //tests/cc/cpp_inline_src:incorrect_extension
check_bazel_build_error //tests/cc/cpp_inline_src:incorrect_extension.test
check_bazel_build_error //tests/cc/c_inline_src:incorrect_extension
check_bazel_build_error //tests/cc/c_inline_src:incorrect_extension.test
