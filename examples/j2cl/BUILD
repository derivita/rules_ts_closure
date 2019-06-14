load("@com_derivita_rules_ts_closure//:closure.bzl", "closure_ts_library")
load("@com_derivita_rules_ts_closure//:j2cl.bzl", "j2ts_library")
load(
    "@io_bazel_rules_closure//closure:defs.bzl",
    "closure_js_binary",
)

j2ts_library(
  name="example-j2cl",
  srcs=["Example.java"],
)

closure_ts_library(
    name = "helloworld-lib",
    srcs = ["hello.ts"],
    deps = [":example-j2cl"],
)

closure_js_binary(
    name = "j2cl",
    entry_points = ["com_derivita_rules_ts_closure.examples.j2cl.hello"],
    deps = [":helloworld-lib"],
)
