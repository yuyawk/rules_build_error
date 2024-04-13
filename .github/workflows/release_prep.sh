#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

TAG="${GITHUB_REF_NAME}"
REPO_NAME="${GITHUB_REPOSITORY#*/}"
PREFIX="${REPO_NAME}-${TAG}"
ARCHIVE="${REPO_NAME}-${TAG}.tar.gz"

git archive --format=tar "--prefix=${PREFIX}/" "${TAG}" | \
    gzip \
    > "${ARCHIVE}"

if ! SHA=$(shasum -a 256 "${ARCHIVE}" | awk '{print $1}'); then
    echo "ERROR: Could not determine hash for ${ARCHIVE}" >&2
    exit 1
fi

URL="https://github.com/${GITHUB_REPOSITORY}/releases/download/${TAG}/${ARCHIVE}"

# StdOut of this script is used for release description
cat << EOF
## Using Bzlmod with Bazel 6 or greater

1. Enable Bzlmod with \`common --enable_bzlmod\` in \`.bazelrc\`.
2. Add to your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "${REPO_NAME}", version = "${TAG}")
\`\`\`

## Using WORKSPACE

\`\`\`starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "${REPO_NAME}",
    sha256 = "${SHA}",
    strip_prefix = "${PREFIX}",
    url = "${URL}",
)
\`\`\`
EOF
