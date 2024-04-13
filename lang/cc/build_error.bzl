"""Implement `cc_build_error`.
"""

load(
    "@bazel_tools//tools/build_defs/cc:action_names.bzl",
    "ACTION_NAMES",
)
load(
    "@bazel_tools//tools/cpp:toolchain_utils.bzl",
    "CPP_TOOLCHAIN_TYPE",
    "find_cpp_toolchain",
)
load(
    "//bzl_internal:general_build_actions.bzl",
    "check_build_error",
    "get_executable_file",
)

visibility("private")

CcBuildErrorInfo = provider(
    doc = "Build error information for C/C++",
    fields = {
        "compile_stderr": "File: A text file containing stderr when attempting to compile",
        "compile_stdout": "File: A text file containing stdout when attempting to compile",
        "link_stderr": "File: A text file containing stderr when attempting to link",
        "link_stdout": "File: A text file containing stdout when attempting to link",
        "markers": "list[File]: Marker files for validation actions",
    },
)

_EXTENSIONS_C = [
    ".c",
    ".C",
]

_EXTENSIONS_CPP = [
    ".cc",
    ".cpp",
    ".cxx",
    ".c++",
]

def _is_c(src_file):
    """Whether the source file is for C.

    Args:
        src_file(File): C/C++ source file

    Returns:
        bool: Whether the source file is for C.
    """
    return "." + src_file.extension in _EXTENSIONS_C

def _is_cpp(src_file):
    """Whether the source file is for C++.

    Args:
        src_file(File): C/C++ source file

    Returns:
        bool: Whether the source file is for C++.
    """
    return "." + src_file.extension in _EXTENSIONS_CPP

def _get_compile_action_name(src_file):
    """Get action name for compilation

    Args:
        src_file(File): C/C++ source file

    Returns:
        str: Compilation action name
    """
    if _is_c(src_file):
        return ACTION_NAMES.c_compile
    elif _is_cpp(src_file):
        return ACTION_NAMES.cpp_compile
    else:
        fail("Unsupported file type ({})".format(src_file.path))

def _try_compile(ctx):
    """Try C/C++ compilation.

    Args:
        ctx(ctx): The rule's context.

    Returns:
        struct with the following members:
            output(File): Object file if the action succeeds in compiling the C/C++ code.
                    Empty text file otherwise
            stderr(File): Stderr while compiling
            stdout(File): Stdout while compiling
    """

    compile_output = ctx.actions.declare_file(ctx.label.name + "/compile_output")
    compile_stderr = ctx.actions.declare_file(ctx.label.name + "/compile_stderr")
    compile_stdout = ctx.actions.declare_file(ctx.label.name + "/compile_stdout")

    cc_toolchain = find_cpp_toolchain(ctx)
    features = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    ccopts = ctx.fragments.cpp.copts + ctx.attr.copts
    if _is_cpp(ctx.file.src):
        ccopts += ctx.fragments.cpp.cxxopts

    compile_variables = cc_common.create_compile_variables(
        cc_toolchain = cc_toolchain,
        feature_configuration = features,
        user_compile_flags = ccopts,
    )

    compile_action_name = _get_compile_action_name(ctx.file.src)

    compiler = cc_common.get_tool_for_action(
        feature_configuration = features,
        action_name = compile_action_name,
    )

    compiler_options = cc_common.get_memory_inefficient_command_line(
        feature_configuration = features,
        action_name = compile_action_name,
        variables = compile_variables,
    )

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
    args.add(compiler)

    for dep in ctx.attr.deps:
        compilation_context = dep[CcInfo].compilation_context
        args.add_all(compilation_context.defines, before_each = "-D")
        args.add_all(compilation_context.framework_includes, before_each = "-F")
        args.add_all(compilation_context.includes, before_each = "-I")
        args.add_all(compilation_context.quote_includes, before_each = "-iquote")
        args.add_all(compilation_context.system_includes, before_each = "-isystem")
        inputs += compilation_context.headers.to_list()

    args.add_all(compiler_options)

    args.add_all(ctx.attr.local_defines, before_each = "-D")

    args.add("-c", ctx.file.src)
    args.add("-o", compile_output)

    ctx.actions.run(
        outputs = [compile_output, compile_stdout, compile_stderr],
        inputs = inputs,
        executable = get_executable_file(ctx.attr._try_build),
        arguments = [args],
        tools = cc_toolchain.all_files,
    )

    return struct(
        output = compile_output,
        stdout = compile_stdout,
        stderr = compile_stderr,
    )

