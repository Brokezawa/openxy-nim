## Early validation of machine metadata before the SDK sees it.

import std/[json, os, strutils]

import openxy/kind
import openxy/util/project

type
  DisplayShape* = object
    paths*, points*, nodes*, texts*, palette*: int

  MachineSpec* = object
    project*: Project
    machine*: JsonNode
    definition*: JsonNode
    kind*: MachineKind
    name*: string
    display*: DisplayShape
    hasAnalysis*: bool
    hasPadSettings*: bool
    hasDrumControls*: bool
    hasBuffer*: bool
    hasTransport*: bool
    dryParameter*: int

  Measurements* = object
    voiceBytes*, voiceAlignment*, sharedBytes*: int
    displayBytes*, displayAlignment*: int
    frameBytes*, frameAlignment*: int
    stateBytes*, stateAlignment*: int
    preparationBytes*, preparationAlignment*: int

proc fail(message: string) {.noreturn.} =
  raise newException(ValueError, message)

proc require(condition: bool; message: string) =
  if not condition:
    fail(message)

proc field(node: JsonNode; name: string): JsonNode =
  if node == nil or node.kind != JObject or not node.hasKey(name):
    fail("missing JSON field: " & name)
  node[name]

proc stringField(node: JsonNode; name: string): string =
  let value = field(node, name)
  require(value.kind == JString, name & " must be a string")
  value.getStr

proc intField(node: JsonNode; name: string): int =
  let value = field(node, name)
  require(value.kind == JInt, name & " must be an integer")
  value.getInt

proc optionalInt(node: JsonNode; name: string; fallback: int): int =
  if node != nil and node.kind == JObject and node.hasKey(name):
    intField(node, name)
  else:
    fallback

proc numberField(node: JsonNode; name: string): float =
  let value = field(node, name)
  require(value.kind in {JInt, JFloat}, name & " must be a number")
  value.getFloat

proc boolFlag(node: JsonNode; name: string): bool =
  optionalInt(node, name, 0) != 0

proc allowedKeys(node: JsonNode; allowed: openArray[string]; label: string) =
  require(node != nil and node.kind == JObject, label & " must be an object")
  for key, _ in node:
    require(key in allowed, "unexpected " & label & " field: " & key)

proc requireKeys(node: JsonNode; required: openArray[string]; label: string) =
  for key in required:
    require(node.hasKey(key), label & " is missing " & key)

proc validIdentifier(value: string): bool =
  if value.len == 0 or value.len > 32 or value[0] notin {'a'..'z'}:
    return false
  for character in value:
    if character notin {'a'..'z', '0'..'9', '_', '-'}:
      return false
  true

proc validLabel(value: string): bool =
  if value.len == 0 or value.len > 64 or value[0] notin {'A'..'Z', 'a'..'z', '0'..'9'}:
    return false
  for character in value:
    if character notin {'A'..'Z', 'a'..'z', '0'..'9', ' ', '_', '-'}:
      return false
  true

proc validControlLabel(value: string): bool =
  value.len in 1 .. 8 and value[0] in {'A'..'Z', 'a'..'z', '0'..'9'} and
    value.allCharsInSet({'A'..'Z', 'a'..'z', '0'..'9', ' '})

