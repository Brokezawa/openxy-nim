## Actionable environment checks for the openxy checkout.

import std/[os, strutils]

let root = currentSourcePath().parentDir.parentDir
let sdk = root / "open-xy"
var failures: seq[string]

proc fail(message: string) =
  failures.add message
  echo "FAIL: ", message

proc ok(message: string) =
  echo "ok:   ", message

proc currentCommit(directory: string): string =
  var gitDir = directory / ".git"
  if fileExists(gitDir):
    let pointer = readFile(gitDir).strip
    if pointer.startsWith("gitdir:"):
      gitDir = directory / pointer[7 .. ^1].strip
  let head = readFile(gitDir / "HEAD").strip
  if head.startsWith("ref: "):
    readFile(gitDir / head[5 .. ^1]).strip
  else:
    head

block sdk_checkout:
  if not dirExists(sdk):
    fail("SDK checkout missing at " & sdk &
      "; initialize it with: git submodule update --init --recursive")
  elif not fileExists(sdk / "sdk.py"):
    fail("SDK checkout is incomplete: " & (sdk / "sdk.py") & " is missing")
  elif not fileExists(sdk / "VERSION"):
    fail("SDK checkout is incomplete: VERSION is missing")
  else:
    ok("SDK " & readFile(sdk / "VERSION").strip & " at " & sdk)

block sdk_commit:
  let expectedPath = root / "open-xy.lock"
  if not fileExists(expectedPath):
    fail("open-xy.lock is missing")
  else:
    let expected = readFile(expectedPath).strip
    try:
      let actual = currentCommit(sdk)
      if actual == expected:
        ok("SDK commit " & actual)
      else:
        fail("SDK commit is " & actual & "; expected " & expected &
          ". Re-check out the pinned SDK revision.")
    except OSError as error:
      fail("cannot read SDK commit metadata: " & error.msg)

block python:
  var selected = ""
  var selectedVersion = 0
  var candidates = @["python3.13", "python3.12", "python3.11", "python3.10",
                     "python3", "python"]
  let uv = findExe("uv")
  if uv.len != 0:
    let (output, code) = gorgeEx(quoteShell(uv) & " python find 3.12")
    if code == 0 and output.strip.len != 0:
      candidates.insert(output.strip, 0)
  for candidate in candidates:
    let executable = findExe(candidate)
    if executable.len == 0:
      continue
    let (output, code) = gorgeEx(quoteShell(executable) &
      " -c \"import sys; print(sys.version_info[0] * 1000 + sys.version_info[1])\"")
    if code == 0 and output.strip.len > 0:
      let version = output.strip.parseInt
      if version > selectedVersion:
        selected = executable
        selectedVersion = version
  if selected.len == 0:
    fail("Python 3 not found; install Python 3.10+ and run `python3 sdk.py doctor --preview`")
  elif selectedVersion < 3010:
    fail("Python " & $selectedVersion & " at " & selected &
      " is too old; the SDK needs Python 3.10+")
  else:
    ok("Python " & $selectedVersion & " at " & selected)

block wasm:
  var candidates = @[findExe("clang++")]
  let brew = findExe("brew")
  if brew.len > 0:
    let (prefix, code) = gorgeEx(quoteShell(brew) & " --prefix llvm")
    if code == 0:
      candidates.add prefix.strip / "bin" / "clang++"
  var found = ""
  var lastError = ""
  for clang in candidates:
    if clang.len == 0 or not fileExists(clang):
      continue
    let probe = getTempDir() / "openxy-wasm-probe.o"
    let (output, code) = gorgeEx(quoteShell(clang) &
      " --target=wasm32 -nostdlib -x c++ -c /dev/null -o " & quoteShell(probe))
    let wasm = getTempDir() / "openxy-wasm-probe.wasm"
    let (linkOutput, linkCode) = gorgeEx(quoteShell(clang) &
      " --target=wasm32 -nostdlib -Wl,--no-entry -x c++ /dev/null -o " & quoteShell(wasm))
    rmFile(probe)
    rmFile(wasm)
    if code == 0 and linkCode == 0:
      found = clang
      break
    lastError = (output & " " & linkOutput).strip
  if found.len == 0:
    fail("no clang++ can compile wasm32; install LLVM with the WebAssembly target: " &
      lastError)
  else:
    ok("wasm-capable clang++ at " & found)

block blackfin:
  let tools = sdk / "local" / "toolchain" / "bin"
  if not fileExists(tools / "bfin-elf-g++"):
    fail("pinned Blackfin toolchain missing at " & tools &
      "; run: python3 " & quoteShell(sdk / "sdk.py") & " toolchain fetch")
  else:
    ok("Blackfin toolchain at " & tools)

block node_check:
  let nodeExe = findExe("node")
  if nodeExe.len == 0:
    fail("node not found; install Node.js for the browser preview")
  else:
    let (output, code) = gorgeEx(quoteShell(nodeExe) & " --version")
    if code == 0:
      ok("Node " & output.strip)
    else:
      fail("node --version failed")

if failures.len > 0:
  raise newException(OSError, $failures.len & " environment check(s) failed")
echo "All environment checks passed."
