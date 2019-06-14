load("@com_derivita_rules_ts_closure//:closure.bzl", "closure_ts_declaration")

# Type declarations for (most of) the Closure Library
# This only provides the types, you still need to add
# the closure_js_libraries you use to your deps.
closure_ts_declaration(
  name="closure-library",
  srcs=["index.d.ts"],
  generate_externs=False,
  visibility=["//visibility:public"]
)