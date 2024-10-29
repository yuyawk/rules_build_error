# Development guide

## Prerequisites

Ensure [`bazelisk`](https://github.com/bazelbuild/bazelisk) is installed before running any tests or development scripts.

## Testing

### Unit tests

To run unit tests, execute [`development/cli/execute_tests.bash`](development/cli/execute_tests.bash). This script runs `bazelisk test` and `bazelisk build` commands.

Note that some test targets are marked with `tags = ["manual"]` and are intended to individually verify that bazel build fails as expected.

### Example validation

To validate examples, run [`development/cli/validate_example.bash`](development/cli/validate_example.bash). This script runs `bazelisk test` inside the [examples](examples) directory.

### Code formatting and linting

For formatting and linting, execute [`development/cli/style_check.bash`](development/cli/style_check.bash).

This script checks for style consistency across the codebase.

## Release process

Only an admin user can release a new version. To initiate a release, the admin should push a tag in the format `X.Y.Z` (e.g., `1.0.0`). This will trigger a CI job that:

- Builds and uploads a tarball
- Creates a GitHub release
- Opens a pull request in the [Bazel Central Registry (BCR)](https://github.com/bazelbuild/bazel-central-registry)

After the BCR PR is approved and merged, the `rules_build_error` module becomes available as a Bazel module.
