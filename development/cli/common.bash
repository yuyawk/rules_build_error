#!/usr/bin/env bash
#
# Common prerequisites for manual bash execution

set -euo pipefail

# Absolute path of `development/cli/` directory
SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

# Absolute path of the repository root
REPO_ROOT_DIR=$(realpath "${SCRIPT_DIR}/../..")

# Bazel executable with some arguments
bazel() {
    # Execute bazelisk
    #
    # Args:
    #   $@: Arguments for bazelisk
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

# Default Bazel version
BAZEL_VERSION_DEFAULT="9.x"

for root_dir in "${REPO_ROOT_DIR}" "${REPO_ROOT_DIR}/examples" $(find "${REPO_ROOT_DIR}/tests/integration" -mindepth 1 -maxdepth 1 -type d); do
    if [[ ! -f "${root_dir}/.bazelversion" ]]; then
        if [[ "${CI:-}" == "true" ]]; then
            echo "ERROR: Explicitly specify Bazel version on CI" >&2
            exit 1
        fi

        echo "WARN: ${root_dir}/.bazelversion not found." >&2
        echo "WARN: Creating it with a default version ${BAZEL_VERSION_DEFAULT}." >&2
        echo "${BAZEL_VERSION_DEFAULT}" > "${root_dir}/.bazelversion"
    fi
done