def _get_library_link_option(library_path):
    """Get library link option, such as `-lfoo`.

    Args:
        library_path(str): Library path

    Returns:
        list[str]: Link option for the library.
    """
    if not library_path.startswith("lib"):
        return ["-l", ":" + library_path]

    for ext in [".a", ".so"]:
        if library_path.endswith(ext):
            return ["-l", library_path.removeprefix("lib").removesuffix(ext)]

    return ["-l", ":" + library_path]

def _try_link(ctx, compile_output):
    """Try linking the object file.

    Execute the linking action if the previous compilation action succeeded.
    Otherwise, just create empty files.

    Args:
        ctx(ctx): The rule's context.
        compile_output: Output of the previous compilation action.

    Returns:
        struct with the following members:
            output(File): Object file if the action succeeds in linking the object file.
                    Empty text file otherwise
            stderr(File): Stderr while linking
            stdout(File): Stdout while linking
    """

    link_output = ctx.actions.declare_file(ctx.label.name + "/link_output")
    link_stderr = ctx.actions.declare_file(ctx.label.name + "/link_stderr")
    link_stdout = ctx.actions.declare_file(ctx.label.name + "/link_stdout")

    cc_toolchain = find_cpp_toolchain(ctx)
    features = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    link_variables = cc_common.create_link_variables(
        cc_toolchain = cc_toolchain,
        feature_configuration = features,
        user_link_flags = ctx.fragments.cpp.linkopts + ctx.attr.linkopts,
    )

    linker = cc_common.get_tool_for_action(
        feature_configuration = features,
        action_name = ACTION_NAMES.cpp_link_executable,
    )

    linker_options = cc_common.get_memory_inefficient_command_line(
        feature_configuration = features,
        action_name = ACTION_NAMES.cpp_link_executable,
        variables = link_variables,
    )

    inputs = [compile_output] + ctx.attr.additional_linker_inputs

    # Arguments for `try_build.bash`
    args = ctx.actions.args()
    args.add("-e", link_stderr)
    args.add("-o", link_stdout)
    args.add("-n", link_output)
    args.add("-n", link_stderr)
    args.add("-n", link_stdout)

    # If the compilation output is empty, it means the previous compilation failed.
    # In such a case, linking is skipped
    args.add("-f", compile_output)

    # From here on `args` is used for the linking command
    args.add(linker)
    args.add_all(linker_options)
    for dep in ctx.attr.deps:
        for linker_input in dep[CcInfo].linking_context.linker_inputs.to_list():
            inputs += linker_input.additional_inputs
            args.add_all(linker_input.user_link_flags)
            for library_to_link in linker_input.libraries:
                # TODO: Ideally the way of linking should be controlled by the attributes
                library = library_to_link.static_library if library_to_link.static_library else library_to_link.dynamic_library
                if library:
                    args.add("-L", library.dirname)
                    args.add(*_get_library_link_option(library.basename))
                    inputs.append(library)

    args.add("-o", link_output)
    args.add(compile_output)

    ctx.actions.run(
        outputs = [link_output, link_stdout, link_stderr],
        inputs = inputs,
        executable = get_executable_file(ctx.attr._try_build),
        arguments = [args],
        tools = cc_toolchain.all_files,
    )

    return struct(
        output = link_output,
        stdout = link_stdout,
        stderr = link_stderr,
    )

