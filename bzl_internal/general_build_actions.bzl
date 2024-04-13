"""Implementations for non-langage-specific build actions.
"""

visibility("//lang/...")

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
        File: An empty text file.
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
