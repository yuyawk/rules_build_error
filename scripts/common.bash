#!/usr/bin/env bash
#
# Common prerequisites for manual bash execution

set -euo pipefail

# Absolute path of `scripts/` directory
SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

# Absolute path of the repository root
REPO_ROOT_DIR=$(realpath "${SCRIPT_DIR}/..")

# Bazel executable with some arguments
BAZEL_EXECUTABLE=(
    "env"
    "-i"
    BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN=1
    "BAZELISK_HOME=${REPO_ROOT_DIR}/.cache/bazelisk"
    "HOME=${HOME}"
    "PATH=${PATH}"
    bazelisk
)

# Default Bazel version
BAZEL_VERSION_DEFAULT="7.1.1"

if [[ ! -f "${REPO_ROOT_DIR}/.bazeliskrc" ]]; then
    if [[ "${CI:-}" == "true" ]]; then
        echo "ERROR: Explicitly specify Bazel version on CI" >&2
        exit 1
    fi

    echo "WARN: .bazeliskrc not found." >&2
    echo "WARN: Creating it with a default version ${BAZEL_VERSION_DEFAULT}." >&2
    echo "USE_BAZEL_VERSION=${BAZEL_VERSION_DEFAULT}" > "${REPO_ROOT_DIR}/.bazeliskrc"
fi
