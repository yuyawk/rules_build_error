"""Public bzl file for re-exporting `//lang/cc` implementations.
"""

load(
    ":build_error.bzl",
    _CcBuildErrorInfo = "CcBuildErrorInfo",
    _cc_build_error = "cc_build_error",
    _cc_build_error_test = "cc_build_error_test",
)
load(
    ":inline_src.bzl",
    _inline_src = "inline_src",
)

visibility("public")

cc_build_error = _cc_build_error
cc_build_error_test = _cc_build_error_test
CcBuildErrorInfo = _CcBuildErrorInfo
inline_src = _inline_src
