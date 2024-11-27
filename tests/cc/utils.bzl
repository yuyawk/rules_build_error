"""Testing utilities for C/C++ rules.
"""

load("//lang/cc:defs.bzl", "cc_build_error", "cc_build_error_test")

visibility("//tests/cc/...")

def check_build_and_test(name, **kwargs):
    """Utility to define both `check_build_and_test` and `cc_build_error_test` targets.

    Args:
        name(str): Name of the build target.
        **kwargs(dict): Other arguments.
    """
    cc_build_error(
        name = name,
        **kwargs
    )

    cc_build_error_test(
        name = name + ".test",
        **kwargs
    )
