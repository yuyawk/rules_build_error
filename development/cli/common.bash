#!/usr/bin/env bash
#
# Common prerequisites for manual bash execution

set -euo pipefail

# Absolute path of `development/cli/` directory
SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

# Absolute path of the repository root
REPO_ROOT_DIR=$(realpath "${SCRIPT_DIR}/../..")

# Default Bazel version
BAZEL_VERSION_DEFAULT="9.x"

# Bazel executable with some arguments
bazel() {
    # Execute bazelisk
    #
    # Args:
    #   $@: Arguments for bazelisk

    if [[ -n "${DEVELOPMENT_BAZEL_VERSION:-}" ]]; then
        echo "Using Bazel version from DEVELOPMENT_BAZEL_VERSION: ${DEVELOPMENT_BAZEL_VERSION}" >&2
        echo "${DEVELOPMENT_BAZEL_VERSION}" > .bazelversion
    elif [[ ! -f .bazelversion ]]; then
        if [[ "${CI:-}" == "true" ]]; then
            echo "ERROR: Explicitly specify Bazel version on CI" >&2
            exit 1
        fi

        echo "WARN: .bazelversion not found." >&2
        echo "WARN: Creating it with a default version ${BAZEL_VERSION_DEFAULT}." >&2
        echo "${BAZEL_VERSION_DEFAULT}" > .bazelversion
    fi

    local environment_variables_to_set
    environment_variables_to_set=(
        BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN=1
        "BAZELISK_HOME=${REPO_ROOT_DIR}/.cache/bazelisk"
        "PATH=${PATH}"
    )
    # Also set BAZEL_VC if defined in the environment
    # https://bazel.build/configure/windows#build_cpp
    if [[ -n "${BAZEL_VC:-}" ]]; then
        environment_variables_to_set+=("BAZEL_VC=${BAZEL_VC}")
    fi

    env \
        -i \
        "${environment_variables_to_set[@]}" \
        bazelisk "${@}"
}
