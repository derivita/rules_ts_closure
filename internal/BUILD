load("@build_bazel_rules_nodejs//:defs.bzl", "nodejs_binary")

nodejs_binary(
    name = "tsc_wrapped__bin",
    data = [
        "@npm//@bazel/typescript",
        "@npm//tsickle",
    ],
    entry_point = "@bazel/typescript/internal/tsc_wrapped/tsc_wrapped.js",
    install_source_map_support = False,
    visibility = ["//visibility:public"],
)

exports_files([
    "incremental_clutz_externs.js",
])