proc validateParameter(parameter: JsonNode; index: int; kind: MachineKind) =
  require(parameter != nil and parameter.kind == JObject, "parameter " & $index & " must be an object")
  let alternate = kind == mkSynth and index >= 4
  var allowed = @["id", "label", "default", "mapping", "display"]
  if alternate: allowed.add "control"
  allowedKeys(parameter, allowed, "parameter")
  requireKeys(parameter, ["id", "label", "default", "mapping", "display"], "parameter")
  let identity = stringField(parameter, "id")
  require(validIdentifier(identity), "invalid parameter id: " & identity)
  require(validControlLabel(stringField(parameter, "label")),
    "control labels are at most 8 letters, digits or spaces")
  let default = numberField(parameter, "default")
  require(default >= 0 and default <= 1, "parameter defaults are normalized 0..1")
  if alternate:
    let control = intField(parameter, "control")
    require(control >= 0 and control < 4, "alternate controls name a position 0..3")
  let mapping = field(parameter, "mapping")
  require(mapping.kind == JObject, "parameter mapping must be an object")
  let mappingKind = stringField(mapping, "kind")
  require(mappingKind in ["linear", "anchors", "power", "exponential", "enum"],
    "unknown parameter mapping: " & mappingKind)
  case mappingKind
  of "linear":
    allowedKeys(mapping, ["kind", "minimum", "maximum"], "linear mapping")
    require(numberField(mapping, "minimum") < numberField(mapping, "maximum"),
      "linear mapping must increase")
  of "anchors":
    let values = field(mapping, "values")
    require(values.kind == JArray and values.len >= 3 and values.len <= 256,
      "anchors need 3..256 values")
    var previous = low(float)
    for value in values:
      require(value.kind in {JInt, JFloat}, "anchor values must be numbers")
      let number = value.getFloat
      require(number > previous, "anchor values must increase")
      previous = number
  of "power":
    allowedKeys(mapping, ["kind", "maximum", "exponent"], "power mapping")
    discard numberField(mapping, "maximum")
    let exponent = numberField(mapping, "exponent")
    require(exponent > 0 and exponent <= 32 and exponent != 1, "power exponent must be 0.01..32 and not 1")
  of "exponential":
    allowedKeys(mapping, ["kind", "minimum", "maximum"], "exponential mapping")
    require(numberField(mapping, "minimum") > 0 and
      numberField(mapping, "maximum") > numberField(mapping, "minimum"),
      "exponential mapping must increase from a positive minimum")
  of "enum":
    allowedKeys(mapping, ["kind", "labels"], "enum mapping")
    let labels = field(mapping, "labels")
    require(labels.kind == JArray and labels.len >= 2 and labels.len <= 256,
      "enum labels need 2..256 values")
  else:
    discard
  let display = stringField(parameter, "display")
  require(display in ["ratio", "percent", "bipolar", "duration", "semitones", "enum", "division"],
    "unsupported parameter display: " & display)
  require((display == "enum") == (mappingKind == "enum"),
    "enum mapping and display must agree")
  if display == "division":
    require(mappingKind == "linear" and numberField(mapping, "minimum") == 0 and
      numberField(mapping, "maximum") == 1,
      "a division control maps linearly from 0 to 1")

proc validateDisplay(display: JsonNode) =
  allowedKeys(display, ["stateBytes", "stateAlignment", "paths", "points", "nodes", "texts", "palette"],
    "display")
  requireKeys(display, ["stateBytes", "stateAlignment", "paths", "points", "nodes", "texts", "palette"],
    "display")
  let stateBytes = intField(display, "stateBytes")
  let stateAlignment = intField(display, "stateAlignment")
  require(stateBytes >= 4 and stateBytes mod stateAlignment == 0 and
    stateAlignment in [4, 8, 16], "display state must occupy aligned whole words")
  let paths = intField(display, "paths")
  let points = intField(display, "points")
  let nodes = intField(display, "nodes")
  let texts = intField(display, "texts")
  let palette = intField(display, "palette")
  require(paths in 0 .. 4 and points in 0 .. 64 and nodes in 1 .. 256 and
    texts in 0 .. 4 and palette in 1 .. 16, "display budget outside SDK limits")
  require((points >= 2) == (paths > 0), "paths have 2..64 points; a display without paths declares 0")
  require(paths <= nodes, "each path is also a node")

