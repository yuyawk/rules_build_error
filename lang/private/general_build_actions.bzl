"""Implementations for non-langage-specific build actions.
"""

visibility("//lang/...")

# Default value of matcher struct passed to each message assertion.
DEFAULT_MATCHER = struct(
    matcher = None,
    pattern = None,
)

LIST_ALL_ARGS = '"$@"'

def get_executable_file(label):
    """Get executable file if the label is not None.

    Args:
        label(label or None): Executable label

    Returns:
        File: Executable file.
    """
    if not label:
        return None
    return label.files_to_run.executable

def check_build_error(
        *,
        ctx,
        files_to_check,
        error_message,
        check_emptiness):
    """Check if a build error occured.

    Force internal `ctx.actions.run_shell` execution to fail if the previous build error
    did NOT occur, otherwise, create an empty text file as a marker for the action.
    This marker file has to be surely evaluated by the rule.

    Args:
        ctx(ctx): The rule's context.
        files_to_check(list[File]): Output of the previous build actions.
        error_message(str): Error message when the validation fails
        check_emptiness(File): Executable file object of `check_emptiness.bash`.

    Returns:
        File: Marker file for the check.
    """

    # Marker file for the check
    marker_check_build_error = ctx.actions.declare_file(
        ctx.label.name + "/m_cbe",
    )

    # Create a text file to contain the error message
    # in order to easily escape its characters
    error_message_file = ctx.actions.declare_file(
        ctx.label.name + "/e_cbe",
    )
    ctx.actions.write(
        output = error_message_file,
        content = error_message,
    )

    # Arguments for `check_emptiness`
    args = ctx.actions.args()
    args.add(check_emptiness)

    for file_to_check in files_to_check:
        args.add("-f", file_to_check)

    args.add("-m", error_message_file)
    args.add("-n", marker_check_build_error)

    ctx.actions.run_shell(
        outputs = [marker_check_build_error],
        inputs = files_to_check + [error_message_file],
        command = LIST_ALL_ARGS,
        arguments = [args],
        tools = [check_emptiness],
    )

    return marker_check_build_error

def check_each_message(
        *,
        ctx,
        id,
        message_file,
        matcher,
        pattern,
        checker):
    """Check each message with a matcher and a pattern string.

    After checking the message, create an empty text file as a marker for the action.
    This marker file has to be surely evaluated by the rule.

    Args:
        ctx(ctx): The rule's context.
        id(str): Identifier string to distinguish different checks corresponding to the same label.
        message_file(File): A text file containing message.
        matcher(File): A matcher executable.
        pattern(str): A pattern string.
        checker(File): Executable file object for `check_each_message.bash`

    Returns:
        File: Marker file for the check.
    """

    # Marker for the check
    marker_file = ctx.actions.declare_file(
        ctx.label.name +
        "/m_cem/" +
        id,
    )

    # Text file containing the pattern string
    pattern_file = ctx.actions.declare_file(
        ctx.label.name +
        "/p_cem/" +
        id,
    )

    if not matcher:
        if pattern:
            fail(
                "When not specifying the matcher, " +
                "pattern string must be empty",
            )

        ctx.actions.run(
            outputs = [marker_file, pattern_file],
            executable = "touch",
            arguments = [
                marker_file.path,
                pattern_file.path,
            ],
        )
    else:
        if not pattern:
            fail(
                "When specifying the matcher, " +
                "pattern string must not be empty",
            )

        ctx.actions.write(
            output = pattern_file,
            content = pattern,
        )

        ctx.actions.run_shell(
            outputs = [marker_file],
            inputs = [message_file, pattern_file],
            command = LIST_ALL_ARGS,
            arguments = [
                checker.path,
                matcher.path,
                pattern_file.path,
                message_file.path,
                marker_file.path,
            ],
            tools = [checker, matcher],
        )

    return marker_file
