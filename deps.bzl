load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_jar")

def setup_j2cl(name):
    http_archive(
        name = "com_google_j2cl",
        sha256 = "604529134bd8ffd41fa5390b3758a1a4ad2b2d45b4a5e83d1cbe02ba53deb5a4",
        strip_prefix = "j2cl-f54e5b15b7c6d5fac4913847e7e33e5577169b1c",
        url = "https://github.com/ribrdb/j2cl/archive/f54e5b15b7c6d5fac4913847e7e33e5577169b1c.zip",
    )

def patch_tsickle_tslib(name):
    # print('workspace: '+native.repository_name())
    http_archive(
        name = "tsickle_tslib",
        build_file = "//third_party:tslib.BUILD",
        sha256 = "698191ec932e895943740bcfe2b450842c26d8847cb530f28a77e4cc611253b2",
        strip_prefix = "tsickle-0fae5b5dcc617787ec0c37b8309312dcbadec5c2",
        urls = [
            "https://github.com/angular/tsickle/archive/0fae5b5dcc617787ec0c37b8309312dcbadec5c2.zip",
        ],
    )

def install_rules_ts_closure_dependencies():
    _maybe(
        http_archive,
        name = "io_bazel_rules_closure",
        sha256 = "4d0f795b2701d65aa8fcb15dec81b45b123f17f85b310fa4edc12757496224ed",
        strip_prefix = "rules_closure-cd6ffe5574decc44c7b4cbaf9794d5b2843d18e0",
        url = "http://github.com/ribrdb/rules_closure/archive/cd6ffe5574decc44c7b4cbaf9794d5b2843d18e0.tar.gz",
    )
    _maybe(setup_j2cl, name = "com_google_j2cl")
    _maybe(
        http_archive,
        name = "io_angular_clutz",
        build_file = "//third_party:clutz.BUILD",
        sha256 = "3b601a585d49357fcb31ad304c9fcb5d7a7156f7f345beaf901cf487a2e6249b",
        strip_prefix = "clutz-733783dc299805a963272d4d77bf11b12668fad4",
        urls = [
            "https://github.com/angular/clutz/archive/733783dc299805a963272d4d77bf11b12668fad4.tar.gz",
        ],
    )
    _maybe(patch_tsickle_tslib, name = "tsickle_tslib")

    # I think this is a j2cl dependency. Not sure why we need to include it here.
    _maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "4afeeb81a39231351588cc2b8eb36fb5fa13feb82edece81d8d05e8fa791c0d1",
        strip_prefix = "bazel-skylib-197d8694821fa2bbafe6ac7f3b1266b882c2829c",
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/archive/197d8694821fa2bbafe6ac7f3b1266b882c2829c.tar.gz",
        ],
    )

def _maybe(repo_rule, name, **kwargs):
    if name not in native.existing_rules():
        repo_rule(name = name, **kwargs)
