"""Define `inline_src`.
"""

load(
    "//inline_src:inline_src.bzl",
    "inline_src_c",
    "inline_src_cpp",
)

visibility("private")

inline_src = struct(
    c = inline_src_c,
    cpp = inline_src_cpp,
)
