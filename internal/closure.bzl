load("@build_bazel_rules_nodejs//internal/common:node_module_info.bzl", "NodeModuleInfo", "NodeModuleSources", "collect_node_modules_aspect")

# load("@build_bazel_rules_typescript//internal:common/compilation.bzl", "COMMON_ATTRIBUTES", "DEPS_ASPECTS", "compile_ts", "ts_providers_dict_to_struct")
# load("@build_bazel_rules_typescript//internal:common/tsconfig.bzl", "create_tsconfig")
load("@npm_bazel_typescript//internal:ts_config.bzl", "TsConfigInfo")
load("@npm_bazel_typescript//internal:build_defs.bzl", "COMMON_ATTRIBUTES", "DEPS_ASPECTS", "compile_ts", "ts_providers_dict_to_struct", "tsc_wrapped_tsconfig")
load("@io_bazel_rules_closure//closure:defs.bzl", "CLOSURE_JS_TOOLCHAIN_ATTRS", "create_closure_js_library")

# TODO: share code with @npm_bazel_typescript//internal:build_defs.bzl.

_DEFAULT_COMPILER = "//internal:tsc_wrapped__bin"

def closure_tsconfig(
        ctx,
        files,
        srcs,
        *args,
        **kwargs):
    """Produce a tsconfig.json that sets options required under Bazel.
    Args:
      ctx: the Bazel starlark execution context
      files: Labels of all TypeScript compiler inputs
      srcs: Immediate sources being compiled, as opposed to transitive deps
      devmode_manifest: path to the manifest file to write for --target=es5
      jsx_factory: the setting for tsconfig.json compilerOptions.jsxFactory
      **kwargs: remaining args to pass to the create_tsconfig helper
    Returns:
      The generated tsconfig.json as an object
    """
    config = tsc_wrapped_tsconfig(ctx, files, srcs, *args, **kwargs)
    config["compilerOptions"]["target"] = "es2017"
    config["compilerOptions"]["noEmitHelpers"] = True
    config["compilerOptions"]["importHelpers"] = True

    # config["compilerOptions"]["paths"]["tslib"] = ["external/tsickle_tslib/tslib.d.ts"]
    config["bazelOptions"]["tsickle"] = True
    config["bazelOptions"]["googmodule"] = True
    if ctx.attr.ignore_warnings:
        config["bazelOptions"]["ignoreWarningPaths"] = [src.path for src in srcs]
    return config

def _outputs(ctx, label, srcs_files = []):
    """Returns closure js, devmode js, and .d.ts output files.
    Args:
      ctx: ctx.
      label: Label. package label.
      srcs_files: File list. sources files list.
    Returns:
      A struct of file lists for different output types.
    """
    workspace_segments = label.workspace_root.split("/") if label.workspace_root else []
    package_segments = label.package.split("/") if label.package else []
    trim = len(workspace_segments) + len(package_segments)
    create_shim_files = True

    closure_js_files = []
    devmode_js_files = []
    declaration_files = []
    for input_file in srcs_files:
        is_dts = input_file.short_path.endswith(".d.ts")
        if is_dts and not create_shim_files:
            continue
        basename = "/".join(input_file.short_path.split("/")[trim:])
        for ext in [".d.ts", ".tsx", ".ts"]:
            if basename.endswith(ext):
                basename = basename[:-len(ext)]
                break
        closure_js_files += [ctx.actions.declare_file(basename + ".closure.js")]

        # Temporary until all imports of ngfactory/ngsummary files are removed
        # TODO(alexeagle): clean up after Ivy launch
        if getattr(ctx, "compile_angular_templates", False):
            closure_js_files += [ctx.actions.declare_file(basename + ".ngfactory.closure.js")]
            closure_js_files += [ctx.actions.declare_file(basename + ".ngsummary.closure.js")]

        if not is_dts:
            devmode_js_files += [ctx.actions.declare_file(basename + ".js")]
            declaration_files += [ctx.actions.declare_file(basename + ".d.ts")]

            # Temporary until all imports of ngfactory/ngsummary files are removed
            # TODO(alexeagle): clean up after Ivy launch
            if getattr(ctx, "compile_angular_templates", False):
                devmode_js_files += [ctx.actions.declare_file(basename + ".ngfactory.js")]
                devmode_js_files += [ctx.actions.declare_file(basename + ".ngsummary.js")]
    return struct(
        closure_js = closure_js_files,
        devmode_js = devmode_js_files,
        declarations = declaration_files,
    )

