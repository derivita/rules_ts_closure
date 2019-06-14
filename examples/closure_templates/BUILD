package(default_visibility = ["//visibility:public"])

load(
    "@com_derivita_rules_ts_closure//:closure.bzl",
    "closure_ts_template_library",
    "closure_ts_library",
)
load(
    "@io_bazel_rules_closure//closure:defs.bzl",
    "closure_js_binary",
)

closure_ts_template_library(
    name = "template",
    srcs = ["template.soy"],
)

closure_ts_library(
    name = "main",
    srcs = ["main.ts"],
    deps = [
        ":template",
    ],
)

closure_js_binary(
    name = "closure_templates",
    entry_points = ["com_derivita_rules_ts_closure.examples.closure_templates.main"],
    deps = [":main"],
)
