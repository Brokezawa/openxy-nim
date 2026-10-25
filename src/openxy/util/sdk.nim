## Discovery and invocation of the pinned OP-XY SDK.

import std/os
when defined(nimscript):
  import std/strutils

import openxy/paths
import openxy/util/project

type
  SdkCommand* = enum
    sdkPreview, sdkCompile, sdkBuild, sdkDoctor

proc requireSdk*(sdkRoot = openxyRoot / "open-xy") =
  if not dirExists(sdkRoot):
    raise newException(IOError,
      "OP-XY SDK not found at " & sdkRoot &
      "; initialize the submodule with: git -C " & openxyRoot &
      " submodule update --init --recursive")
  if not fileExists(sdkRoot / "sdk.py"):
    raise newException(IOError, "OP-XY SDK is incomplete: " & (sdkRoot / "sdk.py") & " is missing")

proc requireToolchain*(sdkRoot = openxyRoot / "open-xy") =
  let bin = sdkRoot / "local" / "toolchain" / "bin"
  if not dirExists(bin):
    let python = block:
      let found = findExe("python3")
      if found.len != 0: found else: "python3"
    raise newException(IOError,
      "Blackfin toolchain not installed at " & bin &
      "; run: " & quoteShell(python) & " " &
      quoteShell(sdkRoot / "sdk.py") & " toolchain fetch")

proc sdkCommand*(command: SdkCommand; machineDir, outputDir: string;
                 stockOs = ""; layout = ""; python = ""; cxx = "";
                 checkToolchain = true): string =
  requireSdk()
  let executable = if python.len != 0: python else: pythonExecutable()
  if executable.len == 0:
    raise newException(IOError,
      "Python 3 not found in PATH; install Python and run `python3 sdk.py doctor --preview`")
  when defined(nimscript):
    let (versionText, versionCode) = gorgeEx(quoteShell(executable) &
      " -c \"import sys; print(sys.version_info[0] * 1000 + sys.version_info[1])\"")
    if versionCode != 0 or versionText.strip.len == 0 or versionText.strip.parseInt < 3010:
      raise newException(IOError,
        "the OP-XY SDK needs Python 3.10 or newer; found: " & executable &
        " (" & versionText.strip & ")")
  if checkToolchain and command in {sdkCompile, sdkBuild}:
    requireToolchain()
  let script = sdkScript(openxyRoot / "open-xy")
  result = quoteShell(executable) & " " & quoteShell(script)
  case command
  of sdkPreview:
    result.add " preview --machine " & quoteShell(machineDir) &
      " --out " & quoteShell(outputDir)
    if cxx.len != 0:
      result.add " --cxx " & quoteShell(cxx)
  of sdkCompile:
    result.add " compile --machine " & quoteShell(machineDir) &
      " --out " & quoteShell(outputDir)
  of sdkBuild:
    if stockOs.len == 0:
      raise newException(ValueError, "build requires stockOs in the template config.nims")
    result.add " build --machine " & quoteShell(machineDir) &
      " --out " & quoteShell(outputDir) &
      " --stock-os " & quoteShell(stockOs)
    if layout.len != 0:
      result.add " --layout " & quoteShell(layout)
  of sdkDoctor:
    result.add " doctor --preview"
    if cxx.len != 0:
      result.add " --cxx " & quoteShell(cxx)