def _filter_ts_inputs(all_inputs):
    return [
        f
        for f in all_inputs
        if f.path.endswith(".js") or f.path.endswith(".ts") or f.path.endswith(".json")
    ]

def _compile_action(ctx, inputs, outputs, tsconfig_file, node_opts, description = "prodmode"):
    externs_files = []
    action_inputs = []
    action_outputs = []
    for output in outputs:
        if output.basename.endswith(".externs.js") and not ctx.attr.generate_externs:
            externs_files.append(output)
        elif output.basename.endswith(".es5.MF"):
            ctx.actions.write(output, content = "")
        else:
            action_outputs.append(output)

    # TODO(plf): For now we mock creation of files other than {name}.js.
    for externs_file in externs_files:
        ctx.actions.write(output = externs_file, content = "")

    # A ts_library that has only .d.ts inputs will have no outputs,
    # therefore there are no actions to execute
    if not action_outputs:
        return None

    action_inputs.extend(_filter_ts_inputs(ctx.files.node_modules))

    # Also include files from npm fine grained deps as action_inputs.
    # These deps are identified by the NodeModuleSources provider.
    for d in ctx.attr.deps:
        if NodeModuleSources in d:
            # Note: we can't avoid calling .to_list() on sources
            action_inputs.extend(_filter_ts_inputs(d[NodeModuleSources].sources.to_list()))

    if ctx.file.tsconfig:
        action_inputs.append(ctx.file.tsconfig)
        if TsConfigInfo in ctx.attr.tsconfig:
            action_inputs.extend(ctx.attr.tsconfig[TsConfigInfo].deps)

    # Pass actual options for the node binary in the special "--node_options" argument.
    arguments = ["--node_options=%s" % opt for opt in node_opts]

    # One at-sign makes this a params-file, enabling the worker strategy.
    # Two at-signs escapes the argument so it's passed through to tsc_wrapped
    # rather than the contents getting expanded.
    if ctx.attr.supports_workers:
        arguments.append("@@" + tsconfig_file.path)
        mnemonic = "TypeScriptCompile"
    else:
        arguments.append("-p")
        arguments.append(tsconfig_file.path)
        mnemonic = "tsc"

    ctx.actions.run(
        progress_message = "Compiling TypeScript (%s) %s" % (description, ctx.label),
        mnemonic = mnemonic,
        inputs = depset(action_inputs, transitive = [inputs]),
        outputs = action_outputs,
        # Use the built-in shell environment
        # Allow for users who set a custom shell that can locate standard binaries like tr and uname
        # See https://github.com/NixOS/nixpkgs/issues/43955#issuecomment-407546331
        use_default_shell_env = True,
        arguments = arguments,
        executable = ctx.executable.compiler,
        execution_requirements = {
            "supports-workers": str(int(ctx.attr.supports_workers)),
        },
    )

    # Enable the replay_params in case an aspect needs to re-build this library.
    return struct(
        label = ctx.label,
        tsconfig = tsconfig_file,
        inputs = depset(action_inputs, transitive = [inputs]),
        outputs = action_outputs,
        compiler = ctx.executable.compiler,
    )

def _devmode_compile_action(ctx, inputs, outputs, tsconfig_file, node_opts):
    _compile_action(
        ctx,
        inputs,
        outputs,
        tsconfig_file,
        node_opts,
        description = "devmode",
    )

