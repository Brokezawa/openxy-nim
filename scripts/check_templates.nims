## Copy every template into a scratch project, link the local openxy, and
## exercise the tasks without touching the source templates.

import std/[os, strutils]

import openxy/paths
import openxy/util/fscompat

type
  TemplateCase = object
    folder: string
    id: string
    kind: string
    generated: seq[string]

const cases = [
  TemplateCase(folder: "synth", id: "mysynth", kind: "synth",
    generated: @["core.h", "engine.cpp", "display.h", "generated/wrapper.nim", "machine.json"]),
  TemplateCase(folder: "synth-eight", id: "mysynth8", kind: "synth",
    generated: @["core.h", "engine.cpp", "display.h", "generated/wrapper.nim", "machine.json"]),
  TemplateCase(folder: "sample", id: "mysample", kind: "sample",
    generated: @["sample.h", "sample.cpp", "generated/wrapper.nim", "machine.json"]),
  TemplateCase(folder: "effect", id: "myeffect", kind: "effect",
    generated: @["fx.h", "fx.cpp", "generated/wrapper.nim", "machine.json"]),
]

let scratch = getTempDir() / "openxy-template-check"
var fullCheck = false
for argument in commandLineParams():
  if argument == "--full":
    fullCheck = true

proc stripComment(line: string): string =
  let comment = line.find('#')
  if comment >= 0: line[0 ..< comment] else: line

proc hasToken(line, token: string): bool =
  var start = 0
  while true:
    let position = line.find(token, start)
    if position < 0:
      return false
    let before = if position == 0: '\0' else: line[position - 1]
    let after = if position + token.len >= line.len: '\0' else: line[position + token.len]
    if before notin {'A'..'Z', 'a'..'z', '0'..'9', '_'} and
        after notin {'A'..'Z', 'a'..'z', '0'..'9', '_'}:
      return true
    start = position + token.len
  false

proc scanSource(path: string) =
  let lines = readFile(path).splitLines
  for index, line in lines:
    let code = stripComment(line)
    for token in ["cast", "ptr", "addr", "unsafeAddr", "UncheckedArray"]:
      if code.hasToken(token):
        raise newException(ValueError,
          path & ":" & $(index + 1) & " uses unsafe token " & token)

proc checkTemplateSources() =
  for folder in ["synth", "synth-eight", "sample", "effect", "extension"]:
    let source = templatesRoot / folder / "src"
    for path in walkDirRec(source):
      if path.endsWith(".nim"):
        scanSource(path)

proc run(command: string) =
  echo "Running: ", command
  exec command

proc prepare(item: TemplateCase): string =
  let project = scratch / item.folder
  copyDirCompat(templatesRoot / item.folder, project)
  if dirExists(project / "build"):
    removeDirCompat(project / "build")
  ensureDir(project / "deps")
  let link = project / "deps" / "openxy"
  when defined(windows):
    run "cmd /c mklink /J " & quoteShell(link) & " " & quoteShell(openxyRoot)
  else:
    run "ln -s " & quoteShell(openxyRoot) & " " & quoteShell(link)
  project

proc exercise(item: TemplateCase; project: string) =
  let before = readFile(project / "definition.json")
  run "cd " & quoteShell(project) & " && nim test --skipParentCfg:on"
  run "cd " & quoteShell(project) & " && nim gen --skipParentCfg:on"
  if readFile(project / "definition.json") != before:
    raise newException(ValueError, "the generator rewrote " & item.folder & "/definition.json")
  let generated = project / "build" / item.kind / item.id
  for relative in item.generated:
    if not fileExists(generated / relative):
      raise newException(IOError, "template did not generate " & item.folder & "/" & relative)
  let machineJson = readFile(generated / "machine.json")
  if not machineJson.contains("\"sdk\": \"1.6\""):
    raise newException(ValueError, item.folder & " did not generate SDK 1.6 metadata")
  if machineJson.contains("\"identity\""):
    raise newException(ValueError, item.folder & " still generated machine.json identity")
  if item.kind == "sample" and
      not machineJson.contains("\"base\": \"drumSampler\""):
    raise newException(ValueError, "sample template did not generate its drumSampler base")
  if fullCheck:
    case item.kind
    of "synth":
      run "cd " & quoteShell(project) & " && nim preview --skipParentCfg:on"
      if not dirExists(project / "build" / "out" / item.id / "sdkPreview"):
        raise newException(IOError, "preview did not produce its output folder")
      run "cd " & quoteShell(project) & " && nim compile --skipParentCfg:on"
    of "sample":
      run "cd " & quoteShell(project) & " && nim compile --skipParentCfg:on"
    else:
      # Effects need a synth or sample in the collection for the stock startup
      # table; the collection acceptance is exercised from the repository.
      echo "Skipping standalone effect compile; collection acceptance covers it."
    if item.kind in ["synth", "sample"] and
        not dirExists(project / "build" / "out" / item.id / "sdkCompile"):
      raise newException(IOError, "device compile did not produce its output folder")

