#!/usr/bin/env bash
#
# Validate example directory

set -euo pipefail

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
source "${SCRIPT_DIR}/common.bash"

cd "${REPO_ROOT_DIR}/examples"


# Collect incompatibility flags to raise early warnings for potential migration blockers.

# URL of the YAML file containing a mapping of Bazel incompatibility flags to affected Bazel versions.
INCOMPATIBILITY_FLAGS_URL="https://raw.githubusercontent.com/bazelbuild/bazel-central-registry/main/incompatible_flags.yml"

# Extract the Bazel version in use from the `.bazeliskrc` file.
# It assumes a line in the format: USE_BAZEL_VERSION=8.x
BAZEL_VERSION="$(grep -E '^USE_BAZEL_VERSION=' .bazeliskrc | cut -d= -f2)"

# Download the YAML content
INCOMPATIBILITY_FLAGS_YAML=$(curl "${INCOMPATIBILITY_FLAGS_URL}" 2>/dev/null)

# Normalize it into a flat list alternating between flags and versions.
#
# The meaning of each sed option:
#   (1, 2) Remove comments
#   (3) Remove list item markers to extract versions
#   (4) Extract flag names from quoted YAML keys
INCOMPATIBILITY_FLAGS_FLATTENED=$(echo "${INCOMPATIBILITY_FLAGS_YAML}"
    | sed \
        -e '/^\s*#/d' \
        -e 's/#.*$//' \
        -e 's/^\s*- //' \
        -e 's/^\s*"\([^"]*\)":/\1/'
)

# Initialize array to collect incompatibility flags supported for the current Bazel version.
incompatibility_flags=()

# Track the current flag while iterating over the flattened lines.
current_flag=""

# Read the lines one by one.
# If the line is a flag (starts with "--"), update `current_flag`.
# If the line matches the Bazel version, add the current_flag to the results.
while IFS= read -r line; do
    if [[ "${line}" == --* ]]; then
        current_flag="${line}"
    elif [[ "${line}" == "${BAZEL_VERSION}" ]]; then
        incompatibility_flags+=("${current_flag}")
    fi
done <<< "${INCOMPATIBILITY_FLAGS_FLATTENED}"

if [[ "${#incompatibility_flags[@]}" -eq 0 ]]; then
    echo "ERROR: Failed to obtain the incompatibility flags." >&2
    echo "The content of the YAML file:"  >&2
    echo "${INCOMPATIBILITY_FLAGS_YAML}"  >&2
    echo "The content of the flattened list:"  >&2
    echo "${INCOMPATIBILITY_FLAGS_FLATTENED}"  >&2
    exit 1
fi

echo "INFO: Incompatibility flags enabled:" "${incompatibility_flags[@]}"
"${BAZEL_EXECUTABLE[@]}" test "${incompatibility_flags[@]}" //...
