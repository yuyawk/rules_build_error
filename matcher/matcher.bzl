"""Defines `matcher`.

Each matcher function must receive a positional string argument,
and return an object `MatchCondition` with constructed from the  following members:
    pattern(str): Argument of the matcher function
    matcher(label): Label to the matcher executable.
                    Matcher executable is an executable which receives two arguments
                        $1: Text file containing a pattern string
                        $2: Text file where the matcher searches for a pattern string
                    and exits with an error if the pattern doesn't match the content of the test file.

As a side note, the reason the matcher executable doesn't directly receive a pattern string is to support Windows.
Shell in Windows lacks of the ability to sufficiently quote command line arguments. (https://github.com/bazelbuild/bazel/issues/17487)
"""

load(":match_condition.bzl", "MatchCondition")

visibility("private")

def _contains_basic_regex(pattern):
    """Get a MatchCondition to check if the target contains a basic regular expression.

    Args:
        pattern(str): Pattern string. Supposed to be provided by users.

    Return:
        MatchCondition for the check.
    """
    return MatchCondition(
        pattern = pattern,
        matcher = Label("//matcher/executable:contains_basic_regex"),
    )

def _contains_extended_regex(pattern):
    """Get a MatchCondition to check if the target contains a extended regular expression.

    Args:
        pattern(str): Pattern string. Supposed to be provided by users.

    Return:
        MatchCondition for the check.
    """
    return MatchCondition(
        pattern = pattern,
        matcher = Label("//matcher/executable:contains_extended_regex"),
    )

def _has_substr(pattern):
    """Get a MatchCondition to check if the target has a substring.

    Args:
        pattern(str): Pattern string. Supposed to be provided by users.

    Return:
        MatchCondition for the check.
    """
    return MatchCondition(
        pattern = pattern,
        matcher = Label("//matcher/executable:has_substr"),
    )

matcher = struct(
    contains_basic_regex = _contains_basic_regex,
    contains_extended_regex = _contains_extended_regex,
    has_substr = _has_substr,
)
