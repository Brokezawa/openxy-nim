import std/[os, strutils]

# Explicit template metadata. This file owns the task names; the shared
# openxy script holds the reusable implementation.
const
  machineId = "mysample"
  machineSource = "src/mysample.nim"
  buildRoot = "build"
  stockOs = ""
  layout = ""

let templateRoot = currentSourcePath().parentDir
let localSrc = templateRoot / ".." / ".." / "src"
let depsSrc = templateRoot / "deps" / "openxy" / "src"
let atlasLink = templateRoot / "deps" / "openxy.nimble-link"
let linkedSrc =
  if fileExists(atlasLink):
    let lines = readFile(atlasLink).splitLines()
    if lines.len > 0: lines[0].parentDir / "src" else: ""
  else: ""
let openxySrc = if dirExists(localSrc): localSrc
                 elif dirExists(depsSrc): depsSrc
                 elif linkedSrc.len > 0 and dirExists(linkedSrc): linkedSrc
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

task preview, "Sample engines have no browser preview; this task reports that":
  delegate "preview"

task compile, "Compile the Blackfin development module":
  delegate "compile"

task build, "Build a firmware package (needs stockOs)":
  delegate "build"

task clean, "Remove generated output":
  delegate "clean"
