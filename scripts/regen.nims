## Optional raw-binding regeneration. Henka and libclang are installed only
## with the Nimble `regen` feature. Henka emits the upstream AST mapping; a
## checked-in patch supplies the template instantiations and const initializers
## it cannot express. A changed SDK that alters those shapes makes the patch
## fail, which is the review point for the generated diff.

import std/[os, strutils]

import openxy/util/fscompat

let root = currentSourcePath().parentDir.parentDir
let sdk = root / "open-xy"
let raw = root / "src" / "openxy" / "private" / "raw"
let patchFile = raw / "henka.patch"

var henka = findExe("henka")
if henka.len == 0:
  let local = root / "deps" / "henka" / "bin" / "henka"
  if fileExists(local):
    henka = local
if henka.len == 0:
  raise newException(OSError,
    "Henka is not installed. Run `atlas install --features=regen` " &
    "(or `nimble install -d --features=regen`) from the openxy checkout.")
if not dirExists(sdk):
  raise newException(OSError,
    "SDK checkout missing; initialize it with: git submodule update --init --recursive")

let lock = (root / "open-xy.lock").readFile.strip
let (commit, code) = gorgeEx("git -C " & quoteShell(sdk) & " rev-parse HEAD")
if code != 0:
  raise newException(OSError, "could not read the SDK commit")
if commit.strip != lock:
  raise newException(ValueError,
    "SDK commit mismatch: expected " & lock & ", found " & commit.strip)

ensureDir(raw)
let headers = [
  "opxy/types.hpp", "opxy/audio.hpp", "opxy/q31.hpp", "opxy/draw.hpp",
  "opxy/sample.hpp", "opxy/sample_engine.hpp", "opxy/sample_analysis.hpp",
  "opxy/effect.hpp", "opxy/transport.hpp", "opxy/page_header.hpp",
]
var command = quoteShell(henka) & " --cpp --std=c++17 --inpath=" &
  quoteShell(sdk / "sdk" / "include") & " --outpath=" & quoteShell(raw)
for header in headers:
  command.add " " & quoteShell(header)
echo "Running: ", command
exec command

let patch = findExe("patch")
if patch.len == 0:
  raise newException(OSError, "`patch` is required to normalize Henka output")
echo "Applying ", patchFile
exec quoteShell(patch) & " -p1 -d " & quoteShell(root) & " -i " & quoteShell(patchFile)

let check = findExe("nim")
if check.len == 0:
  raise newException(OSError, "nim compiler not found in PATH")
exec quoteShell(check) & " check --hints:off --path:" & quoteShell(root / "src") &
  " " & quoteShell(raw / "opxy.nim")
echo "Regenerated raw bindings in ", raw
