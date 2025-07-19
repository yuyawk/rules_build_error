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

# Download the YAML content, strip comments and formatting using `sed`,
# and normalize it into a flat list alternating between flags and versions.
#
# The meaning of each sed option:
#   (1) Remove comment lines
#   (2) Remove list item markers to extract versions
#   (3) Extract flag names from quoted YAML keys
INCOMPATIBILITY_FLAGS_AND_VERSION=$(curl "${INCOMPATIBILITY_FLAGS_URL}" 2>/dev/null  \
    | sed \
        -e '/^\s*#/d' \
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
done <<< "${INCOMPATIBILITY_FLAGS_AND_VERSION}"

echo "INFO: Incompatibility flags enabled:" "${incompatibility_flags[@]}"

"${BAZEL_EXECUTABLE[@]}" test "${incompatibility_flags[@]}" //...
