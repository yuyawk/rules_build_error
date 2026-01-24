# C/C++ Build Errors

Defines implementations to check build errors in C/C++. All implementations can be loaded from `//lang/cc:defs.bzl`.

## `cc_build_error`

`cc_build_error` is a rule that provides [`CcBuildErrorInfo`](#ccbuilderrorinfo).

### Attributes

Besides the common rule attributes documented in the [official Bazel documentation](https://bazel.build/reference/be/common-definitions#common-attributes), this rule supports the following attributes (for the term MatchCondition, see the [matcher README](../../matcher/README.md)):

| Attribute                | Description                                                                                                           | Type                                  | Required? | Default | Constraints                                                       |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------- | ------------------------------------- | --------- | ------- | ----------------------------------------------------------------- |
| name                     | Target name.                                                                                                          | str                                   | Yes       |         |                                                                   |
| src                      | C/C++ source file to check build.                                                                                     | label or [inline source](#inline_src) | Yes       |         | When using a label, must be a single file with a C/C++ extension. |
| additional_linker_inputs | Files to pass to the linker command.                                                                                  | list of labels                        | No        | `[]`    |                                                                   |
| copts                    | C/C++ compiler options.                                                                                               | list of str                           | No        | `[]`    |                                                                   |
| deps                     | `CcInfo` libraries to link.                                                                                           | list of labels                        | No        | `[]`    | Each element must provide `CcInfo`.                               |
| linkopts                 | Linker options.                                                                                                       | list of str                           | No        | `[]`    |                                                                   |
| local_defines            | Preprocessor macro definitions.                                                                                       | list of str                           | No        | `[]`    |                                                                   |
| use_default_shell_env    | Whether actions use the default shell environment. Equivalent to the corresponding `ctx.actions.run_shell` parameter. | bool                                  | No        | `False` |                                                                   |
| compile_stderr           | MatchCondition for compiler stderr output.                                                                            | MatchCondition                        | No        | no-op   |                                                                   |
| compile_stdout           | MatchCondition for compiler stdout output.                                                                            | MatchCondition                        | No        | no-op   |                                                                   |
| link_stderr              | MatchCondition for linker stderr output.                                                                              | MatchCondition                        | No        | no-op   |                                                                   |
| link_stdout              | MatchCondition for linker stdout output.                                                                              | MatchCondition                        | No        | no-op   |                                                                   |

### `CcBuildErrorInfo`

`CcBuildErrorInfo` is a provider that describes a C/C++ build error. See [build_error.bzl](./build_error.bzl) for its definition.

## `cc_build_error_test`

`cc_build_error_test` is a test rule that verifies `cc_build_error` builds successfully. It accepts the same arguments as `cc_build_error`.

## `inline_src`

Use the `inline_src` struct to provide source code as an inline string, like `src = inline_src.c("int main(void) { return 0; }")`. Use `inline_src.c` for C code and `inline_src.cpp` for C++ code. Both functions accept a string containing the source code.
