#!/usr/bin/env bash
#
# Validate example directory

set -euo pipefail

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
source "${SCRIPT_DIR}/common.bash"

cd "${REPO_ROOT_DIR}/examples"

bazel_version="$(grep -E '^USE_BAZEL_VERSION=' .bazeliskrc | cut -d= -f2)"
bazel_major_version="$(echo "${bazel_version}" | cut -d. -f1)"

# Incompatible flags to raise early warnings for potential migration blockers.
# https://github.com/bazelbuild/bazel-central-registry/blob/main/incompatible_flags.yml
incompatible_flags=(
    "--incompatible_config_setting_private_default_visibility"
    "--incompatible_disable_starlark_host_transitions"
    "--incompatible_disable_native_repo_rules"
    "--incompatible_autoload_externally="
)

if [[ "${bazel_major_version}" =~ ^[0-9]+$ ]]; then
    if [[ "${bazel_major_version}" -ge 8 ]]; then
        incompatible_flags+=(
            "--incompatible_disable_autoloads_in_main_repo"
        )
    fi
fi

"${BAZEL_EXECUTABLE[@]}" test "${incompatible_flags[@]}" //...
