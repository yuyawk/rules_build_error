"""Public bzl file for re-exporting `//lang/cc` implementations.
"""

load(
    ":build_error.bzl",
    _CcBuildErrorInfo = "CcBuildErrorInfo",
    _cc_build_error = "cc_build_error",
)

visibility("public")

cc_build_error = _cc_build_error
CcBuildErrorInfo = _CcBuildErrorInfo
