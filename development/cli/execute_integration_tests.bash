#!/usr/bin/env bash
#
# Execute all integration tests.
#
# Args:
#   $@: Integration test directory where `bazel test` is executed. If not provided, all directories under `tests/integration` are used.

set -euo pipefail

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
source "${SCRIPT_DIR}/common.bash"

test_dirs=("${@}")
if [ ${#test_dirs[@]} -eq 0 ]; then
    mapfile -t test_dirs < <(find "${REPO_ROOT_DIR}/tests/integration" -mindepth 1 -maxdepth 1 -type d)
fi

for test_dir in "${test_dirs[@]}"; do
    echo "Executing integration tests in directory: ${test_dir}"
    pushd "${test_dir}" > /dev/null
    bazel test //...
    popd > /dev/null
done
