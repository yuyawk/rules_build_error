# C/C++ build error

Defines some implementations to check build error in C/C++.

## `cc_build_error`

`cc_build_error` is a rule providing [`CcBuildErrorInfo`](#ccbuilderrorinfo).

In addition to the common rule attributes listed [here](https://bazel.build/reference/be/common-definitions#common-attributes), it can receive the following attributes (regarding the specific matcher, please refer to [its readme](../../matcher/README.md)):

| Attribute                | Description                                                        | Type             | Is this attribute required? | Other constraints                                   |
| ------------------------ | ------------------------------------------------------------------ | ---------------- | --------------------------- | --------------------------------------------------- |
| name                     | Name of the target.                                                | str              | Yes                         |                                                     |
| src                      | C/C++ source file to check build                                   | label            | Yes                         | Must be a single file having an extension for C/C++ |
| additional_linker_inputs | Pass these files to the linker command                             | list of labels   | No (defaults to `[]`)       |                                                     |
| copts                    | C/C++ compilation options                                          | list of str      | No (defaults to `[]`)       |                                                     |
| deps                     | The list of CcInfo libraries to be linked in to the binary target. | list of label    | No (defaults to `[]`)       | Each list element must provide `CcInfo`             |
| linkopts                 | C/C++ linking options                                              | list of str      | No (defaults to `[]`)       |                                                     |
| local_defines            | Pre-processor macro definitions                                    | list of str      | No (defaults to `[]`)       |                                                     |
| compile_stderr           | Matcher for the stderr message while compiling                     | specific matcher | No (defaults to no-op)      |                                                     |
| compile_stdout           | Matcher for the stdout message while compiling                     | specific matcher | No (defaults to no-op)      |                                                     |
| link_stderr              | Matcher for the stderr message while linking                       | specific matcher | No (defaults to no-op)      |                                                     |
| link_stdout              | Matcher for the stdout message while linking                       | specific matcher | No (defaults to no-op)      |                                                     |

### `CcBuildErrorInfo`

`CcBuildErrorInfo` is a provider describing the build error in C/C++. See its definition in [its bzl file](./build_error.bzl) for its details.

## `cc_build_error_test`

`cc_build_error_test` is a test rule used to verify that `cc_build_error` builds successfully. It accepts the same set of arguments as `cc_build_error`.
