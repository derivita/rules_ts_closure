# Rule for generating .d.ts files.
def _gen_dts_impl(ctx):
    srcs = ctx.files.srcs
    output = ctx.outputs.output
    args = [
        "--partialInput",
        "-o",
        output.path,
        "--skipEmitRegExp",
        ctx.file._clutz_mock_goog_base.path,
        ctx.file._clutz_mock_goog_base.path,
        ctx.file._clutz_externs.path,
    ] + [f.path for f in srcs]
    ctx.action(
        inputs = srcs + [ctx.file._clutz_mock_goog_base, ctx.file._clutz_externs],
        outputs = [output],
        executable = ctx.executable._clutz,
        arguments = args,
        mnemonic = "Clutz",
        progress_message = "Running Clutz on %d JS files %s" % (len(srcs), ctx.label),
    )
    dts_files = [output]
    return struct(clutz_dts = dts_files)

clutz_gen_dts = rule(
    attrs = {
        "srcs": attr.label_list(allow_files = [".js"]),
        "output": attr.output(),
        # internal only
        "_clutz": attr.label(
            default = Label("@io_angular_clutz//:clutz"),
            executable = True,
            cfg = "host",
        ),
        "_clutz_mock_goog_base": attr.label(
            default = Label("@io_angular_clutz//:src/resources/partial_goog_base.js"),
            allow_single_file = True,
        ),
        "_clutz_externs": attr.label(
            default = Label("//internal:incremental_clutz_externs.js"),
            allow_single_file = True,
        ),
    },
    implementation = _gen_dts_impl,
)

def clutz_jszip_gen_dts(name, srcs, output):
    clutz_srcs = [
        "@io_angular_clutz//:src/resources/partial_goog_base.js",
        "//internal:incremental_clutz_externs.js",
    ]
    native.genrule(
        name = name,
        srcs = clutz_srcs + srcs,
        outs = [output],
        tools = ["@io_angular_clutz//:clutz"],
        cmd = """mkdir $(@D)/inputs
            for n in $(SRCS); do
              if [ $${n: -4} == .zip ]; then
                unzip -q -d $(@D)/inputs $$n
              fi
            done
            find $(@D) -name \*.js | xargs \
                $(location @io_angular_clutz//:clutz) \
                    --partialInput -o "$(@)" \
                    --skipEmitRegExp "$(location @io_angular_clutz//:src/resources/partial_goog_base.js)" \
                    "$(location @io_angular_clutz//:src/resources/partial_goog_base.js)" \
                    "$(location //internal:incremental_clutz_externs.js)"
            rm -rf $(@D)/inputs 
        """,
    )

