#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

TAG="${GITHUB_REF_NAME}"
PREFIX="rules_build_error-${TAG}"
ARCHIVE="rules_build_error-${TAG}.tar.gz"

git ls-files -z | \
    tar --transform "s|^|${PREFIX}/|" --null -czhf "${ARCHIVE}" --files-from=-

# StdOut of this script is used for release description
cat << EOF
Add to your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "rules_build_error", version = "${TAG}")
\`\`\`
EOF