proc validateResources(definition: JsonNode; kind: MachineKind; page: int): tuple[
    display: DisplayShape; hasAnalysis, hasPadSettings, hasDrumControls, hasBuffer,
    hasTransport: bool] =
  let resources = field(definition, "resources")
  require(resources.kind == JObject, "resources must be an object")
  case kind
  of mkSynth:
    allowedKeys(resources, ["voiceBytes", "voiceAlignment", "voiceCapacity", "sharedBytes",
      "outputPeakQ31", "display"], "resources")
    requireKeys(resources, ["voiceBytes", "voiceAlignment", "voiceCapacity", "sharedBytes",
      "outputPeakQ31", "display"], "resources")
    require(intField(resources, "voiceBytes") >= 4 and intField(resources, "voiceBytes") mod 4 == 0,
      "voiceBytes must be at least one word")
    let alignment = intField(resources, "voiceAlignment")
    require(alignment in [4, 8, 16] and intField(resources, "voiceBytes") mod alignment == 0,
      "unsupported voice alignment")
    require(intField(resources, "voiceCapacity") in 1 .. 256, "voiceCapacity must be 1..256")
    require(intField(resources, "sharedBytes") >= 0 and intField(resources, "sharedBytes") mod 4 == 0,
      "sharedBytes must be whole words")
    let peak = intField(resources, "outputPeakQ31")
    require(peak > 0 and peak <= 0x7fffffff, "outputPeakQ31 must be positive")
    validateDisplay(field(resources, "display"))
    result.display = DisplayShape(
      paths: intField(resources["display"], "paths"),
      points: intField(resources["display"], "points"),
      nodes: intField(resources["display"], "nodes"),
      texts: intField(resources["display"], "texts"),
      palette: intField(resources["display"], "palette"),
    )
  of mkSample:
    allowedKeys(resources, ["voiceCapacity", "sampleAnalysis", "chokeSameKey", "padSettings",
      "drumControls", "stereoOutput"], "resources")
    require(intField(resources, "voiceCapacity") == 256,
      "a sample engine needs voiceCapacity 256")
    let analysis = optionalInt(resources, "sampleAnalysis", 0)
    require(analysis == 0 or (analysis >= 4096 and analysis <= 2 * 1024 * 1024 and analysis mod 4 == 0),
      "sampleAnalysis is 0 or an aligned budget up to 2 MiB")
    for flag in ["chokeSameKey", "padSettings", "drumControls", "stereoOutput"]:
      require(optionalInt(resources, flag, 0) in 0 .. 1, flag & " must be 0 or 1")
    result.hasAnalysis = analysis != 0
    result.hasPadSettings = boolFlag(resources, "padSettings")
    result.hasDrumControls = boolFlag(resources, "drumControls")
    require(result.hasPadSettings or not result.hasDrumControls,
      "drumControls edits pad settings: it needs padSettings")
    if result.hasPadSettings or result.hasDrumControls:
      require(page == 7, "pad settings and drum controls need stock page 7")
  of mkEffect:
    allowedKeys(resources, ["bufferBytes", "transport"], "resources")
    let buffer = optionalInt(resources, "bufferBytes", 0)
    require(buffer == 0 or (buffer >= 4 and buffer <= 524288 and buffer mod 4 == 0),
      "bufferBytes is whole words up to 512 KiB")
    result.hasBuffer = buffer != 0
    result.hasTransport = boolFlag(resources, "transport")
  result

proc validateDefinition(definition: JsonNode; kind: MachineKind; page: int): tuple[
    name: string; display: DisplayShape; hasAnalysis, hasPadSettings, hasDrumControls,
    hasBuffer, hasTransport: bool; dryParameter: int] =
  allowedKeys(definition, ["schema", "id", "name", "parameters", "presets", "resources"], "definition")
  requireKeys(definition, ["schema", "id", "name", "parameters", "presets", "resources"], "definition")
  require(intField(definition, "schema") == 1, "unknown definition schema")
  let identity = stringField(definition, "id")
  require(identity.len > 0, "definition id is empty")
  let name = stringField(definition, "name")
  require(validLabel(name), "invalid machine name")
  let parameters = field(definition, "parameters")
  require(parameters.kind == JArray, "parameters must be an array")
  let low = if kind == mkSynth: 4 else: 1
  require(parameters.len >= low and parameters.len <= 8, "control count outside SDK limits")
  var names: seq[string]
  for index in 0 ..< parameters.len:
    let parameter = parameters[index]
    validateParameter(parameter, index, kind)
    let parameterId = stringField(parameter, "id")
    require(parameterId notin names, "duplicate parameter id: " & parameterId)
    names.add parameterId
  let presets = field(definition, "presets")
  require(presets.kind == JObject and presets.len <= 64, "presets must be an object with at most 64 entries")
  for presetName, preset in presets:
    require(validLabel(presetName), "invalid preset name: " & presetName)
    allowedKeys(preset, names, "preset")
    requireKeys(preset, names, "preset")
    for _, value in preset:
      require(value.kind in {JInt, JFloat} and value.getFloat >= 0 and value.getFloat <= 1,
        "preset values are normalized 0..1")
  let resources = validateResources(definition, kind, page)
  result = (name, resources.display, resources.hasAnalysis, resources.hasPadSettings,
    resources.hasDrumControls, resources.hasBuffer, resources.hasTransport, -1)

