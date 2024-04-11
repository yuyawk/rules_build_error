#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

TAG="${GITHUB_REF_NAME}"

# StdOut of this script is used for release description
cat << EOF
## Using Bzlmod with Bazel 6 or greater

1. Enable Bzlmod with \`common --enable_bzlmod\`.
2. Add to your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "rules_build_error", version = "${TAG}")
\`\`\`
EOF
