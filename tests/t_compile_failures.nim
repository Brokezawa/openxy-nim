import std/assertions
import std/[os, osproc]

let root = currentSourcePath().parentDir.parentDir
let src = root / "src"
let nim = findExe("nim")

proc check(path: string): (string, int) =
  execCmdEx(quoteShell(nim) & " check --hints:off --path:" & quoteShell(src) & " " &
    quoteShell(root / path))

block valid_fixture_compiles:
  let (output, code) = check("tests/fixtures/valid_synth.nim")
  doAssert code == 0, output

block failures:
  for path in [
    "tests/fail/mix_phase_sample.nim",
    "tests/fail/mix_units.nim",
    "tests/fail/readonly_parameters.nim",
    "tests/fail/readonly_pitch.nim",
    "tests/fail/wrong_callback.nim",
    "tests/fail/missing_destroy.nim",
    "tests/fail/raising_callback.nim",
    "tests/fail/page_header_small_frame.nim",
  ]:
    let (output, code) = check(path)
    doAssert code != 0, "expected compile failure: " & path & "\n" & output
