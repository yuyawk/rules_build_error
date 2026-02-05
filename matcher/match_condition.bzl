"""Defines some functions to characterize MatchCondition.
"""

visibility("//lang/...")

# Tag to identify a MatchCondition object.
_TAG_SUFFIX = "\1RBEMATCHCONDITION\1"

# Contains information to identify each matcher.
_MATCHERS_INFORMATION = [
    struct(
        tag = "0",
        label = Label("//matcher/executable:contains_basic_regex"),
        attr_name = "_matcher_contains_basic_regex",
    ),
    struct(
        tag = "1",
        label = Label("//matcher/executable:contains_extended_regex"),
        attr_name = "_matcher_contains_extended_regex",
    ),
    struct(
        tag = "2",
        label = Label("//matcher/executable:has_substr"),
        attr_name = "_matcher_has_substr",
    ),
]

def MatchCondition(*, pattern, matcher):
    """MatchCondition constructor.

    Args:
        pattern(str): Pattern string. Supposed to be provided by users.
        matcher(label): Label to the matcher executable.

    Return:
        An object describing the match condition
    """

    def _matcher_to_tag(matcher_label):
        """Retrieve the tag string for the given matcher label.

        Args:
            matcher_label(label): Label to the matcher executable.

        Return:
            str: Tag string for the matcher.
        """
        for matcher_info in _MATCHERS_INFORMATION:
            if matcher_label == matcher_info.label:
                return matcher_info.tag
        fail("Unknown matcher label: '{}'".format(matcher_label))

    if not pattern:
        fail(
            "Empty pattern string is not allowed for the MatchCondition",
        )

    # Internally MatchCondition is represented as a string, so that it can support `select()` in BUILD files.
    return _matcher_to_tag(matcher) + pattern + _TAG_SUFFIX

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
    matcher_info.attr_name: attr.label(
        default = matcher_info.label,
        allow_single_file = True,
    )
    for matcher_info in _MATCHERS_INFORMATION
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
        for matcher_info in _MATCHERS_INFORMATION:
            if remaining.startswith(matcher_info.tag):
                index_right = remaining.find(_TAG_SUFFIX)
                if index_right == -1:
                    fail("Invalid MatchCondition object: '{}'".format(match_condition))
                pattern = remaining[len(matcher_info.tag):index_right]
                matcher_label = getattr(ctx.attr, matcher_info.attr_name)
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
