"""Implement `cc_build_error`.
"""

visibility("private")

RustBuildErrorInfo = provider(
    doc = "Build error information for C/C++.",
    fields = {
        "compile_stderr": "File: A text file containing stderr when attempting to compile.",
        "compile_stdout": "File: A text file containing stdout when attempting to compile.",
        "markers": "list[File]: Marker files for validation actions.",
    },
)

# Explicit attributes for `_try_build`
_TRY_BUILD_EXPLICIT_ATTRS = {
    "aliases": attr.label_keyed_string_dict(
        doc = "Remap crates to a new name or moniker for linkage to this target.",
        mandatory = False,
    ),
    "compile_data": attr.label_list(
        doc = "List of files used by this rule at compile time.",
        mandatory = False,
    ),
    "crate_features": attr.string_list(
        doc = "List of features to enable for this crate.",
        mandatory = False,
    ),
    "crate_name": attr.string(
        doc = (
            "Crate name to use for this target. " +
            "This must be a valid Rust identifier, " +
            "i.e. it may contain only alphanumeric characters and underscores" +
            "Defaults to the target name, with any hyphens replaced by underscores."
        ),
        mandatory = False,
    ),
    "deps": attr.label_list(
        doc = "List of other libraries to be linked to this library target.",
        mandatory = False,
        # TODO(soon in the PR): Specify the provider
    ),
    "edition": attr.string(
        doc = (
            "The rust edition to use for this crate. " +
            "Defaults to the edition specified in the rust_toolchain."
        ),
        mandatory = False,
    ),
    "rustc_flags": attr.string_list(
        doc = "List of compiler flags passed to `rustc`.",
        mandatory = False,
    ),
    "src": attr.label(
        adoc = "Rust source file to be processed",
        mandatory = True,
        allow_single_file = [".rs"],
    ),
}
