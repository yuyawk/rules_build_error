"""Implementations for non-langage-specific build actions.
"""

load("@aspect_bazel_lib//lib:base64.bzl", "base64")

visibility("//lang/...")

# Default value of matcher struct passed to each message assertion.
DEFAULT_MATCHER = struct(
    matcher = None,
    pattern = None,
)

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

    Force internal `ctx.actions.run` execution to fail if the previous build error
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
        ctx.label.name + "/marker_check_build_error",
    )

    # Arguments for `check_emptiness`
    args = ctx.actions.args()

    for file_to_check in files_to_check:
        args.add("-f", file_to_check)

    args.add("-m", error_message)
    args.add("-n", marker_check_build_error)

    ctx.actions.run(
        outputs = [marker_check_build_error],
        inputs = files_to_check,
        executable = check_emptiness,
        arguments = [args],
    )

    return marker_check_build_error

def check_each_message(
        *,
        ctx,
        message_file,
        matcher,
        pattern,
        checker):
    """Check each message with a matcher and a pattern string.

    After checking the message, create an empty text file as a marker for the action.
    This marker file has to be surely evaluated by the rule.

    Args:
        ctx(ctx): The rule's context.
        message_file(File): A text file containing message.
        matcher(File): A matcher executable.
        pattern(str): A pattern string.
        checker(File): Executable file object for `check_each_message.bash`

    Returns:
        File: Marker file for the check.
    """
    marker_file = ctx.actions.declare_file(
        ctx.label.name +
        "/marker_check_each_message/" +
        message_file.basename + "/" +
        # Use base64-encoding to ensure valid characters
        base64.encode(
            data =
                (matcher.path if matcher else "") +
                (pattern if pattern else ""),
        ).replace("/", "-").rstrip("="),
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
            executable = checker,
            arguments = [
                matcher.path,
                pattern,
                message_file.path,
                marker_file.path,
            ],
            tools = [matcher],
        )

    return marker_file
