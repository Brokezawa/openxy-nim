import std/[assertions, json, os, strutils]

import openxy/kind
import openxy/util/project
import openxy/util/validate

let root = currentSourcePath().parentDir.parentDir
let templateRoot = root / "templates" / "synth"
let templateProject = Project(
  root: templateRoot,
  id: "mysynth",
  source: templateRoot / "src" / "mysynth.nim",
  kind: mkSynth,
  buildRoot: templateRoot / "build",
)

block valid_template:
  let spec = loadMachine(templateProject)
  doAssert spec.kind == mkSynth
  doAssert spec.name == "My Synth"
  doAssert spec.display.paths == 2
  doAssert spec.display.points == 64

let temp = getTempDir() / "openxy-validate-tests"
if dirExists(temp):
  removeDir(temp)
createDir(temp)
let machinePath = temp / "machine.json"
let definitionPath = temp / "definition.json"
let sourcePath = temp / "testsynth.nim"
writeFile(sourcePath, "import openxy\n")
let machineText = readFile(templateRoot / "machine.json").replace("mysynth", "testsynth")
let definitionText = readFile(templateRoot / "definition.json").replace("mysynth", "testsynth")

proc check(label: string; machine, definition: string; source = "import openxy\n") =
  writeFile(machinePath, machine)
  writeFile(definitionPath, definition)
  writeFile(sourcePath, source)
  let project = Project(root: temp, id: "testsynth", source: sourcePath,
                        kind: mkSynth, buildRoot: temp / "build")
  try:
    discard loadMachine(project)
  except ValueError as error:
    return
  doAssert false, "expected rejection: " & label

block valid_temp:
  writeFile(machinePath, machineText)
  writeFile(definitionPath, definitionText)
  let project = Project(root: temp, id: "testsynth", source: sourcePath,
                        kind: mkSynth, buildRoot: temp / "build")
  doAssert loadMachine(project).kind == mkSynth

block definition_id_mismatch:
  var definition = parseJson(definitionText)
  definition["id"] = %"other"
  check("definition id", machineText, $definition)

block bad_control_label:
  var definition = parseJson(definitionText)
  definition["parameters"][0]["label"] = %"TooLongLabel"
  check("control label", machineText, $definition)

block duplicate_parameter:
  var definition = parseJson(definitionText)
  definition["parameters"][1]["id"] = %"blend"
  check("duplicate parameter", machineText, $definition)

block bad_voice_bytes:
  var definition = parseJson(definitionText)
  definition["resources"]["voiceBytes"] = %3
  check("voiceBytes", machineText, $definition)

block bad_display_relation:
  var definition = parseJson(definitionText)
  definition["resources"]["display"]["paths"] = %0
  check("display relation", machineText, $definition)

block incomplete_preset:
  var definition = parseJson(definitionText)
  definition["presets"]["Triangle"] = %*{"blend": 0.5}
  check("preset keys", machineText, $definition)

block wrong_kind_resources:
  var machine = parseJson(machineText)
  machine["kind"] = %"sample"
  check("kind resources", $machine, definitionText)

block top_level_var:
  check("top-level var", machineText, definitionText, "var state: int\n")

removeDir(temp)
