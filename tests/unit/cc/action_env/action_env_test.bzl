"""Analysis test for the environment of the C/C++ build trial actions.
"""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

visibility("private")

_TRIAL_OUTPUTS = ["compile_output", "link_output"]

def _action_env_test_impl(ctx):
    env = analysistest.begin(ctx)

    trial_actions = [
        action
        for action in analysistest.target_actions(env)
        if [
            output
            for output in action.outputs.to_list()
            if output.basename in _TRIAL_OUTPUTS
        ]
    ]
    asserts.equals(env, len(_TRIAL_OUTPUTS), len(trial_actions))

    for action in trial_actions:
        asserts.equals(
            env,
            ctx.attr.expected_pwd or None,
            action.env.get("PWD"),
            "Unexpected PWD for the action creating {}".format(
                action.outputs.to_list()[0].basename,
            ),
        )

    return analysistest.end(env)

action_env_test = analysistest.make(
    _action_env_test_impl,
    attrs = {
        "expected_pwd": attr.string(
            doc = "Expected value of PWD for the trial actions. Empty if it must not be set.",
        ),
    },
)
