"""Defines some functions to characterize MatchCondition.
"""

visibility("//lang/...")

# Tag to identify a MatchCondition object.
_TAG_SUFFIX = "\1RBEMATCHCONDITION\1"

# A tag for `contains_basic_regex` matcher.
_TAG_CONTAINS_BASIC_REGEX = "0"

# A tag for `contains_extended_regex` matcher.
_TAG_CONTAINS_EXTENDED_REGEX = "1"

# A tag for `has_substr` matcher.
_TAG_HAS_SUBSTR = "2"

# Mapping between matcher labels and their string representations.
# Every string representation is a single character.
_MATCHER_TO_TAG = {
    Label("//matcher/executable:contains_basic_regex"): _TAG_CONTAINS_BASIC_REGEX,
    Label("//matcher/executable:contains_extended_regex"): _TAG_CONTAINS_EXTENDED_REGEX,
    Label("//matcher/executable:has_substr"): _TAG_HAS_SUBSTR,
}

def MatchCondition(*, pattern, matcher):
    """MatchCondition constructor.

    Args:
        pattern(str): Pattern string. Supposed to be provided by users.
        matcher(label): Label to the matcher executable.

    Return:
        An object describing the match condition
    """
    if not pattern:
        fail(
            "Empty pattern string is not allowed for the MatchCondition",
        )

    # Internally MatchCondition is represented as a string, so that it can support `select()` in BUILD files.
    return _MATCHER_TO_TAG[matcher] + pattern + _TAG_SUFFIX

def _attr_match_condition(doc):
    """Rule attribute definition for MatchCondition object.

    Args:
        doc (str): Documentation string for the attribute.

    Returns:
        A rule attribute definition for MatchCondition object.
    """
    return attr.string(
        doc = doc,
        default = "",
        mandatory = False,
    )

# Rule attributes required whenever using a MatchCondition attribute.
_MATCH_CONDITION_REQUIRED_ATTRS = {
    "_matcher_contains_basic_regex": attr.label(
        default = Label("//matcher/executable:contains_basic_regex"),
        allow_single_file = True,
    ),
    "_matcher_contains_extended_regex": attr.label(
        default = Label("//matcher/executable:contains_extended_regex"),
        allow_single_file = True,
    ),
    "_matcher_has_substr": attr.label(
        default = Label("//matcher/executable:has_substr"),
        allow_single_file = True,
    ),
}

def _match_condition_to_structs(ctx, match_condition):
    """Converts a MatchCondition object to a list of structs with pattern and matcher fields.

    This function is intended for internal use inside the rule implementation function.

    Args:
        ctx (ctx): The rule context.
        match_condition (MatchCondition): A MatchCondition object.

    Returns:
        A list of structs with 'pattern' and 'matcher' fields. The type of each field is:
            pattern (str): The pattern string.
            matcher (File): The file object to the matcher executable.
    """

    remaining = match_condition

    list_structs = []

    for _ in range(1000000000):  # pseudo-infinite loop
        if not remaining:
            break

        pattern = None
        matcher = None
        for matcher_tag, matcher_label in {
            _TAG_CONTAINS_BASIC_REGEX: ctx.attr._matcher_contains_basic_regex,
            _TAG_CONTAINS_EXTENDED_REGEX: ctx.attr._matcher_contains_extended_regex,
            _TAG_HAS_SUBSTR: ctx.attr._matcher_has_substr,
        }.items():
            if remaining.startswith(matcher_tag):
                index_right = remaining.find(_TAG_SUFFIX)
                if index_right == -1:
                    fail("Invalid MatchCondition object: '{}'".format(match_condition))
                pattern = remaining[len(matcher_tag):index_right]
                matcher = matcher_label.files_to_run.executable
                remaining = remaining[index_right + len(_TAG_SUFFIX):]
                break

        if not matcher:
            fail("Invalid MatchCondition object: '{}'".format(match_condition))

        if not pattern:
            fail("The pattern string cannot be empty")

        list_structs.append(
            struct(
                pattern = pattern,
                matcher = matcher,
            ),
        )

    return list_structs

# Utility struct to access MatchCondition related functions from '//lang/...'.
match_condition_util = struct(
    attr = _attr_match_condition,
    to_structs = _match_condition_to_structs,
    required_attrs = _MATCH_CONDITION_REQUIRED_ATTRS,
)
