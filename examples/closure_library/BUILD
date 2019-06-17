package(default_visibility = ["//visibility:public"])

load(
    "@com_derivita_rules_ts_closure//:closure.bzl",
    "closure_ts_library",
)
load(
    "@io_bazel_rules_closure//closure:defs.bzl",
    "closure_js_binary",
)

closure_ts_library(
    name = "main",
    srcs = ["main.ts"],
    deps = [
        # Typescript types for the Closure Library
        "@com_derivita_rules_ts_closure//types:closure-library",
        # And the actual closure_js_libraries we depened on.
        "@io_bazel_rules_closure//closure/library/string",
    ],
)

closure_js_binary(
    name = "closure_library",
    entry_points = ["com_derivita_rules_ts_closure.examples.closure_library.main"],
    deps = [":main"],
)