_ts_library_attrs = dict(COMMON_ATTRIBUTES, **{
    "srcs": attr.label_list(
        doc = "The TypeScript source files to compile.",
        allow_files = [".ts", ".tsx"],
        mandatory = True,
    ),
    "ignore_warnings": attr.bool(),
    "compile_angular_templates": attr.bool(
        doc = """Run the Angular ngtsc compiler under ts_library""",
    ),
    "compiler": attr.label(
        doc = """Sets a different TypeScript compiler binary to use for this library.
            For example, we use the vanilla TypeScript tsc.js for bootstrapping,
            and Angular compilations can replace this with `ngc`.

            The default ts_library compiler depends on the `@npm//@bazel/typescript`
            target which is setup for projects that use bazel managed npm deps that
            fetch the @bazel/typescript npm package. It is recommended that you use
            the workspace name `@npm` for bazel managed deps so the default
            compiler works out of the box. Otherwise, you'll have to override
            the compiler attribute manually.
            """,
        default = Label(_DEFAULT_COMPILER),
        allow_files = True,
        executable = True,
        cfg = "host",
    ),
    "internal_testing_type_check_dependencies": attr.bool(default = False, doc = "Testing only, whether to type check inputs that aren't srcs."),
    "node_modules": attr.label(
        doc = """The npm packages which should be available during the compile.

            The default value is `@npm//typescript:typescript__typings` is setup
            for projects that use bazel managed npm deps that. It is recommended
            that you use the workspace name `@npm` for bazel managed deps so the
            default node_modules works out of the box. Otherwise, you'll have to
            override the node_modules attribute manually. This default is in place
            since ts_library will always depend on at least the typescript
            default libs which are provided by `@npm//typescript:typescript__typings`.

            This attribute is DEPRECATED. As of version 0.18.0 the recommended
            approach to npm dependencies is to use fine grained npm dependencies
            which are setup with the `yarn_install` or `npm_install` rules.

            For example, in targets that used a `//:node_modules` filegroup,

            ```
            ts_library(
                name = "my_lib",
                ...
                node_modules = "//:node_modules",
            )
            ```

            which specifies all files within the `//:node_modules` filegroup
            to be inputs to the `my_lib`. Using fine grained npm dependencies,
            `my_lib` is defined with only the npm dependencies that are
            needed:

            ```
            ts_library(
                name = "my_lib",
                ...
                deps = [
                    "@npm//@types/foo",
                    "@npm//@types/bar",
                    "@npm//foo",
                    "@npm//bar",
                    ...
                ],
            )
            ```

            In this case, only the listed npm packages and their
            transitive deps are includes as inputs to the `my_lib` target
            which reduces the time required to setup the runfiles for this
            target (see https://github.com/bazelbuild/bazel/issues/5153).
            The default typescript libs are also available via the node_modules
            default in this case.

            The @npm external repository and the fine grained npm package
            targets are setup using the `yarn_install` or `npm_install` rule
            in your WORKSPACE file:

            yarn_install(
                name = "npm",
                package_json = "//:package.json",
                yarn_lock = "//:yarn.lock",
            )
            """,
        default = Label("@npm//typescript:typescript__typings"),
    ),
    "supports_workers": attr.bool(
        doc = """Intended for internal use only.
            Allows you to disable the Bazel Worker strategy for this library.
            Typically used together with the "compiler" setting when using a
            non-worker aware compiler binary.""",
        default = True,
    ),

    # TODO(alexeagle): reconcile with google3: ts_library rules should
    # be portable across internal/external, so we need this attribute
    # internally as well.
    "tsconfig": attr.label(
        doc = """A tsconfig.json file containing settings for TypeScript compilation.
            Note that some properties in the tsconfig are governed by Bazel and will be
            overridden, such as `target` and `module`.

The default value is set to `//:tsconfig.json` by a macro. This means you must
either:

- Have your `tsconfig.json` file in the workspace root directory
- Use an alias in the root BUILD.bazel file to point to the location of tsconfig:
    `alias(name="tsconfig.json", actual="//path/to:tsconfig-something.json")`
- Give an explicit `tsconfig` attribute to all `ts_library` targets
            """,
        allow_single_file = True,
    ),
    "tsickle_typed": attr.bool(
        default = True,
        doc = "If using tsickle, instruct it to translate types to ClosureJS format",
    ),
    "deps": attr.label_list(
        aspects = DEPS_ASPECTS + [collect_node_modules_aspect],
        doc = "Compile-time dependencies, typically other ts_library targets",
    ),
})

# --- end copied code

default_ts_suppress = [
    "checkTypes",
    "strictCheckTypes",
    "strictDependencies",  # TODO: is this necessary?
    "reportUnknownTypes",
    "analyzerChecks",
    "JSC_EXTRA_REQUIRE_WARNING",
    "unusedLocalVariables",
    "superfluousSuppress",
    "underscore",
]

_closure_ts_library_attrs = dict(dict(_ts_library_attrs, **CLOSURE_JS_TOOLCHAIN_ATTRS), **{
    "suppress": attr.string_list(doc = "List of Closure Compiler errors to suppress"),
    "exports": attr.label_list(providers = ["closure_js_library"], doc = "Listing dependencies here will cause them to become direct dependencies in parent rules. "),
})

