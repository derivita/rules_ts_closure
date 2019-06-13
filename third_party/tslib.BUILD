licenses(["notice"]) # apache
load(
    "@io_bazel_rules_closure//closure:defs.bzl",
    "closure_js_library",
)
load("@com_derivita_rules_ts_closure//:closure.bzl", "closure_ts_declaration", "clutz_gen_dts")

# TODO: figure out how to get rid of this module name hack.
genrule(
    name="copy_js",
    srcs=["third_party/tslib/tslib.js"],
    outs=["tslib.js"],
    cmd="cat $<|sed -e \"s/'tslib'/'rules_ts_closure.external.tsickle_tslib.tslib'/\" >$@"
)
closure_js_library(
    name="tslib-closure",
    srcs=["tslib.js"],
    no_closure_library=True,
    lenient=True,
)
# closure_ts_library won't allow sources from another package
genrule(
    name="copy_dts",
    srcs=["@npm//node_modules/tslib:tslib.d.ts"],
    outs=["tslib.d.ts"],
    cmd="cp $< $@",
)
closure_ts_declaration(
    name="tslib",
    srcs=["tslib.d.ts"],
    deps=["tslib-closure"],
    generate_externs = False,
    module_name="tslib",
    module_root="tslib.d.ts",
    visibility=["//visibility:public"],
)
