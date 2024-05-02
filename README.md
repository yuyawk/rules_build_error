# `rules_build_error`

Bazel implementations to test a build error.

## Description

There's a situation where a developer wants to test if particular code doesn't compile. However, when using ordinary testing rules, such as `cc_test`, `bazel test` results in an error if the test code doesn't compile.

`rules_build_error` is the repository to address such a problem. It provides some implementations to test the compilation error for each programming language. When the code written in a particular programming language **does** compile, `bazel build` should fail for the associated target.

## Usage

Also refer to [the example module](examples) for more details.

### C/C++ usage

```bazel
load("@rules_build_error//lang/cc:defs.bzl", "cc_build_error")
load("@rules_build_error//matcher:defs.bzl", "matcher")

cc_build_error(
    name = "cause_compile_error",
    src = "cause_compile_error.cpp",
    deps = [":library_to_successfully_link"], # `:library_to_successfully_link` must provide `CcInfo`, like `cc_library`
    compile_stderr = matcher.has_substr("static assertion failed"),
)
```

## Language-specific implementations

The implementations to check the build error in a particular language is available.

### C/C++ implementation

Refer to [its readme](lang/cc/README.md)

## Matcher

In order to specify how to validate the error message, a struct `matcher` is available. Refer to [its readme](matcher/README.md) for more details.

## Development

### How to test

Each test script requires the installation of [`bazelisk`](https://github.com/bazelbuild/bazelisk) in advance.

#### Unit tests

Execute [`development/cli/execute_tests.bash`](development/cli/execute_tests.bash). It performs `bazelisk test` and `bazelisk build` commands under the hood.

Note that some unit test cases with `tags = ["manual"]` are for checking the failure of `bazel build`, by executing the build command one by one.

#### Example

Execute [`development/cli/validate_example.bash`](development/cli/validate_example.bash). It performs `bazelisk test` inside the [examples](examples) directory.

#### Formatting and linting

Execute [`development/cli/style_check.bash`](development/cli/style_check.bash).

### How to release

When the admin user pushes a tag "X.Y.Z" (where X, Y and Z are non-negative integers), the CI job automatically cuts a release, uploads a tar ball and create a corresponding PR in [BCR](https://github.com/bazelbuild/bazel-central-registry). After the PR is approved and merged, the bazel module of `rules_build_error` becomes available.

## CI

[![Tests](https://github.com/yuyawk/rules_build_error/actions/workflows/tests.yml/badge.svg)](https://github.com/yuyawk/rules_build_error/actions/workflows/tests.yml)

[![Bazel Steward](https://github.com/yuyawk/rules_build_error/actions/workflows/bazel-steward.yml/badge.svg)](https://github.com/yuyawk/rules_build_error/actions/workflows/bazel-steward.yml)

[![Release](https://github.com/yuyawk/rules_build_error/actions/workflows/release.yml/badge.svg)](https://github.com/yuyawk/rules_build_error/actions/workflows/release.yml)
