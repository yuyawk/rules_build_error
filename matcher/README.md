# Matcher

Defines a struct `matcher`, which can be loaded from `//matcher:defs.bzl`.

`matcher` has some member functions each of which receives a pattern string as a positional string argument, and which returns its specific matcher. Each specific matcher can be used to specify the way of validating the build error message (stderr or stdout).

The member functions of `matcher` are as follows

| Member                  | Description                                                           |
| ----------------------- | --------------------------------------------------------------------- |
| contains_basic_regex    | Check if the message contains the basic regular expression pattern    |
| contains_extended_regex | Check if the message contains the extended regular expression pattern |
| has_substr              | Check if the message has the sub-string                               |
