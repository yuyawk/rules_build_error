# `rules_build_error`

Bazel implementations to test a build error.

## Description

There's a situation where a developer wants to test if particular code doesn't compile. However, when using ordinary testing rules, such as `cc_test`, `bazel test` results in an error if the test code doesn't compile.

`rules_build_error` is the repository to address such an issue. It provides some implementations to test the compilation error for each programming language. When the code written in a particular **does** compile,  `bazel build` should fail.

## Usage

## Language-specific implementations

### C/C++

## Matcher
