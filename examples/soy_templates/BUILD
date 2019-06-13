package(default_visibility = ["//visibility:public"])

 load(
    "@com_derivita_rules_ts_closure//:closure.bzl",
    "closure_ts_template_library",
)
 load(
    "@io_bazel_rules_closure//closure:defs.bzl",
    "closure_js_binary",
    "closure_js_library",
)
load("@build_bazel_rules_nodejs//:defs.bzl", "nodejs_binary")

 closure_ts_template_library(
    name = "template",
    srcs = ["some.soy"],
)

 ts_library(
    name = "main",
    srcs = ["main.ts"],
    deps = [
        ":mini_closure",
        ":template_ts",
    ],
)

 closure_js_library(
    name = "main_js",
    ts_lib = ":main",
    suppress=["unusedLocalVariables"],
)

 closure_js_binary(
    name = "render_soy_bin",
    entry_points = ["goog:build_bazel_rules_typescript.examples.some_soy.main"],
    deps = [":main_js"],
)

 nodejs_binary(
    name = "some_soy",
    data = [
        ":render_soy_bin",
    ],
    entry_point = "build_bazel_rules_typescript/examples/some_soy/render_soy_bin.js",
)

 sh_test(
    name = "soy_render_test",
    srcs = ["soy_render_test.sh"],
    data = [":some_soy"],
)

 ts_library(
    name="mini_closure",
    srcs=[":closure.d.ts"],
    runtime_deps = [
        "@io_bazel_rules_closure//closure/library",
    ],
    generate_externs = False,
)