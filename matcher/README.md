# Matcher

Defines a struct `matcher`, which can be loaded from `//matcher:defs.bzl`.

`matcher` has some member functions each of which receives a pattern string as a positional string argument, and which returns the corresponding [MatchCondition](#matchcondition). Each MatchCondition can be used to specify the way of validating the build error message (stderr or stdout).

The member functions of `matcher` are as follows

| Member                  | Description                                                           |
| ----------------------- | --------------------------------------------------------------------- |
| contains_basic_regex    | Check if the message contains the basic regular expression pattern    |
| contains_extended_regex | Check if the message contains the extended regular expression pattern |
| has_substr              | Check if the message has the sub-string                               |

## Usage

```bazel
load("@rules_build_error//lang/cc:defs.bzl", "cc_build_error_test")
load("@rules_build_error//matcher:defs.bzl", "matcher")

cc_build_error_test(
    name = "cause_compile_error",
    src = "cause_compile_error.cpp",
    compile_stderr = matcher.has_substr("I'm the error"),
)
```

This example checks that the compiler’s standard error output contains the substring `"I'm the error"`.

### `select()`

Match conditions can incorporate `select()` in two different ways.

#### `select()` inside a match condition

You can embed a `select()` call directly within a matcher argument. This is useful when only part of the expected message varies by constraint:

```bazel
cc_build_error_test(
    name = "select_inside_match_condition",
    src = "cause_compile_error.cpp",
    compile_stderr = matcher.has_substr("The target platform is " + select({
        "@platforms//os:linux": "linux",
        "@platforms//os:windows": "Windows",
        "@platforms//os:macos": "macOS",
        "//conditions:default": "unknown",
    })),
)
```

#### `select()` outside match conditions

Alternatively, you can use `select()` to switch an entirely different match condition per constraint:

```bazel
cc_build_error_test(
    name = "select_outside_match_conditions",
    src = "c_compile_error.c",
    compile_stderr = select({
        "@platforms//os:linux": matcher.has_substr("The target platform is linux"),
        "@platforms//os:windows": matcher.contains_basic_regex(r"The[[:space:]]target \(p\|P\)latform is Windows"),
        "@platforms//os:macos": matcher.contains_extended_regex("The[[:space:]]target (p|P)latform is macOS"),
        "//conditions:default": matcher.has_substr("The target platform is unknown"),
    }),
)
```

### Multiple match conditions

You can combine multiple match conditions to express a logical AND by joining them with the `+` operator:

```bazel
cc_build_error_test(
    name = "with_multiple_matcher_conditions",
    src = "c_compile_error.c",
    compile_stderr = matcher.has_substr("Multiple match conditions") +
                     matcher.contains_basic_regex(r"must[[:space:]]be[[:space:]]supported") +
                     matcher.contains_extended_regex(r"by (t|T)his framework\."),
)
```

All specified matcher conditions must be satisfied for the test to pass.

## MatchCondition

Throughout this repository, the term **MatchCondition** refers to an object that defines how to match a pattern against a target string.