def _try_build_impl(ctx):
    """Implementation of the rule `try_cc_build`

    Args:
        ctx(ctx): The rule's context.

    Returns:
        A list of providers.
    """
    compile_result = _try_compile(ctx)
    link_result = _try_link(ctx, compile_result.output)
    marker_check_build_error = check_build_error(
        ctx = ctx,
        marker_file_name = ctx.label.name + "/marker_check_build_error",
        files_to_check = [
            compile_result.output,
            link_result.output,
        ],
        error_message = "ERROR: C/C++ build error didn't occur",
        check_emptiness = get_executable_file(ctx.attr._check_emptiness),
    )

    markers = [marker_check_build_error]
    return [
        CcBuildErrorInfo(
            compile_stderr = compile_result.stderr,
            compile_stdout = compile_result.stdout,
            link_stderr = link_result.stderr,
            link_stdout = link_result.stdout,
            markers = markers,
        ),
        DefaultInfo(
            # Explicitly specify the markers to make sure the checking action is evaluated
            files = depset(markers),
        ),
    ]

_try_build = rule(
    implementation = _try_build_impl,
    attrs = {
        "additional_linker_inputs": attr.label_list(
            doc = "Pass these files to the linker command",
            allow_empty = True,
            allow_files = True,
            mandatory = False,
        ),
        "copts": attr.string_list(
            doc = "Add these options to the compilation command",
            allow_empty = True,
            mandatory = False,
        ),
        "deps": attr.label_list(
            doc = "The list of CcInfo libraries to be linked in to the target",
            allow_empty = True,
            mandatory = False,
            providers = [CcInfo],
        ),
        "linkopts": attr.string_list(
            doc = "Add these options to the linker command",
            allow_empty = True,
            mandatory = False,
        ),
        "local_defines": attr.string_list(
            doc = "List of pre-processor macro definitions to add to the compilation command",
            allow_empty = True,
            mandatory = False,
        ),
        "src": attr.label(
            doc = "C/C++ file to be processed",
            mandatory = True,
            allow_single_file = _EXTENSIONS_C + _EXTENSIONS_CPP,
        ),
        "_cc_toolchain": attr.label(
            default = Label("@bazel_tools//tools/cpp:current_cc_toolchain"),
        ),
        "_check_emptiness": attr.label(
            default = Label("//build_script:check_emptiness"),
        ),
        "_try_build": attr.label(
            default = Label("//build_script:try_build"),
        ),
    },
    fragments = ["cpp"],
    toolchains = [CPP_TOOLCHAIN_TYPE],
    provides = [CcBuildErrorInfo, DefaultInfo],
)

def _check_each_message(ctx, message_file, matcher, pattern):
    """Check each message with a matcher and a pattern string.

    Args:
        ctx(ctx): The rule's context.
        message_file(File): A text file containing message.
        matcher(File): A matcher executable.
        pattern(str): A pattern string.

    Returns:
        File: Marker file for the check.
    """
    marker_file = ctx.actions.declare_file(
        ctx.label.name +
        "/marker_check_message__" +
        message_file.basename + "__" +
        (matcher.path if matcher else "NONE") + "__" +
        (pattern if pattern else "NONE") + "__",
    )

    if not matcher:
        if pattern:
            fail(
                "When not specifying the matcher, " +
                "pattern string must be empty",
            )

        ctx.actions.run(
            outputs = [marker_file],
            executable = "touch",
            arguments = [
                marker_file.path,
            ],
        )
    else:
        if not pattern:
            fail(
                "When specifying the matcher, " +
                "pattern string must not be empty",
            )

        ctx.actions.run(
            outputs = [marker_file],
            inputs = [message_file],
            executable = get_executable_file(ctx.attr._check_each_message),
            arguments = [
                matcher.path,
                pattern,
                message_file.path,
                marker_file.path,
            ],
            tools = [matcher],
        )

    return marker_file

