import std/[os, strutils]

# Explicit extension metadata. The shared openxy script holds the reusable
# implementation. Set `machine` to a generated synth or sample folder for
# device compile and firmware build; host tests and generation work without it.
const
  extensionId = "mynotify"
  extensionSource = "src/mynotify.nim"
  buildRoot = "build"
  stockOs = ""
  machine = ""

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
let openxyScript = openxySrc.parentDir / "scripts" / "extension_tasks.nims"

proc delegate(taskName: string) =
  exec "nim e --hints:off --path:" & quoteShell(openxySrc) & " " &
    quoteShell(openxyScript) & " " & taskName & " " & quoteShell(templateRoot) & " " &
    quoteShell(extensionId) & " " & quoteShell(extensionSource) & " " &
    quoteShell(buildRoot) & " " & quoteShell(stockOs) & " " & quoteShell(machine)

task test, "Run the extension host tests":
  delegate "test"

task gen, "Validate, generate, and package the SDK extension folder":
  delegate "gen"

task compile, "Compile the extension with a machine collection":
  delegate "compile"

task build, "Build a firmware package (needs stockOs and machine)":
  delegate "build"

task clean, "Remove generated output":
  delegate "clean"
