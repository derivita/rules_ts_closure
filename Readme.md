## WORKSPACE Set Up:
Set up rules_nodejs and typescript:
https://github.com/bazelbuild/rules_nodejs
https://www.npmjs.com/package/@bazel/typescript

Make sure you include tsickle and @types/node in your package.json.

Add rules_ts_closure to your WORKSPACE file:

```py
http_archive(
  name="com_derivita_rules_ts_closure",
  ...
)
load("@com_derivita_rules_ts_closure//:deps.bzl", "install_rules_ts_closure_dependencies")
install_rules_ts_closure_dependencies()
load("@com_derivita_rules_ts_closure//:closure.bzl", "setup_rules_ts_closure_workspace")
setup_rules_ts_closure_workspace()
```
ca
## Design Overview
https://docs.google.com/document/d/1Sq9c8NybsOzUy0EfoSc71469g-HWxRMAJx-ucfBqAGM/edit?usp=sharing

## Bazel hints
If you're using gcc on Linux it may help to set the CC environment variable:
export CC=gcc

If you're not using remote caching you might want to use the --disk_cache flag for bazel