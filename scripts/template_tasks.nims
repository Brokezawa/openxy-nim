## Shared implementation of the tasks declared by each machine template.

import std/[os, strutils]

import openxy/paths
import openxy/util/[fscompat, generator, measure, project, sdk, validate]

if paramCount() < 6:
  raise newException(ValueError,
    "usage: template_tasks.nims <task> <root> <id> <source> <buildRoot> <stockOs> <layout>")

# NimScript paramStr also exposes nim and its options; the template arguments
# are the last seven parameters.
let base = paramCount() - 6
let
  taskName = paramStr(base)
  templateRoot = paramStr(base + 1)
  machineId = paramStr(base + 2)
  machineSource = paramStr(base + 3)
  buildRoot = paramStr(base + 4)
  stockOs = paramStr(base + 5)
  layout = paramStr(base + 6)

let currentProject = loadProject(machineId, machineSource, buildRoot, stockOs, layout)
let openxySrc = openxyRoot / "src"

proc runHostTests() =
  let includeDir = sdkIncludeDir(openxyRoot / "open-xy")
  if not dirExists(includeDir):
    raise newException(IOError, "OP-XY SDK headers not found at " & includeDir &
      "; initialize the submodule first")
  var count = 0
  for kind, testFile in walkDir(currentProject.root / "tests"):
    let name = extractFilename(testFile)
    if kind == pcFile and name.startsWith("t_") and name.endsWith(".nim"):
      let command = "nim cpp -r --hints:off --path:" & quoteShell(openxySrc) &
        " --path:" & quoteShell(currentProject.sourceDir) &
        " --passC:-I" & quoteShell(includeDir) & " " & quoteShell(testFile)
      echo "Running: ", command
      exec command
      inc count
  if count == 0:
    raise newException(ValueError, "no tests/t_*.nim files found")

proc prepareGenerated(): tuple[project: Project; spec: MachineSpec] =
  var spec = loadMachine(currentProject,
    readFile(currentProject.root / "machine.json"),
    readFile(currentProject.root / "definition.json"),
    readFile(currentProject.source))
  let probe = spec.project.machineDir / "measure.nim"
  let measurements = measure(spec, probe, openxySrc)
  validateMeasurements(spec, measurements)
  discard prepare(spec, measurements)
  result = (spec.project, spec)

proc generate() =
  let (project, spec) = prepareGenerated()
  let generated = project.machineDir
  switch("path", openxySrc)
  switch("path", project.sourceDir)
  switch("cppCompileToNamespace", project.id)
  switch("nimMainPrefix", project.id & "_")
  switch("nimBasePattern", "vendor/openxy/openxy_nimbase.h")
  switch("noMain", "on")
  switch("compileOnly", "on")
  switch("nimcache", generated / "nimcache")
  switch("os", "any")
  switch("cpu", "arm")
  switch("mm", "arc")
  switch("exceptions", "quirky")
  switch("checks", "off")
  switch("overflowChecks", "off")
  switch("panics", "off")
  switch("threads", "off")
  switch("stackTrace", "off")
  switch("lineTrace", "off")
  switch("define", "useMalloc")
  switch("define", "nimPreviewSlimSystem")
  switch("define", "noSignalHandler")
  switch("define", "release")
  switch("passC", "-I" & generated)
  switch("passC", "-I" & generated / "vendor" / "openxy")
  switch("passC", "-I" & sdkIncludeDir(openxyRoot / "open-xy"))
  setCommand("cpp", generated / "generated" / "wrapper.nim")


proc wasmClang(): string =
  var candidates = @[findExe("clang++")]
  let brew = findExe("brew")
  if brew.len > 0:
    let (prefix, code) = gorgeEx(quoteShell(brew) & " --prefix llvm")
    if code == 0:
      candidates.add prefix.strip / "bin" / "clang++"
  for candidate in candidates:
    if candidate.len == 0 or not fileExists(candidate):
      continue
    let probe = getTempDir() / "openxy-wasm-probe.o"
    let (output, code) = gorgeEx(quoteShell(candidate) &
      " --target=wasm32 -nostdlib -x c++ -c /dev/null -o " & quoteShell(probe))
    let wasm = getTempDir() / "openxy-wasm-probe.wasm"
    let (linkOutput, linkCode) = gorgeEx(quoteShell(candidate) &
      " --target=wasm32 -nostdlib -Wl,--no-entry -x c++ /dev/null -o " & quoteShell(wasm))
    rmFile(probe)
    rmFile(wasm)
    if code == 0 and linkCode == 0:
      return candidate
  ""

proc packageAndRun(command: SdkCommand) =
  let packageProject = loadProject(machineId, machineSource, buildRoot, stockOs, layout)
  let spec = loadMachine(packageProject,
    readFile(packageProject.root / "machine.json"),
    readFile(packageProject.root / "definition.json"),
    readFile(packageProject.source))
  let generated = spec.project.machineDir
  let cachePath = generated / "nimcache" / "wrapper.json"
  package(generated, readFile(cachePath))
  let sdkOut = packageProject.buildRoot / "out" / packageProject.id / $command
  ensureDir(sdkOut.parentDir)
  if dirExists(sdkOut):
    removeDirCompat(sdkOut)
  let cxx = if command == sdkPreview: wasmClang() else: ""
  if command == sdkPreview and cxx.len == 0:
    raise newException(OSError,
      "no wasm-capable clang++ found; install LLVM with the WebAssembly target")
  let commandLine = sdkCommand(command, generated, sdkOut, stockOs, layout, cxx = cxx)
  echo "Running: ", commandLine
  exec commandLine

case taskName
of "test":
  runHostTests()
of "gen":
  generate()
of "preview":
  exec "nim gen"
  packageAndRun(sdkPreview)
of "compile":
  exec "nim gen"
  packageAndRun(sdkCompile)
of "build":
  exec "nim gen"
  packageAndRun(sdkBuild)
of "clean":
  removeDirCompat(currentProject.buildRoot)
else:
  raise newException(ValueError, "unknown template task: " & taskName)
