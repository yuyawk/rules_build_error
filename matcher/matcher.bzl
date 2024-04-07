"""Defines `matcher`.

Each matcher function must receive a positional string argument,
and return a struct with the following members:
    pattern(str): Argument of the matcher function
    matcher(label): Label to the matcher executable.
                    Matcher executable is an executables which receives two arguments
                        $1: Pattern string
                        $2: Text file path to investigate
                    and exits with an error if the pattern doesn't match the content of the test file.
"""

visibility("private")

def _validate_pattern_string(pattern):
    """Validate pattern string.

    Args:
        pattern(str): Pattern string
    """
    if not pattern:
        fail(
            "Empty pattern string is not allowed for the matcher",
        )

def _contains_basic_regex(pattern):
    """Matcher to check if the target contains a basic regular expression.

    Args:
        pattern(str): Pattern for substring.

    Return:
        struct describing the matcher
    """
    _validate_pattern_string(pattern)
    return struct(
        pattern = pattern,
        matcher = Label("//matcher/executable:contains_basic_regex"),
    )

def _contains_extended_regex(pattern):
    """Matcher to check if the target contains a extended regular expression.

    Args:
        pattern(str): Pattern for substring.

    Return:
        struct describing the matcher
    """
    _validate_pattern_string(pattern)
    return struct(
        pattern = pattern,
        matcher = Label("//matcher/executable:contains_extended_regex"),
    )

def _has_substr(pattern):
    """Matcher to check if the target has a substring.

    Args:
        pattern(str): Pattern for substring.

    Return:
        struct describing the matcher
    """
    _validate_pattern_string(pattern)
    return struct(
        pattern = pattern,
        matcher = Label("//matcher/executable:has_substr"),
    )

matcher = struct(
    contains_basic_regex = _contains_basic_regex,
    contains_extended_regex = _contains_extended_regex,
    has_substr = _has_substr,
)
