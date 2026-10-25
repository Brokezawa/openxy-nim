import std/[assertions, os, strutils]

import openxy/util/project

block valid_ids:
  for value in ["a", "mysynth", "a1_b2", "openxy_machine"]:
    doAssert isValidMachineId(value), value

block invalid_ids:
  for value in ["", "1abc", "MySynth", "my-synth", "this_name_is_too_long",
                "sampler", "drum", "delay", "class", "proc", "opxy", "std",
                "sdk_thing", "kit_thing", "stock_thing", "local_thing"]:
    doAssert not isValidMachineId(value), value
    doAssert machineIdError(value).len > 0

block project_paths:
  let project = loadProject("mysynth", "templates/synth/src/mysynth.nim", "build")
  doAssert project.id == "mysynth"
  doAssert project.source.endsWith("templates/synth/src/mysynth.nim")
  doAssert project.sourceModule == "mysynth"
  doAssert project.machineDir.endsWith("build/synth/mysynth")
  doAssert fileExists(project.source)

block source_name_must_match:
  doAssertRaises(ValueError):
    discard loadProject("other", "templates/synth/src/mysynth.nim", "build")

block missing_source:
  doAssertRaises(IOError):
    discard loadProject("missing", "templates/synth/src/missing.nim", "build")
