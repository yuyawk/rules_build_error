"""Define the inline source object and its functions.
"""

visibility("//lang/...")

_INLINE_SRC_TYPE = "INLINE_SRC"

def is_inline_src(obj):
    """Test if an object is an inline source object or not.

    Args:
        An object to test.

    Returns:
        True it's an inline source object, false otherwise.
    """
    return type(obj) == "struct" and getattr(obj, "type", None) == _INLINE_SRC_TYPE

def inline_src_c(content):
    """Construct an inline source object for C.

    Args:
        content(str): Content of the source file.

    Returns:
        An inline source object for C.
    """

    return struct(
        type = _INLINE_SRC_TYPE,
        content = content,
        extension = "c",
    )

def inline_src_cpp(content):
    """Construct an inline source object for C++.

    Args:
        content(str): Content of the source file.

    Returns:
        An inline source object for C++.
    """

    return struct(
        type = _INLINE_SRC_TYPE,
        content = content,
        extension = "cpp",
    )

def _generate_inline_src_rule_impl(ctx):
    """Implementation of `_generate_inline_src_rule`.

    Args:
        ctx: Rule context.

    Returns:
        Provider for the rule.
    """
    output = ctx.actions.declare_file(ctx.label.name + "." + ctx.attr.extension)
    ctx.actions.write(
        output = output,
        content = ctx.attr.content,
    )
    return [DefaultInfo(files = depset([output]))]

_generate_inline_src_rule = rule(
    implementation = _generate_inline_src_rule_impl,
    attrs = {
        "content": attr.string(
            doc = (
                "The content of the source file."
            ),
            mandatory = True,
        ),
        "extension": attr.string(
            doc = (
                "The extension of the source file."
            ),
            mandatory = True,
        ),
    },
    provides = [DefaultInfo],
)

def generate_inline_src(*, name, inline_src, **kwargs):
    """Rule to generate inline source.

    Args:
        name(str): The name of the target.
        inline_src(inline source object): The inline source object to generate.
        **kwargs(dict): Passed to internal rules.
    """
    if not is_inline_src(inline_src):
        fail("Precondition: `inline_src` must be an inline source object.")

    _generate_inline_src_rule(
        name = name,
        content = inline_src.content,
        extension = inline_src.extension,
        **kwargs
    )
