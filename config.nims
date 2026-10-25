import std/[os, strutils]

let root = currentSourcePath().parentDir
let src = root / "src"

proc hasFlag(flag: string): bool =
  for argument in commandLineParams():
    if argument == flag:
      return true

proc runScript(name: string; extra = "") =
  let command = "nim e --hints:off --path:" & quoteShell(src) & " " &
    quoteShell(root / "scripts" / name) & extra
  exec command

task test, "Run the openxy unit and compile-failure tests":
  runScript "test.nims"

task doctor, "Check the SDK, Python, Clang/WebAssembly, and Blackfin tools":
  runScript "doctor.nims"

task regen, "Regenerate raw C++ bindings (requires the regen feature)":
  runScript "regen.nims"

task checkTemplates, "Copy and exercise every machine template (pass -- --full for preview/device checks)":
  runScript "check_templates.nims",
    (if hasFlag("--full"): " -- --full" else: "")
