"""Defines some functions to characterize MatchCondition.
"""

visibility("//lang/...")

# Default value of MatchCondition passed to each message assertion. Indicates no-op.
DEFAULT_MATCH_CONDITION = struct(
    matcher = None,
    pattern = None,
)

def MatchCondition(*, pattern, matcher):
    """MatchCondition constructor.

    Args:
        pattern(str): Pattern string. Supposed to be provided by users.
        matcher(label): Label to the matcher executable.

    Return:
        struct describing the match condition
    """
    if not pattern:
        fail(
            "Empty pattern string is not allowed for the MatchCondition",
        )

    return struct(
        pattern = pattern,
        matcher = matcher,
    )
