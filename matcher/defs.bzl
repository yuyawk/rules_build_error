"""Public bzl file for re-exporting `//matcher` implementations.
"""

load(":matcher.bzl", _matcher = "matcher")

visibility("public")

matcher = _matcher