proc validateIdentity(machine: JsonNode; kind: MachineKind): int =
  let identity = field(machine, "identity")
  require(identity.kind == JObject, "identity must be an object")
  let slot = if kind == mkEffect: "effect" else: "engine"
  allowedKeys(identity, [slot, "page"], "identity")
  requireKeys(identity, [slot, "page"], "identity")
  discard intField(identity, slot)
  intField(identity, "page")

proc validateSource(source: string) =
  for line in source.splitLines:
    let trimmed = line.strip
    if trimmed.len == 0 or trimmed.startsWith("#"):
      continue
    if line.len == line.strip.len and
        (trimmed.startsWith("var ") or trimmed.startsWith("let ")):
      fail("top-level mutable state is not allowed in a machine source: " & trimmed)

proc loadMachine*(project: Project; machineText = ""; definitionText = "";
                  sourceText = ""): MachineSpec =
  ## Read and validate machine.json and definition.json from the template root.
  let machinePath = project.root / "machine.json"
  let definitionPath = project.root / "definition.json"
  require(fileExists(machinePath), "machine.json not found in " & project.root)
  require(fileExists(definitionPath), "definition.json not found in " & project.root)
  var machine: JsonNode
  var definition: JsonNode
  try:
    let machineSource = if machineText.len == 0: readFile(machinePath) else: machineText
    let definitionSource = if definitionText.len == 0: readFile(definitionPath) else: definitionText
    machine = parseJson(machineSource)
    definition = parseJson(definitionSource)
  except JsonParsingError as error:
    fail("invalid JSON: " & error.msg)
  allowedKeys(machine, ["schema", "sdk", "kind", "description", "identity", "sources", "includes",
    "icon", "presetDefaults", "dryParameter"], "machine.json")
  require(intField(machine, "schema") == 1, "unknown machine.json schema")
  let sdkVersion = stringField(machine, "sdk")
  let versionParts = sdkVersion.split('.')
  require(versionParts.len == 2 and versionParts[0].len > 0 and versionParts[1].len > 0,
    "machine.json sdk must be <major>.<minor>")
  for part in versionParts:
    require(part.allCharsInSet({'0'..'9'}), "machine.json sdk must be <major>.<minor>")
  require(versionParts[0] == "1" and versionParts[1].parseInt <= 2,
    "machine.json targets unsupported SDK: " & sdkVersion)
  let kindText = stringField(machine, "kind")
  let kind = parseMachineKind(kindText)
  let description = stringField(machine, "description")
  require(description.len > 0 and description.len <= 160, "machine description is 1..160 characters")
  let page = validateIdentity(machine, kind)
  if kind != mkSynth:
    for key in ["sources", "includes"]:
      if machine.hasKey(key):
        require(machine[key].kind == JArray and machine[key].len == 0,
          "sample engines and effects compile one source file")
  for key in ["sources", "includes"]:
    if machine.hasKey(key):
      require(machine[key].kind == JArray, key & " must be an array")
      for item in machine[key]:
        require(item.kind == JString, key & " entries must be strings")
        let relative = item.getStr
        require(not relative.isAbsolute and ".." notin relative.split({'/', '\\'}),
          "machine paths must stay inside the machine folder: " & relative)
        require(fileExists(project.root / relative) or dirExists(project.root / relative),
          "machine path does not exist: " & relative)
  if machine.hasKey("presetDefaults"):
    let defaults = machine["presetDefaults"]
    allowedKeys(defaults, ["amp"], "presetDefaults")
    if defaults.hasKey("amp"):
      let amp = defaults["amp"]
      allowedKeys(amp, ["attack", "decay", "release", "sustain"], "amp defaults")
      for _, value in amp:
        require(value.kind == JInt and value.getInt in 0 .. 32767, "invalid amp default")
  let definitionResult = validateDefinition(definition, kind, page)
  require(stringField(definition, "id") == project.id,
    "definition.json id must equal machineId: " & project.id)
  var spec = MachineSpec(
    project: project,
    machine: machine,
    definition: definition,
    kind: kind,
    name: definitionResult.name,
    display: definitionResult.display,
    hasAnalysis: definitionResult.hasAnalysis,
    hasPadSettings: definitionResult.hasPadSettings,
    hasDrumControls: definitionResult.hasDrumControls,
    hasBuffer: definitionResult.hasBuffer,
    hasTransport: definitionResult.hasTransport,
    dryParameter: definitionResult.dryParameter,
  )
  if machine.hasKey("dryParameter"):
    require(kind == mkEffect, "dryParameter names a normalized control on an effect")
    let dry = stringField(machine, "dryParameter")
    var index = -1
    for position in 0 ..< definition["parameters"].len:
      let parameter = definition["parameters"][position]
      if stringField(parameter, "id") == dry:
        index = position
        break
    require(index >= 0, "dryParameter must name a declared control")
    let mapping = definition["parameters"][index]["mapping"]
    require(stringField(mapping, "kind") == "linear" and numberField(mapping, "minimum") == 0 and
      numberField(mapping, "maximum") == 1, "dryParameter must map linearly from 0 to 1")
    spec.dryParameter = index
  spec.project.kind = kind
  validateSource(if sourceText.len == 0: readFile(project.source) else: sourceText)
  spec

