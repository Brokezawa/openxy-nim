import std/[assertions, os, osproc, strutils]

import openxy
import openxy/private/raw/opxy/extension_raw as raw

let root = currentSourcePath().parentDir.parentDir
let clang = findExe("clang++")
doAssert clang.len > 0, "clang++ is required for the 32-bit extension ABI probe"

block public_layout:
  doAssert sizeof(extension.Time) == 8
  doAssert sizeof(extension.Track) == 4
  doAssert sizeof(extension.ProjectId) == 4
  doAssert sizeof(extension.PatternId) == 4
  doAssert sizeof(extension.Ticks) == 4
  doAssert sizeof(extension.RecordingContext) == 28
  doAssert sizeof(extension.Context) == 32
  doAssert sizeof(extension.Note) == 12
  doAssert sizeof(extension.LiveNote) == 20
  doAssert sizeof(extension.NoteOff) == 8
  doAssert sizeof(extension.Tick) == 8
  doAssert sizeof(extension.Control) == 16
  doAssert sizeof(extension.Hooks) == 48

block note_offsets:
  doAssert offsetOf(extension.Note, position) == 0
  doAssert offsetOf(extension.Note, length) == 4
  doAssert offsetOf(extension.Note, pitch) == 8
  doAssert offsetOf(extension.Note, velocity) == 9

block raw_layout:
  doAssert sizeof(raw.RecordingContext) == 28
  doAssert sizeof(raw.Context) == 32
  doAssert sizeof(raw.Note) == 12
  doAssert sizeof(raw.LiveNote) == 20
  doAssert sizeof(raw.NoteOff) == 8
  doAssert sizeof(raw.Tick) == 8
  doAssert sizeof(raw.Control) == 16
  doAssert sizeof(raw.Actions) == 24
  doAssert sizeof(raw.Hooks) == 48
  doAssert offsetOf(raw.Note, position) == 0
  doAssert offsetOf(raw.Note, length) == 4
  doAssert offsetOf(raw.Note, pitch) == 8
  doAssert offsetOf(raw.Note, velocity) == 9

block target_32bit:
  let probe = root / "tests" / "extension_abi_probe32.cpp"
  let binary = getTempDir() / "openxy-extension-abi32.o"
  let command = quoteShell(clang) & " -target i386-unknown-none -ffreestanding " &
    "-std=c++11 -I" & quoteShell(root / "open-xy" / "sdk" / "include") &
    " -c " & quoteShell(probe) & " -o " & quoteShell(binary)
  let (output, code) = execCmdEx(command)
  doAssert code == 0, output
