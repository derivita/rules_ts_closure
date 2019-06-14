load(
    "@io_bazel_rules_closure//closure:defs.bzl",
    "closure_js_proto_library",
    "closure_js_template_library",
)
load("//internal:closure.bzl", _closure_ts_library="closure_ts_library", _closure_ts_declaration="closure_ts_declaration")
load("//internal:clutz.bzl", _clutz_gen_dts="clutz_gen_dts")
# TODO: make these optional
load("@com_google_j2cl//build_defs:repository.bzl", "load_j2cl_repo_deps")
load("@com_google_j2cl//build_defs:rules.bzl", "setup_j2cl_workspace")

clutz_gen_dts=_clutz_gen_dts

def closure_ts_library(tsconfig = None, **kwargs):
    """Wraps `closure_ts_library` to set the default for the `tsconfig` attribute.
    This must be a macro so that the string is converted to a label in the context of the
    workspace that declares the `ts_library` target, rather than the workspace that defines
    `closure_ts_library`, or the workspace where the build is taking place.
    Args:
      tsconfig: the label pointing to a tsconfig.json file
      **kwargs: remaining args to pass to the closure_ts_library rule
    """
    if not tsconfig:
        tsconfig = "//:tsconfig.json"

    _closure_ts_library(tsconfig = tsconfig, **kwargs)

def closure_ts_declaration(tsconfig = None, **kwargs):
    """Wraps `closure_ts_declaration` to set the default for the `tsconfig` attribute.
    This must be a macro so that the string is converted to a label in the context of the
    workspace that declares the `closure_ts_declaration` target, rather than the workspace that defines
    `closure_ts_declaration`, or the workspace where the build is taking place.
    Args:
      tsconfig: the label pointing to a tsconfig.json file
      **kwargs: remaining args to pass to the closure_ts_declaration rule
    """
    if not tsconfig:
        tsconfig = "//:tsconfig.json"

    _closure_ts_declaration(tsconfig = tsconfig, **kwargs)

def closure_ts_template_library(name, srcs, deps = [], visibility = None, **kwargs):
    jslib = "%s_jslib" % name
    jsdeps = ["%s_jslib" % n for n in deps]
    js_srcs = ["%s.js" % s for s in srcs]
    closure_js_template_library(
        name = jslib,
        srcs = srcs,
        deps = jsdeps,
        visibility = visibility,
        **kwargs
    )
    decl_label = "%s_gen_dts" % name
    dtsfile = "%s.d.ts" % name
    clutz_gen_dts(name = decl_label, srcs = js_srcs, output = dtsfile)
    closure_ts_declaration(
        name = name,
        srcs = [dtsfile],
        generate_externs = False,
        deps = deps + ["@com_derivita_rules_ts_closure//types:closure-library", jslib],
        visibility = visibility,
    )

def closure_ts_proto_library(name, visibility = None, **kwargs):
    jslib = "%s_proto" % name
    closure_js_proto_library(
        name = jslib,
        visibility = visibility,
        **kwargs
    )
    decl_label = "%s_gen_dts" % name
    jsfile = "%s.js" % jslib
    dtsfile = "%s.d.ts" % name
    clutz_gen_dts(name = decl_label, srcs = [jsfile], output = dtsfile)
    closure_ts_declaration(
        name = name,
        srcs = [dtsfile],
        generate_externs = False,
        deps = ["@com_derivita_rules_ts_closure//types:closure-library", jslib],
        visibility = visibility,
    )

def setup_rules_ts_closure_workspace():
    load_j2cl_repo_deps()
    setup_j2cl_workspace()
