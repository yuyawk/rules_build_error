"""Implement `cc_build_error`.
"""

load(
    "@bazel_tools//tools/build_defs/cc:action_names.bzl",
    "ACTION_NAMES",
)
load(
    "@bazel_tools//tools/cpp:toolchain_utils.bzl",
    "find_cpp_toolchain",
)
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load(
    "//inline_src:inline_src.bzl",
    "generate_inline_src",
    "is_inline_src",
)
load(
    "//lang/private:general_build_actions.bzl",
    "DEFAULT_MATCHER",
    "LIST_ALL_ARGS",
    "check_build_error",
    "check_each_message",
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
    # keep sorted
    ".c",
]

_EXTENSIONS_CPP = [
    # keep sorted
    ".C",
    ".c++",
    ".cc",
    ".cpp",
    ".cxx",
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
    if _is_c(ctx.file.src):
        ccopts += ctx.fragments.cpp.conlyopts
    elif _is_cpp(ctx.file.src):
        ccopts += ctx.fragments.cpp.cxxopts

    compilation_context = cc_common.merge_compilation_contexts(
        compilation_contexts = [
            dep[CcInfo].compilation_context
            for dep in ctx.attr.deps
        ],
    )

    compile_variables = cc_common.create_compile_variables(
        cc_toolchain = cc_toolchain,
        feature_configuration = features,
        user_compile_flags = ccopts,
        include_directories = compilation_context.includes,
        quote_include_directories = compilation_context.quote_includes,
        system_include_directories = compilation_context.system_includes,
        framework_include_directories = compilation_context.framework_includes,
        preprocessor_defines = depset(
            direct = ctx.attr.local_defines,
            transitive = [compilation_context.defines],
        ),
        source_file = ctx.file.src.path,
        output_file = compile_output.path,
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

    env = cc_common.get_environment_variables(
        feature_configuration = features,
        action_name = compile_action_name,
        variables = compile_variables,
    )

    # Input files for executing the action
    inputs = [ctx.file.src] + compilation_context.headers.to_list()

    # Arguments for `try_build.bash`
    try_build_executable = get_executable_file(ctx.attr._try_build)
    if type(try_build_executable) != "File":
        fail("{} must correspond to an executable".format(ctx.attr._try_build))

    args = ctx.actions.args()
    args.add(try_build_executable)
    args.add("-e", compile_stderr)
    args.add("-o", compile_stdout)
    args.add("-n", compile_output)
    args.add("-n", compile_stderr)
    args.add("-n", compile_stdout)

    # From here on `args` is used for the compilation command
    args.add(compiler)
    args.add_all(compiler_options)

    ctx.actions.run_shell(
        outputs = [compile_output, compile_stdout, compile_stderr],
        inputs = inputs,
        arguments = [args],
        command = LIST_ALL_ARGS,
        tools = cc_toolchain.all_files.to_list() + [try_build_executable],
        env = env,
    )

    return struct(
        output = compile_output,
        stdout = compile_stdout,
        stderr = compile_stderr,
    )

def _get_library_link_option(ctx, library_path):
    """Get library link option, such as `-lfoo`.

    Args:
        ctx(ctx): The rule's context.
        library_path(str): Library path

    Returns:
        list[str]: Link option for the library.
    """

    if ctx.attr.os == "linux":
        return _get_library_link_option_linux(library_path)
    elif ctx.attr.os == "macos":
        return _get_library_link_option_macos(library_path)
    elif ctx.attr.os == "windows":
        return _get_library_link_option_windows(library_path)
    else:
        # This line should be unreachable
        fail("Unsupported OS: {}".format(ctx.attr.os))

def _get_library_link_option_linux(library_path):
    """Get library link option for linux.

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

def _get_library_link_option_macos(library_path):
    """Get library link option for macos.

    Args:
        library_path(str): Library path

    Returns:
        list[str]: Link option for the library.
    """
    if not library_path.startswith("lib"):
        return ["-l", ":" + library_path]

    for ext in [".a", ".so", ".dylib"]:
        if library_path.endswith(ext):
            return ["-l", library_path.removeprefix("lib").removesuffix(ext)]

    return ["-l", ":" + library_path]

def _get_library_link_option_windows(library_path):
    """Get library link option for windows.

    Args:
        library_path(str): Library path

    Returns:
        list[str]: Link option for the library.
    """

    for ext in [".lib", ".dll"]:
        if library_path.endswith(ext):
            return ["-l", library_path.removesuffix(ext)]

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
    try_build_executable = get_executable_file(ctx.attr._try_build)
    if type(try_build_executable) != "File":
        fail("{} must correspond to an executable".format(ctx.attr._try_build))
    args = ctx.actions.args()
    args.add(try_build_executable)
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
                    args.add(*_get_library_link_option(ctx, library.basename))
                    inputs.append(library)

    args.add("-o", link_output)
    args.add(compile_output)

    env = cc_common.get_environment_variables(
        feature_configuration = features,
        action_name = ACTION_NAMES.cpp_link_executable,
        variables = link_variables,
    )

    ctx.actions.run_shell(
        outputs = [link_output, link_stdout, link_stderr],
        inputs = inputs,
        arguments = [args],
        command = LIST_ALL_ARGS,
        tools = cc_toolchain.all_files.to_list() + [try_build_executable],
        env = env,
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

# Explicit attributes for `_try_build`
_TRY_BUILD_EXPLICIT_ATTRS = {
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
}

_try_build = rule(
    implementation = _try_build_impl,
    attrs = _TRY_BUILD_EXPLICIT_ATTRS | {
        "os": attr.string(
            doc = (
                "OS of the build environment. " +
                "This attribute is not user-facing."
            ),
            values = [
                "linux",
                "macos",
                "windows",
            ],
            mandatory = True,
        ),
        "_cc_toolchain": attr.label(
            default = Label("@bazel_tools//tools/cpp:current_cc_toolchain"),
        ),
        "_check_emptiness": attr.label(
            default = Label("//lang/private/script:check_emptiness"),
        ),
        "_try_build": attr.label(
            default = Label("//lang/private/script:try_build"),
        ),
    },
    fragments = ["cpp"],
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
    provides = [CcBuildErrorInfo, DefaultInfo],
)

def _check_messages_impl(ctx):
    """Implementation of `_check_messages`.

    Args:
        ctx(ctx): The rule's context.

    Returns:
        A list of providers.
    """

    cc_build_error_info = ctx.attr.build_trial[CcBuildErrorInfo]
    marker_compile_stderr = check_each_message(
        ctx = ctx,
        id = "compile_stderr",
        message_file = cc_build_error_info.compile_stderr,
        matcher = get_executable_file(ctx.attr.matcher_compile_stderr),
        pattern = ctx.attr.pattern_compile_stderr,
        checker = get_executable_file(ctx.attr._check_each_message),
    )
    marker_compile_stdout = check_each_message(
        ctx = ctx,
        id = "compile_stdout",
        message_file = cc_build_error_info.compile_stdout,
        matcher = get_executable_file(ctx.attr.matcher_compile_stdout),
        pattern = ctx.attr.pattern_compile_stdout,
        checker = get_executable_file(ctx.attr._check_each_message),
    )
    marker_link_stderr = check_each_message(
        ctx = ctx,
        id = "link_stderr",
        message_file = cc_build_error_info.link_stderr,
        matcher = get_executable_file(ctx.attr.matcher_link_stderr),
        pattern = ctx.attr.pattern_link_stderr,
        checker = get_executable_file(ctx.attr._check_each_message),
    )
    marker_link_stdout = check_each_message(
        ctx = ctx,
        id = "link_stdout",
        message_file = cc_build_error_info.link_stdout,
        matcher = get_executable_file(ctx.attr.matcher_link_stdout),
        pattern = ctx.attr.pattern_link_stdout,
        checker = get_executable_file(ctx.attr._check_each_message),
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
            default = Label("//lang/private/script:check_each_message"),
        ),
    },
    provides = [CcBuildErrorInfo, DefaultInfo],
)

def cc_build_error(
        *,
        name,
        compile_stderr = DEFAULT_MATCHER,
        compile_stdout = DEFAULT_MATCHER,
        link_stderr = DEFAULT_MATCHER,
        link_stdout = DEFAULT_MATCHER,
        **kwargs):
    """Check a C/C++ build error.

    Args:
        name(str): Name of the target.
        compile_stderr(matcher struct): Matcher for stderr during compilation.
        compile_stdout(matcher struct): Matcher for stdout during compilation.
        link_stderr(matcher struct): Matcher for stderr while linking.
        link_stdout(matcher struct): Matcher for stdout while linking.
        **kwargs(dict): Passed to internal rules.
    """

    testonly = kwargs.pop("testonly", False)
    tags = kwargs.pop("tags", [])
    visibility = kwargs.pop("visibility", None)

    kwargs_try_build = {
        key: kwargs[key]
        for key in kwargs
        if key in _TRY_BUILD_EXPLICIT_ATTRS
    }
    kwargs_check_messages = {
        key: kwargs[key]
        for key in kwargs
        if key not in _TRY_BUILD_EXPLICIT_ATTRS
    }
    kwargs.clear()

    src = kwargs_try_build.pop("src")
    if is_inline_src(src):
        inline_src_target = name + "__i"
        generate_inline_src(
            name = inline_src_target,
            inline_src = src,
            tags = ["manual"] + tags,
            testonly = testonly,
            visibility = ["//visibility:private"],
        )
        src = ":" + inline_src_target

    try_build_target = name + "__0"
    _try_build(
        name = try_build_target,
        src = src,
        tags = ["manual"] + tags,
        os = select({
            Label("//platforms/os:linux"): "linux",
            Label("//platforms/os:macos"): "macos",
            Label("//platforms/os:windows"): "windows",
            "//conditions:default": "linux",
        }),
        visibility = ["//visibility:private"],
        testonly = testonly,
        **kwargs_try_build
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
        **kwargs_check_messages
    )

def _create_test_impl(ctx):
    """Implementation of `_create_test`.

    Args:
        ctx(ctx): The rule's context.

    Returns:
        A list of providers.
    """
    cc_build_error_info = ctx.attr.cc_build_error[CcBuildErrorInfo]
    extension = ".bat" if ctx.attr.is_windows else ".sh"
    content = "exit 0" if ctx.attr.is_windows else "#!/usr/bin/env bash\nexit 0"
    executable_template = ctx.actions.declare_file(ctx.label.name + "/exe_tpl")
    executable = ctx.actions.declare_file(ctx.label.name + extension)
    ctx.actions.write(
        output = executable_template,
        is_executable = True,
        content = content,
    )
    ctx.actions.run_shell(
        outputs = [executable],
        inputs = cc_build_error_info.markers + [executable_template],
        command = 'cp "$1" "$2"',
        arguments = [
            executable_template.path,
            executable.path,
        ],
    )
    return [
        DefaultInfo(
            files = depset([executable]),
            executable = executable,
        ),
    ]

_create_test = rule(
    implementation = _create_test_impl,
    attrs = {
        "cc_build_error": attr.label(
            doc = "Target for `CcBuildErrorInfo`",
            mandatory = True,
            providers = [CcBuildErrorInfo],
        ),
        "is_windows": attr.bool(
            doc = "Whether the runtime environment is windows or not. " +
                  "This attribute is not user-facing.",
            mandatory = True,
        ),
    },
    test = True,
)

def cc_build_error_test(*, name, **kwargs):
    """Test rule checking `cc_build_error` builds.

    Args:
        name(str): Name of the test target.
        **kwargs(dict): Receives the same keyword arguments as `cc_build_error`.
    """
    build_target_name = name + "__0"

    # `testonly` is always true.
    kwargs["testonly"] = True

    # Arguments passed to the test target.
    tags = kwargs.pop("tags", [])
    visibility = kwargs.pop("visibility", None)

    cc_build_error(
        name = build_target_name,
        tags = tags + ["manual"],
        visibility = ["//visibility:private"],
        **kwargs
    )

    _create_test(
        name = name,
        cc_build_error = ":" + build_target_name,
        is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        tags = tags,
        visibility = visibility,
        timeout = "short",
    )