def _is_ts_dep(d):
    # Filter out the node_modules from deps passed to TypeScript compiler
    # since they don't have the required providers.
    # They were added to the action inputs for tsc_wrapped already.
    # strict_deps checking currently skips node_modules.
    if NodeModuleInfo in d:
        return False

    # Also filter out closure_js_libraries, they will be passed to
    # create_closure_js_library below.
    if hasattr(d, "closure_js_library") and not hasattr(d, "typescript"):
        return False
    return True

def _closure_ts_library_impl(ctx):
    """Implementation of closure_ts_library.

    Args:
      ctx: the context.

    Returns:
      the struct returned by the call to compile_ts.
    """
    ts_providers = compile_ts(
        ctx,
        is_library = True,
        # TODO(alexeagle): turn on strict deps checking when we have a real
        # provider for JS/DTS inputs to ts_library.
        deps = [d for d in ctx.attr.deps if _is_ts_dep(d)],
        compile_action = _compile_action,
        devmode_compile_action = _devmode_compile_action,
        tsc_wrapped_tsconfig = closure_tsconfig,
        # outputs = _outputs,
    )
    js_sources = ts_providers["typescript"]["es6_sources"]
    js_deps = [d for d in ctx.attr.deps + ctx.attr._helpers if not NodeModuleInfo in d]
    suppress = ctx.attr.suppress + default_ts_suppress
    js_providers = create_closure_js_library(ctx, js_sources, js_deps, ctx.attr.exports, suppress)
    ts_providers["exports"] = js_providers.exports
    ts_providers["closure_js_library"] = js_providers.closure_js_library
    return ts_providers_dict_to_struct(ts_providers)

closure_ts_library = rule(
    _closure_ts_library_impl,
    attrs = dict(_closure_ts_library_attrs, **{
        "_helpers": attr.label_list(default = [Label("@tsickle_tslib//:tslib")], aspects = DEPS_ASPECTS + [collect_node_modules_aspect]),
    }),
    outputs = {
        "tsconfig": "%{name}_tsconfig.json",
    },
    doc = """`ts_library` type-checks and compiles a set of TypeScript sources to JavaScript.

    It produces declarations files (`.d.ts`) which are used for compiling downstream
    TypeScript targets and JavaScript for the browser and Closure compiler.
    """,
)

def _closure_ts_declaration_impl(ctx):
    """Implementation of closure_ts_declaration.

    Args:
      ctx: the context.

    Returns:
      the struct returned by the call to compile_ts.
    """

    ts_providers = compile_ts(
        ctx,
        is_library = False,
        # TODO(alexeagle): turn on strict deps checking when we have a real
        # provider for JS/DTS inputs to closure_ts_declaration.
        deps = [d for d in ctx.attr.deps if _is_ts_dep(d)],
        compile_action = _compile_action,
        devmode_compile_action = _devmode_compile_action,
        tsc_wrapped_tsconfig = closure_tsconfig,
        # outputs = _outputs,
    )
    js_sources = ts_providers["typescript"]["es6_sources"]
    js_deps = [d for d in ctx.attr.deps if not NodeModuleInfo in d]
    suppress = ctx.attr.suppress + default_ts_suppress
    js_providers = create_closure_js_library(ctx, srcs = js_sources, deps = js_deps, exports = js_deps, suppress = suppress)
    ts_providers["exports"] = js_providers.exports
    ts_providers["closure_js_library"] = js_providers.closure_js_library
    return ts_providers_dict_to_struct(ts_providers)

closure_ts_declaration = rule(
    _closure_ts_declaration_impl,
    attrs = _closure_ts_library_attrs,
    outputs = {
        "tsconfig": "%{name}_tsconfig.json",
    },
    doc = """`closure_ts_declaration` type-checks and compiles a set of TypeScript sources to JavaScript.

    It produces declarations files (`.d.ts`) which are used for compiling downstream
    TypeScript targets and JavaScript for the browser and Closure compiler.
    """,
)

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
        # ctx.file._clutz_externs.path,
    ] + [f.path for f in srcs]
    ctx.action(
        inputs = srcs + [
            ctx.file._clutz_mock_goog_base,
            #  ctx.file._clutz_externs,
        ],
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
        # "_clutz_externs": attr.label(
        #     default = Label("@io_bazel_rules_closure//third_party/clutz:externs.js"),
        #     allow_single_file = True,
        # ),
    },
    implementation = _gen_dts_impl,
)
