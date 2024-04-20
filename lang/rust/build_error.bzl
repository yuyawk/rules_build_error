"""Implement `cc_build_error`.
"""

load("@rules_rust//rules_rust/rust:defs.bzl", "rust_common")
load(
    "//lang/private:general_build_actions.bzl",
    "DEFAULT_MATCHER",
    "check_build_error",
    "check_each_message",
    "get_executable_file",
)

visibility("private")

RustBuildErrorInfo = provider(
    doc = "Build error information for C/C++.",
    fields = {
        "compile_stderr": "File: A text file containing stderr when attempting to compile.",
        "compile_stdout": "File: A text file containing stdout when attempting to compile.",
        "markers": "list[File]: Marker files for validation actions.",
    },
)

_RUST_TOOLCHAIN_TYPE = Label("@rules_rust//rust:toolchain_type")

def _find_rust_toolchain(ctx):
    """Find the Rust toolchain.

    Args:
        ctx(ctx): The rule's context.

    Returns:
        rust_toolchain: A Rust toolchain context.
    """
    return ctx.toolchains[_RUST_TOOLCHAIN_TYPE]

def _try_compile(ctx):
    """Try rust compilation.

    Args:
        ctx(ctx): The rule's context.

    Returns:
        struct with the following members:
            output(File): Output file if the action succeeds in compiling the Rust code.
                    Empty text file otherwise
            stderr(File): Stderr while compiling
            stdout(File): Stdout while compiling
    """

    compile_output = ctx.actions.declare_file(ctx.label.name + "/compile_output")
    compile_stderr = ctx.actions.declare_file(ctx.label.name + "/compile_stderr")
    compile_stdout = ctx.actions.declare_file(ctx.label.name + "/compile_stdout")

    rust_toolchain = _find_rust_toolchain(ctx)

    # Input files for executing the action
    inputs = [ctx.file.src]

    # Arguments for `try_build.bash`
    args = ctx.actions.args()
    args.add("-e", compile_stderr)
    args.add("-o", compile_stdout)
    args.add("-n", compile_output)
    args.add("-n", compile_stderr)
    args.add("-n", compile_stdout)

    # From here on `args` is used for the compilation command

    args.add(rust_toolchain.rustc.path)
    args.add("--crate-name", ctx.attr.crate_name if ctx.attr.crate_name else ctx.label.name)
    args.add("--crate-type", "bin")
    args.add("--edition", ctx.attr.edition)

    ctx.actions.run(
        outputs = [compile_output, compile_stdout, compile_stderr],
        inputs = inputs,
        executable = get_executable_file(ctx.attr._try_build),
        arguments = [args],
        tools = rust_toolchain.all_files,
    )

    return struct(
        output = compile_output,
        stdout = compile_stdout,
        stderr = compile_stderr,
    )

def _try_build_impl(ctx):
    """Implementation of the rule `try_cc_build`

    Args:
        ctx(ctx): The rule's context.

    Returns:
        A list of providers.
    """
    compile_result = _try_compile(ctx)
    marker_check_build_error = check_build_error(
        ctx = ctx,
        files_to_check = [
            compile_result.output,
        ],
        error_message = "ERROR: Rust build error didn't occur",
        check_emptiness = get_executable_file(ctx.attr._check_emptiness),
    )

    markers = [marker_check_build_error]
    return [
        RustBuildErrorInfo(
            compile_stderr = compile_result.stderr,
            compile_stdout = compile_result.stdout,
            markers = markers,
        ),
        DefaultInfo(
            # Explicitly specify the markers to make sure the checking action is evaluated
            files = depset(markers),
        ),
    ]

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
        # TODO(soon): Is crate_info needed?
        providers = [
            rust_common.crate_info,
            rust_common.dep_info,
            DefaultInfo,
        ],
    ),
    "edition": attr.string(
        doc = (
            "The rust edition to use for this crate. " +
            "Defaults to the edition specified in the rust_toolchain."
        ),
        mandatory = False,
        default = "2021",
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

_try_build = rule(
    implementation = _try_build_impl,
    attrs = _TRY_BUILD_EXPLICIT_ATTRS | {
        "_check_emptiness": attr.label(
            default = Label("//lang/private/script:check_emptiness"),
        ),
        "_try_build": attr.label(
            default = Label("//lang/private/script:try_build"),
        ),
    },
    toolchains = [_RUST_TOOLCHAIN_TYPE],
    provides = [RustBuildErrorInfo, DefaultInfo],
)
