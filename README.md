# `rules_build_error`

Bazel rules to test build errors.

## Description

`rules_build_error` provides Bazel implementations that let developers verify code that **should not** compile.

When executing `bazel test`, standard Bazel testing rules, like `cc_test`, will result in an error if a test code doesn’t compile. With `rules_build_error`, a `bazel build` command will instead fail when code **does** compile, indicating that the target is expected to raise a compilation error.

## Usage

For more examples, see [the example module](examples).

Load this module from the [Bazel Central Registry](https://registry.bazel.build/modules/rules_build_error) to use it as a Bazel module.

### C/C++ example

```bazel
load("@rules_build_error//lang/cc:defs.bzl", "cc_build_error_test")
load("@rules_build_error//matcher:defs.bzl", "matcher")

cc_build_error_test(
    name = "cause_compile_error",
    src = "cause_compile_error.cpp",
    deps = [":library_to_successfully_link"], # `:library_to_successfully_link` must provide `CcInfo`, like `cc_library`
    compile_stderr = matcher.has_substr("static assertion failed"),
)
```

## Language-specific implementations

See individual language implementations:

- [C/C++ README](lang/cc/README.md)

## Matcher

The `matcher` struct allows specific error message matching criteria. Learn more in [its readme](matcher/README.md).

## Contributing

Pull requests and issues are welcome! See [DEVEL.md](DEVEL.md) for development documentation.

## CI status

[![Tests](https://github.com/yuyawk/rules_build_error/actions/workflows/tests.yml/badge.svg)](https://github.com/yuyawk/rules_build_error/actions/workflows/tests.yml)

[![Bazel Steward](https://github.com/yuyawk/rules_build_error/actions/workflows/bazel-steward.yml/badge.svg)](https://github.com/yuyawk/rules_build_error/actions/workflows/bazel-steward.yml)

[![Release](https://github.com/yuyawk/rules_build_error/actions/workflows/release.yml/badge.svg)](https://github.com/yuyawk/rules_build_error/actions/workflows/release.yml)
