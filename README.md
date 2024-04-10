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

Execute [`scripts/execute_tests.bash`](scripts/execute_tests.bash) after installing [`bazelisk`](https://github.com/bazelbuild/bazelisk). It executes `bazelisk test` and `bazelisk build` commands under the hood.

When writing tests, in principle, use `tags = ["manual"]` if a test case target must fail with `bazelisk test`. In such a test case, confirm its failure in [`scripts/execute_tests.bash`](scripts/execute_tests.bash) one by one.

## CI

[![Tests](https://github.com/yuyawk/rules_build_error/actions/workflows/tests.yml/badge.svg)](https://github.com/yuyawk/rules_build_error/actions/workflows/tests.yml)

[![Bazel Steward](https://github.com/yuyawk/rules_build_error/actions/workflows/bazel-steward.yml/badge.svg)](https://github.com/yuyawk/rules_build_error/actions/workflows/bazel-steward.yml)
