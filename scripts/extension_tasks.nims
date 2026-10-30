## Shared implementation of the extension template tasks.

import std/[os, strutils]

import openxy/paths
import openxy/util/[extension_generator, extension_validate, fscompat, generator,
  project, sdk]

if paramCount() < 7:
  raise newException(ValueError,
    "usage: extension_tasks.nims <task> <root> <id> <source> <buildRoot> <stockOs> <machine>")

let base = paramCount() - 6
let
  taskName = paramStr(base)
  templateRoot = paramStr(base + 1)
  extensionId = paramStr(base + 2)
  extensionSource = paramStr(base + 3)
  buildRoot = paramStr(base + 4)
  stockOs = paramStr(base + 5)
  machine = paramStr(base + 6)

let projectPaths = extensionPaths(templateRoot, extensionId, extensionSource, buildRoot)
let openxySrc = openxyRoot / "src"
let sdkInclude = sdkIncludeDir(openxyRoot / "open-xy")

proc runHostTests() =
  var count = 0
  for kind, testFile in walkDir(templateRoot / "tests"):
    let name = extractFilename(testFile)
    if kind == pcFile and name.startsWith("t_") and name.endsWith(".nim"):
      let command = "nim cpp -r --hints:off --path:" & quoteShell(openxySrc) &
        " --path:" & quoteShell(projectPaths.source.parentDir) &
        " --passC:-I" & quoteShell(sdkInclude) & " " & quoteShell(testFile)
      echo "Running: ", command
      exec command
      inc count
  if count == 0:
    raise newException(ValueError, "no tests/t_*.nim files found")

proc selectedHooks(): set[HookKind] =
  let moduleName = splitFile(projectPaths.source).name
  let probe = projectPaths.sdkDir / "hooks_probe.nim"
  writeFile(probe, hookProbeSource(moduleName))
  let command = "nim e --hints:off --path:" & quoteShell(openxySrc) &
    " --path:" & quoteShell(projectPaths.source.parentDir) & " " & quoteShell(probe)
  let (output, code) = gorgeEx(command)
  if code != 0:
    raise newException(ValueError, "extension hook probe failed:\n" & output)
  parseHookSelection(output)

proc prepareVendorShims() =
  let vendor = projectPaths.nimDir / "vendor" / "openxy"
  copyFileCompat(projectPaths.nimDir / "limits.h", vendor / "limits.h")
  copyFileCompat(projectPaths.nimDir / "string.h", vendor / "string.h")
  let nimbase = vendor / "nimbase.h"
  var text = readFile(nimbase)
  text = text.replace("#include <limits.h>", "#include \"limits.h\"")
  text = text.replace("#include <string.h>", "#include \"string.h\"")
  writeFile(nimbase, text)
  let warnings = vendor / "warnings.hpp"
  writeFile(warnings, readFile(warnings) &
    "\n#pragma GCC diagnostic ignored \"-Wwrite-strings\"\n")

proc generate() =
  discard prepareExtension(projectPaths)
  prepareVendorShims()
  let selected = selectedHooks()
  writeWrapper(projectPaths, selected)
  let nim = findExe("nim")
  if nim.len == 0:
    raise newException(OSError, "nim compiler not found in PATH")
  let nimcache = projectPaths.nimDir / "nimcache"
  let command = quoteShell(nim) & " cpp --compileOnly:on --noMain:on --hints:off" &
    " --warnings:off --skipParentCfg:on" &
    " --path:" & quoteShell(openxySrc) &
    " --path:" & quoteShell(projectPaths.source.parentDir) &
    " --cppCompileToNamespace:" & quoteShell(projectPaths.id) &
    " --nimMainPrefix:" & quoteShell(projectPaths.id & "_") &
    " --nimBasePattern:" & quoteShell("vendor/openxy/openxy_nimbase.h") &
    " --nimcache:" & quoteShell(nimcache) &
    " --os:any --cpu:arm --mm:arc --exceptions:quirky --checks:off" &
    " --overflowChecks:off --panics:off --threads:off --stackTrace:off --lineTrace:off" &
    " -d:useMalloc -d:nimPreviewSlimSystem -d:noSignalHandler -d:release" &
    " --passC:-I" & quoteShell(projectPaths.nimDir) &
    " --passC:-I" & quoteShell(projectPaths.nimDir / "vendor" / "openxy") &
    " --passC:-I" & quoteShell(sdkInclude) &
    " " & quoteShell(projectPaths.nimDir / "wrapper.nim")
  echo "Running: ", command
  exec command
  package(projectPaths.nimDir, readFile(nimcache / "wrapper.json"))
  copyFileCompat(projectPaths.nimDir / "vendor" / "openxy" / "machine.cpp",
    projectPaths.nimDir / "extension.cpp")
  let nimCpp = projectPaths.nimDir / "extension.cpp"
  var text = readFile(nimCpp)
  text = text.replace("#include <string.h>", "#include \"vendor/openxy/string.h\"")
  text = text.replace("#include <limits.h>", "#include \"vendor/openxy/limits.h\"")
  writeFile(nimCpp, text)
  writeMetadata(projectPaths)
  writeAdapter(projectPaths, selected)

proc resolved(path: string): string =
  if path.len == 0: ""
  elif path.isAbsolute: path
  else: templateRoot / path

proc requireMachine(): string =
  result = resolved(machine)
  if result.len == 0:
    raise newException(ValueError,
      "set machine in config.nims to a generated synth or sample folder")
  if not dirExists(result):
    raise newException(IOError, "machine folder not found: " & result)

proc compile() =
  exec "nim gen"
  let output = projectPaths.buildRoot / "out" / projectPaths.id / "sdkCompile"
  ensureDir(output.parentDir)
  removeDirCompat(output)
  let command = sdkExtensionCommand(sdkCompile, projectPaths.sdkDir, requireMachine(), output)
  echo "Running: ", command
  exec command

proc build() =
  exec "nim gen"
  let stockOsPath = resolved(stockOs)
  if stockOsPath.len == 0:
    raise newException(ValueError, "build requires stockOs in config.nims")
  let output = projectPaths.buildRoot / "out" / projectPaths.id / "sdkBuild"
  ensureDir(output.parentDir)
  removeDirCompat(output)
  let command = sdkExtensionCommand(sdkBuild, projectPaths.sdkDir, requireMachine(),
    output, stockOsPath)
  echo "Running: ", command
  exec command

case taskName
of "test":
  runHostTests()
of "gen":
  generate()
of "compile":
  compile()
of "build":
  build()
of "clean":
  removeDirCompat(projectPaths.buildRoot)
else:
  raise newException(ValueError, "unknown extension task: " & taskName)
