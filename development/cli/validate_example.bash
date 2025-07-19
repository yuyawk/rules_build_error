#!/usr/bin/env bash
#
# Validate example directory

set -euo pipefail

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
source "${SCRIPT_DIR}/common.bash"

cd "${REPO_ROOT_DIR}/examples"


# Collect incompatibility flags to raise early warnings for potential migration blockers.
INCOMPATIBILITY_FLAGS_URL="https://raw.githubusercontent.com/bazelbuild/bazel-central-registry/main/incompatible_flags.yml"
BAZEL_VERSION="$(grep -E '^USE_BAZEL_VERSION=' .bazeliskrc | cut -d= -f2)"
INCOMPATIBILITY_FLAGS_AND_VERSION=$(curl "${INCOMPATIBILITY_FLAGS_URL}" 2>/dev/null  \
    | sed \
        -e '/^\s*#/d' \
        -e 's/^\s*- //' \
        -e 's/^\s*"\([^"]*\)":/\1/'
)
incompatibility_flags=()
current_flag=""
while IFS= read -r line; do
    if [[ "${line}" == --* ]]; then
        current_flag="${line}"
    elif [[ "${line}" == "${BAZEL_VERSION}" ]]; then
        incompatibility_flags+=("${current_flag}")
    fi
done <<< "${INCOMPATIBILITY_FLAGS_AND_VERSION}"

echo "INFO: Incompatibility flags enabled: ${incompatibility_flags[@]}"

"${BAZEL_EXECUTABLE[@]}" test "${incompatibility_flags[@]}" //...