def _check_messages_impl(ctx):
    """Implementation of `_check_messages`.

    Args:
        ctx(ctx): The rule's context.

    Returns:
        A list of providers.
    """

    cc_build_error_info = ctx.attr.build_trial[CcBuildErrorInfo]
    marker_compile_stderr = _check_each_message(
        ctx,
        cc_build_error_info.compile_stderr,
        get_executable_file(ctx.attr.matcher_compile_stderr),
        ctx.attr.pattern_compile_stderr,
    )
    marker_compile_stdout = _check_each_message(
        ctx,
        cc_build_error_info.compile_stdout,
        get_executable_file(ctx.attr.matcher_compile_stdout),
        ctx.attr.pattern_compile_stdout,
    )
    marker_link_stderr = _check_each_message(
        ctx,
        cc_build_error_info.link_stderr,
        get_executable_file(ctx.attr.matcher_link_stderr),
        ctx.attr.pattern_link_stderr,
    )
    marker_link_stdout = _check_each_message(
        ctx,
        cc_build_error_info.link_stdout,
        get_executable_file(ctx.attr.matcher_link_stdout),
        ctx.attr.pattern_link_stdout,
    )
    markers = [
        marker_compile_stderr,
        marker_compile_stdout,
        marker_link_stderr,
        marker_link_stdout,
    ] + cc_build_error_info.markers
    return [
        CcBuildErrorInfo(
            compile_stderr = cc_build_error_info.compile_stderr,
            compile_stdout = cc_build_error_info.compile_stdout,
            link_stderr = cc_build_error_info.compile_stderr,
            link_stdout = cc_build_error_info.compile_stdout,
            markers = markers,
        ),
        DefaultInfo(
            # Explicitly specify the markers to make sure the checking action is evaluated
            files = depset(markers),
        ),
    ]

_check_messages = rule(
    implementation = _check_messages_impl,
    attrs = {
        "build_trial": attr.label(
            doc = "`_try_build` target",
            mandatory = True,
            providers = [CcBuildErrorInfo],
        ),
        "matcher_compile_stderr": attr.label(
            doc = "Matcher executable for stderr while compiling",
            mandatory = False,
        ),
        "matcher_compile_stdout": attr.label(
            doc = "Matcher executable for stdout while compiling",
            mandatory = False,
        ),
        "matcher_link_stderr": attr.label(
            doc = "Matcher executable for stderr while linking",
            mandatory = False,
        ),
        "matcher_link_stdout": attr.label(
            doc = "Matcher executable for stdout while linking",
            mandatory = False,
        ),
        "pattern_compile_stderr": attr.string(
            doc = "Pattern string for stderr while compiling",
            mandatory = False,
        ),
        "pattern_compile_stdout": attr.string(
            doc = "Pattern string for stdout while compiling",
            mandatory = False,
        ),
        "pattern_link_stderr": attr.string(
            doc = "Pattern string for stderr while linking",
            mandatory = False,
        ),
        "pattern_link_stdout": attr.string(
            doc = "Pattern string for stdout while linking",
            mandatory = False,
        ),
        "_check_each_message": attr.label(
            default = Label("//build_script:check_each_message"),
        ),
    },
    provides = [CcBuildErrorInfo, DefaultInfo],
)

_DEFAULT_MATCHER = struct(
    matcher = None,
    pattern = None,
)

def cc_build_error(
        *,
        name,
        compile_stderr = _DEFAULT_MATCHER,
        compile_stdout = _DEFAULT_MATCHER,
        link_stderr = _DEFAULT_MATCHER,
        link_stdout = _DEFAULT_MATCHER,
        **kwargs):
    """Check a C/C++ build error.

    Args:
        name(str): Name of the target.
        compile_stderr(matcher struct): Matcher for stderr during compilation.
        compile_stdout(matcher struct): Matcher for stdout during compilation.
        link_stderr(matcher struct): Matcher for stderr while linking.
        link_stdout(matcher struct): Matcher for stdout while linking.
        **kwargs(dict): Passed to `_try_build`.
    """

    testonly = kwargs.pop("testonly", False)
    tags = kwargs.pop("tags", [])
    visibility = kwargs.pop("visibility", None)

    try_build_target = name + "__try_build"
    _try_build(
        name = try_build_target,
        tags = ["manual"] + tags,
        visibility = ["//visibility:private"],
        testonly = testonly,
        **kwargs
    )

    _check_messages(
        name = name,
        build_trial = ":" + try_build_target,
        matcher_compile_stderr = compile_stderr.matcher,
        matcher_compile_stdout = compile_stdout.matcher,
        matcher_link_stderr = link_stderr.matcher,
        matcher_link_stdout = link_stdout.matcher,
        pattern_compile_stderr = compile_stderr.pattern,
        pattern_compile_stdout = compile_stdout.pattern,
        pattern_link_stderr = link_stderr.pattern,
        pattern_link_stdout = link_stdout.pattern,
        visibility = visibility,
        tags = tags,
        testonly = testonly,
    )
