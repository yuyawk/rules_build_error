#!/usr/bin/env bash
#
# Code style checker (linter and formatter)

set -euo pipefail

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
source "${SCRIPT_DIR}/common.bash"

cd "${REPO_ROOT_DIR}"

buildifier_targets="$(
    git ls-files | \
        grep -E '.bzl$|.bazel$|BUILD$|WORKSPACE$|WORKSPACE.bzlmod$' | \
        xargs -I{} echo "$(pwd)/{}"
)"

# Regarding native-cc:
#   It's not required to load rules_cc at this moment.
#   https://docs.google.com/document/d/1GW7UVo1s9X0cti9OMgT3ga5ozKYUWLPk9k8c4-34rC4/edit?tab=t.0#heading=h.9s188ie4hpe4
"${BAZEL_EXECUTABLE[@]}" run -- \
    @buildifier_prebuilt//:buildifier \
        --lint=fix \
        --warnings=-native-cc \
        ${buildifier_targets}
