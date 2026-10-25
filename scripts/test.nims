import std/[os, strutils]

let root = currentSourcePath().parentDir.parentDir
let src = root / "src"
let sdkInclude = root / "open-xy" / "sdk" / "include"
if not dirExists(sdkInclude):
  raise newException(IOError,
    "OP-XY SDK headers not found; initialize the submodule with: git -C " &
    quoteShell(root) & " submodule update --init --recursive")

var ran = 0
for kind, path in walkDir(root / "tests"):
  let name = extractFilename(path)
  if kind == pcFile and name.startsWith("t_") and name.endsWith(".nim"):
    let command = "nim cpp -r --hints:off --path:" & quoteShell(src) &
      " --passC:-I" & quoteShell(sdkInclude) & " " & quoteShell(path)
    echo "Running: ", command
    exec command
    inc ran
if ran == 0:
  raise newException(ValueError, "no tests/t_*.nim files found")
echo "All ", ran, " test files completed."
