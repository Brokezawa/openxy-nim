import std/[assertions, os, osproc, strutils]

import openxy

let root = currentSourcePath().parentDir.parentDir
let clang = findExe("clang++")
doAssert clang.len > 0, "clang++ is required for the page-header reference"

let binary = getTempDir() / "openxy-page-header-probe"
let command = quoteShell(clang) & " -std=c++11 -Werror -I" &
  quoteShell(root / "open-xy" / "sdk" / "include") & " " &
  quoteShell(root / "tests" / "page_header_probe.cpp") & " -o " & quoteShell(binary)
let (compileOutput, compileCode) = execCmdEx(command)
doAssert compileCode == 0, compileOutput
let (reference, runCode) = execCmdEx(quoteShell(binary))
doAssert runCode == 0, reference

proc charString(value: openArray[char]): string =
  for character in value:
    if character == '\0':
      break
    result.add character

proc emit(frame: Frame[2, 64, 10, 16, 16]): string =
  "node=" & $frame.nodes[2].x & "," & $frame.nodes[2].y & "," &
    $frame.nodes[2].scale & " text0=" & charString(frame.texts[0].chars) &
    " text8=" & charString(frame.texts[8].chars) &
    " header0=" & charString(frame.header[0]) & "\n"

var state: PageHeader
state.reset()
var frame: Frame[2, 64, 10, 16, 16]
let titles: array[8, string] = ["One", "Two", "Three", "Four",
  "Five", "Six", "Seven", "Eight"]
var values: array[8, HeaderText]
for value in values.mitems:
  headerAmount(value, Q31(0x40000000))
const slots: PageHeaderSlots = [[0'u8, 1, 2, 3], [4'u8, 5, 6, 7]]
var input: Input
var output = emit(frame)
for index in 0 ..< 4:
  input.shown[index] = uint8(index + 4)
input.elapsed = Q10(16)
pageHeader(state, input, frame, titles, values, 2, slots)
output.add emit(frame)
pageHeader(state, input, frame, titles, values, 2, slots)
output.add emit(frame)
input.elapsed = Q10(154)
pageHeader(state, input, frame, titles, values, 2, slots)
output.add emit(frame)
inc input.track
pageHeader(state, input, frame, titles, values, 2, slots)
output.add emit(frame)
for index in 0 ..< 4:
  input.shown[index] = uint8(index)
input.reducedMotion = 1
pageHeader(state, input, frame, titles, values, 2, slots)
output.add emit(frame)

doAssert output == reference, "Nim page header differs from SDK C++:\n" & output & "\n---\n" & reference
