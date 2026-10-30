import std/[assertions, os, osproc]

import openxy

let root = currentSourcePath().parentDir.parentDir
let clang = findExe("clang++")
doAssert clang.len > 0, "clang++ is required for the double-tap reference"

let binary = getTempDir() / "openxy-double-tap-probe"
let command = quoteShell(clang) & " -std=c++11 -Werror -I" &
  quoteShell(root / "open-xy" / "sdk" / "include") & " " &
  quoteShell(root / "tests" / "double_tap_probe.cpp") & " -o " & quoteShell(binary)
let (compileOutput, compileCode) = execCmdEx(command)
doAssert compileCode == 0, compileOutput
let (reference, runCode) = execCmdEx(quoteShell(binary))
doAssert runCode == 0, reference

var tap: DoubleTap
var output: string

proc press(time: uint64; unmodified: bool) =
  output.add "press=" & (if tap.press(Time(time), unmodified): "1" else: "0") & "\n"

proc release(time: uint64) =
  output.add "release=" & (if tap.release(Time(time)): "1" else: "0") & "\n"

press(0, true)
release(50_000)
press(100_000, true)
release(150_000)
release(200_000)
press(300_000, true)
release(600_000)
press(700_000, true)
release(720_000)
press(800_000, true)
release(850_000)
press(1_300_000, true)
release(1_350_000)
press(1_400_000, false)
release(1_450_000)

doAssert output == reference, "Nim double-tap differs from SDK C++:\n" & output & "\n---\n" & reference