proc expectedFrameBytes*(display: DisplayShape): int =
  let pathBytes = if display.paths == 0: 4 else: 4 + display.points * 8
  let pathArray = (if display.paths == 0: 1 else: display.paths) * pathBytes
  let textArray = (if display.texts == 0: 1 else: display.texts) * 36
  pathArray + display.nodes * 28 + textArray + 4 * 8

proc validateMeasurements*(spec: var MachineSpec; measurements: Measurements) =
  ## Refuse a machine whose measured storage contradicts its declared layout.
  case spec.kind
  of mkSynth:
    require(measurements.voiceBytes >= 4 and measurements.voiceBytes mod 4 == 0,
      "Voice must occupy at least one whole word")
    require(measurements.voiceAlignment in [4, 8, 16], "Voice alignment must be 4, 8 or 16")
    require(measurements.displayBytes >= 4 and measurements.displayAlignment in [4, 8, 16],
      "DisplayState must occupy aligned whole words")
    require(measurements.frameBytes == expectedFrameBytes(spec.display),
      "the machine Frame does not match resources.display")
    spec.definition["resources"]["voiceBytes"] = %measurements.voiceBytes
    spec.definition["resources"]["voiceAlignment"] = %measurements.voiceAlignment
    spec.definition["resources"]["sharedBytes"] = %(if measurements.sharedBytes == 1: 0 else: measurements.sharedBytes)
    spec.definition["resources"]["display"]["stateBytes"] = %measurements.displayBytes
    spec.definition["resources"]["display"]["stateAlignment"] = %measurements.displayAlignment
  of mkSample:
    require(measurements.voiceBytes >= 4, "sample Voice is empty")
    if spec.hasAnalysis:
      require(measurements.preparationBytes > 0, "Preparation is empty for a machine with sampleAnalysis")
  of mkEffect:
    let limit = if spec.hasBuffer: 472 else: 476
    require(measurements.stateBytes > 0 and measurements.stateBytes <= limit and
      measurements.stateBytes mod 4 == 0,
      "effect State must be whole words within the SDK limit of " & $limit & " bytes")
    require(measurements.stateAlignment == 4, "effect State alignment must be 4")
