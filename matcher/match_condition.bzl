"""Defines some functions to characterize MatchCondition.
"""

visibility("//lang/...")

# Default value of match condition passed to each message assertion. Indicates no-op.
DEFAULT_MATCH_CONDITION = struct(
    matcher = None,
    pattern = None,
)

def _validate_pattern_string(pattern):
    """Validate pattern string.

    Args:
        pattern(str): Pattern string
    """
    if not pattern:
        fail(
            "Empty pattern string is not allowed for the matcher",
        )

def MatchCondition(pattern, matcher):
    """MatchCondition constructor.

    Args:
        pattern(str): Pattern string
        matcher(label): Label to the matcher executable.

    Return:
        struct describing the match condition
    """
    _validate_pattern_string(pattern)
    return struct(
        pattern = pattern,
        matcher = matcher,
    )
