load("@com_derivita_rules_ts_closure//:closure.bzl", "closure_ts_library")
load(
    "@io_bazel_rules_closure//closure:defs.bzl",
    "closure_js_binary",
)

closure_ts_library(
    name = "helloworld-lib",
    srcs = ["hello.ts"],
)

closure_js_binary(
    name = "helloworld",
    entry_points = ["com_derivita_rules_ts_closure.examples.helloworld.hello"],
    deps = [":helloworld-lib"],
)
