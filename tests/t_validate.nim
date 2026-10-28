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

proc accepts(machine, definition: string; id: string; kind: MachineKind;
             source = "import openxy\n"): bool =
  writeFile(machinePath, machine)
  writeFile(definitionPath, definition)
  writeFile(sourcePath, source)
  let project = Project(root: temp, id: id, source: sourcePath,
                        kind: kind, buildRoot: temp / "build")
  try:
    discard loadMachine(project)
    true
  except ValueError:
    false

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

block sdk_1_4:
  var machine = parseJson(machineText)
  machine["sdk"] = %"1.4"
  doAssert accepts($machine, definitionText, "testsynth", mkSynth)

block sdk_too_new:
  var machine = parseJson(machineText)
  machine["sdk"] = %"1.5"
  doAssert not accepts($machine, definitionText, "testsynth", mkSynth)

block too_many_texts_with_old_sdk:
  var machine = parseJson(machineText)
  machine["sdk"] = %"1.2"
  var definition = parseJson(definitionText)
  definition["resources"]["display"]["texts"] = %5
  doAssert not accepts($machine, $definition, "testsynth", mkSynth)

block synth_eight_valid:
  let eightMachine = readFile(templateRoot / ".." / "synth-eight" / "machine.json")
  let eightDefinition = readFile(templateRoot / ".." / "synth-eight" / "definition.json")
  doAssert accepts(eightMachine, eightDefinition, "mysynth8", mkSynth)

block partial_page_needs_1_4:
  let eightMachine = readFile(templateRoot / ".." / "synth-eight" / "machine.json")
  let eightDefinition = readFile(templateRoot / ".." / "synth-eight" / "definition.json")
  var machine = parseJson(eightMachine)
  var definition = parseJson(eightDefinition)
  var parameters = newJArray()
  for index in 0 ..< 7:
    parameters.add definition["parameters"][index]
  definition["parameters"] = parameters
  for _, preset in definition["presets"]:
    preset.delete("smooth")
  doAssert accepts($machine, $definition, "mysynth8", mkSynth)
  machine["sdk"] = %"1.3"
  doAssert not accepts($machine, $definition, "mysynth8", mkSynth)

block effect_alternate_valid:
  let effectMachine = readFile(templateRoot / ".." / "effect" / "machine.json")
  let effectDefinition = readFile(templateRoot / ".." / "effect" / "definition.json")
  var definition = parseJson(effectDefinition)
  definition["parameters"].add %*{
    "id": "tone", "label": "Tone", "default": 0.0,
    "mapping": {"kind": "linear", "minimum": 0, "maximum": 1},
    "display": "percent"
  }
  definition["parameters"].add %*{
    "id": "alt", "label": "Alt", "control": 0, "default": 0.0,
    "mapping": {"kind": "linear", "minimum": 0, "maximum": 1},
    "display": "percent"
  }
  for _, preset in definition["presets"]:
    preset["tone"] = %0
    preset["alt"] = %0
  doAssert accepts(effectMachine, $definition, "myeffect", mkEffect)

block effect_presets_rejected:
  let effectMachine = readFile(templateRoot / ".." / "effect" / "machine.json")
  let effectDefinition = readFile(templateRoot / ".." / "effect" / "definition.json")
  var machine = parseJson(effectMachine)
  machine["presets"] = %"presets"
  doAssert not accepts($machine, effectDefinition, "myeffect", mkEffect)

block presets_folder:
  let presetsDir = temp / "presets"
  createDir(presetsDir)
  var machine = parseJson(machineText)
  machine["presets"] = %"presets"
  doAssert accepts($machine, definitionText, "testsynth", mkSynth)
  writeFile(presetsDir / "default.json", "{}")
  doAssert accepts($machine, definitionText, "testsynth", mkSynth)

removeDir(temp)
