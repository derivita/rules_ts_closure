#   Build tool for making TypeScript .d.ts files from Closure JavaScript.

package(default_visibility = ["//visibility:public"])

licenses(["notice"])  # MIT

exports_files([
    "LICENSE",
    "src/resources/closure.lib.d.ts",
    "src/resources/partial_goog_base.js",
])

JVM_FLAGS = [
    "-Xss20m",  # JSCompiler needs big stacks for recursive parsing
    "-XX:+UseParallelGC",  # Best GC when app isn't latency sensitive
]

java_binary(
    name = "clutz",
    srcs = glob(["src/main/java/com/google/javascript/clutz/**/*.java"]),
    jvm_flags = JVM_FLAGS,
    main_class = "com.google.javascript.clutz.DeclarationGenerator",
    deps = [
        "@args4j",
        "@com_google_code_findbugs_jsr305",
        "@com_google_code_gson",
        "@com_google_guava",
        "@com_google_javascript_closure_compiler",
        "@org_apache_commons_text//jar",
        "@org_apache_commons_lang3//jar",
    ],
)

# Tool for converting closure javascript to TypeScript.
java_binary(
    name = "gents",
    srcs = glob(["src/main/java/com/google/javascript/gents/**/*.java"]),
    jvm_flags = JVM_FLAGS,
    main_class = "com.google.javascript.gents.TypeScriptGenerator",
    deps = [
        "@args4j",
        "@com_google_code_findbugs_jsr305",
        "@com_google_code_gson",
        "@com_google_guava",
        "@com_google_javascript_closure_compiler",
    ],
)
