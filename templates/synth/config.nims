import std/[os, strutils]

# Explicit template metadata. This file owns the task names; the shared
# openxy script holds the reusable implementation.
const
  machineId = "mysynth"
  machineSource = "src/mysynth.nim"
  buildRoot = "build"
  stockOs = ""
  layout = ""

let templateRoot = currentSourcePath().parentDir
let localSrc = templateRoot / ".." / ".." / "src"
let depsSrc = templateRoot / "deps" / "openxy" / "src"
let openxySrc = if dirExists(localSrc): localSrc
                 elif dirExists(depsSrc): depsSrc
                 else: ""
if openxySrc.len == 0:
  raise newException(OSError,
    "openxy is not installed; run `atlas init` and `atlas install`, then retry")
let openxyScript = openxySrc.parentDir / "scripts" / "template_tasks.nims"

proc delegate(taskName: string) =
  exec "nim e --hints:off --path:" & quoteShell(openxySrc) & " " &
    quoteShell(openxyScript) & " " & taskName & " " & quoteShell(templateRoot) & " " &
    quoteShell(machineId) & " " & quoteShell(machineSource) & " " &
    quoteShell(buildRoot) & " " & quoteShell(stockOs) & " " & quoteShell(layout)

task test, "Run the machine host tests":
  delegate "test"

task gen, "Validate, measure, and generate the SDK machine folder":
  delegate "gen"

task preview, "Build the browser preview with the OP-XY SDK":
  delegate "preview"

task compile, "Compile the Blackfin development module":
  delegate "compile"

task build, "Build a firmware package (needs stockOs)":
  delegate "build"

task clean, "Remove generated output":
  delegate "clean"
