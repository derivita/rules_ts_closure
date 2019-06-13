load("//internal:closure.bzl", "closure_ts_declaration")
load("//internal:clutz.bzl", "clutz_jszip_gen_dts")
load("@com_google_j2cl//build_defs:rules.bzl", "j2cl_library")

def j2ts_library(name, visibility = None, **kwargs):
    jszip = "%s-j2cl" % name
    dtsfile = "%s.d.ts" % name
    j2cl_library(
        name = jszip,
        visibility = visibility,
        **kwargs
    )
    clutz_jszip_gen_dts(
        name = "%s_gen_dts" % name,
        srcs = ["%s.js.zip" % jszip],
        output = dtsfile,
    )
    closure_ts_declaration(
        name = name,
        srcs = [dtsfile],
        generate_externs = False,
        deps = [jszip],
        visibility = visibility,
    )