if dirExists(scratch):
  removeDirCompat(scratch)
ensureDir(scratch)

checkTemplateSources()

# The lint must reject an unsafe source token.
let unsafeFixture = scratch / "unsafe_fixture.nim"
writeFile(unsafeFixture, "let value = cast[int32](1)\n")
var unsafeRejected = false
try:
  scanSource(unsafeFixture)
except ValueError:
  unsafeRejected = true
if not unsafeRejected:
  raise newException(ValueError, "the unsafe-token lint accepted a cast")

for item in cases:
  let project = prepare(item)
  exercise(item, project)

# The extension template uses the parallel extension build path.
let extensionCase = TemplateCase(folder: "extension", id: "mynotify",
  kind: "extension", generated: @[])
let extensionProject = prepare(extensionCase)
run "cd " & quoteShell(extensionProject) & " && nim test --skipParentCfg:on"
run "cd " & quoteShell(extensionProject) & " && nim gen --skipParentCfg:on"
let extensionGenerated = extensionProject / "build" / "extension" / "mynotify"
for relative in ["extension.json", "extension.cpp"]:
  if not fileExists(extensionGenerated / relative):
    raise newException(IOError, "extension template did not generate " & relative)
let extensionAdapter = readFile(extensionGenerated / "extension.cpp")
if not extensionAdapter.contains("with_queued_control"):
  raise newException(ValueError, "extension adapter did not select queued_control")
if extensionAdapter.contains("with_context"):
  raise newException(ValueError, "extension adapter selected an unset hook")
if fullCheck:
  let synthGenerated = scratch / "synth" / "build" / "synth" / "mysynth"
  let configPath = extensionProject / "config.nims"
  writeFile(configPath,
    readFile(configPath).replace("machine = \"\"",
      "machine = \"" & synthGenerated & "\""))
  run "cd " & quoteShell(extensionProject) & " && nim compile --skipParentCfg:on"
  if not dirExists(extensionProject / "build" / "out" / "mynotify" / "sdkCompile"):
    raise newException(IOError, "extension device compile did not produce its output folder")

# A broken definition must fail during validation, not during the SDK build.
let synthProject = scratch / "synth"
let definitionPath = synthProject / "definition.json"
let original = readFile(definitionPath)
writeFile(definitionPath, original.replace("\"id\": \"mysynth\"", "\"id\": \"notmysynth\""))
var failed = false
try:
  run "cd " & quoteShell(synthProject) & " && nim gen --skipParentCfg:on"
except OSError:
  failed = true
writeFile(definitionPath, original)
if not failed:
  raise newException(ValueError, "a mismatched definition id did not fail generation")

# A measured Frame that disagrees with definition.json must fail generation.
let sourcePath = synthProject / "src" / "mysynth.nim"
let sourceText = readFile(sourcePath)
writeFile(sourcePath, sourceText.replace("Frame[2, 64, 2, 0, 16]", "Frame[1, 8, 2, 0, 16]"))
var frameFailed = false
try:
  run "cd " & quoteShell(synthProject) & " && nim gen --skipParentCfg:on"
except OSError:
  frameFailed = true
writeFile(sourcePath, sourceText)
if not frameFailed:
  raise newException(ValueError, "a mismatched Frame did not fail generation")

removeDirCompat(scratch)
echo "Template checks passed."
