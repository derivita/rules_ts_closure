workspace(name = "com_derivita_rules_ts_closure")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_jar")

http_archive(
    name = "build_bazel_rules_nodejs",
    sha256 = "4c702ffeeab2d24dd4101601b6d27cf582d2e0d4cdc3abefddd4834664669b6b",
    urls = ["https://github.com/bazelbuild/rules_nodejs/releases/download/0.28.0/rules_nodejs-0.28.0.tar.gz"],
)

load("@build_bazel_rules_nodejs//:defs.bzl", "yarn_install", "npm_install")

yarn_install(
    name = "npm",
    package_json = "//:package.json",
    yarn_lock = "//:yarn.lock",
)

load("@npm//:install_bazel_dependencies.bzl", "install_bazel_dependencies")

install_bazel_dependencies()

load("@build_bazel_rules_nodejs//:package.bzl", "rules_nodejs_dependencies")
load("@npm_bazel_typescript//:index.bzl", "ts_setup_workspace")

ts_setup_workspace()

load("@com_derivita_rules_ts_closure//:deps.bzl", "install_rules_ts_closure_dependencies")
install_rules_ts_closure_dependencies()
load("@com_derivita_rules_ts_closure//:closure.bzl", "setup_rules_ts_closure_workspace")
setup_rules_ts_closure_workspace()