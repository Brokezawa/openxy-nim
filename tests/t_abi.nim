import std/assertions
import std/[os, osproc]

let root = currentSourcePath().parentDir.parentDir
let clang = findExe("clang++")
doAssert clang.len > 0, "clang++ is required for the ABI probe"

var command = quoteShell(clang) & " -std=c++11 -Werror -c " &
  quoteShell(root / "tests" / "abi_probe.cpp") &
  " -I" & quoteShell(root / "open-xy" / "sdk" / "include") &
  " -o " & quoteShell(getTempDir() / "openxy-abi-probe.o")
let (output, code) = execCmdEx(command)
doAssert code == 0, output

# Also compile the generated public headers when a template build is present.
let generated = root / "templates" / "synth" / "build" / "synth" / "mysynth"
if fileExists(generated / "core.h"):
  let probe = getTempDir() / "openxy-generated-abi.cpp"
  writeFile(probe, """
#include "core.h"
#include "display.h"
static_assert(sizeof(mysynth::Voice) == 4, "generated Voice");
static_assert(alignof(mysynth::Voice) == 4, "generated Voice alignment");
static_assert(sizeof(mysynth::Shared) == 1, "generated Shared");
static_assert(sizeof(mysynth::DisplayState) == 20, "generated DisplayState");
static_assert(sizeof(mysynth::Frame) == 1156, "generated Frame");
""")
  command = quoteShell(clang) & " -std=c++11 -Werror -c " & quoteShell(probe) &
    " -I" & quoteShell(generated) &
    " -I" & quoteShell(root / "open-xy" / "sdk" / "include") &
    " -o " & quoteShell(getTempDir() / "openxy-generated-abi.o")
  let (generatedOutput, generatedCode) = execCmdEx(command)
  doAssert generatedCode == 0, generatedOutput
