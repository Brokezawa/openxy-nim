## Compile the machine once on the host to measure storage declared in Nim.

import std/[os, strutils]

import openxy/kind
import openxy/util/fscompat
import openxy/util/project
import openxy/util/validate

proc probeSource*(spec: MachineSpec): string =
  let module = spec.project.sourceModule
  result = "import " & module & "\n\nstatic:\n"
  case spec.kind
  of mkSynth:
    result.add "  echo \"openxy-measure voice=\", sizeof(Voice), \",\", alignof(Voice)\n"
    result.add "  echo \"openxy-measure shared=\", sizeof(Shared), \",\", alignof(Shared)\n"
    result.add "  echo \"openxy-measure display=\", sizeof(DisplayState), \",\", alignof(DisplayState)\n"
    result.add "  echo \"openxy-measure frame=\", sizeof(Frame), \",\", alignof(Frame)\n"
  of mkSample:
    result.add "  echo \"openxy-measure voice=\", sizeof(Voice), \",\", alignof(Voice)\n"
    result.add "  when declared(Preparation):\n"
    result.add "    echo \"openxy-measure preparation=\", sizeof(Preparation), \",\", alignof(Preparation)\n"
  of mkEffect:
    result.add "  echo \"openxy-measure state=\", sizeof(State), \",\", alignof(State)\n"

proc probeCommand*(spec: MachineSpec; probePath, openxySrc: string): string =
  let nim = findExe("nim")
  if nim.len == 0:
    raise newException(IOError, "nim compiler not found in PATH")
  result = quoteShell(nim) & " check --hints:off --warnings:off --backend:cpp --cpu:arm" &
    " --path:" & quoteShell(openxySrc) &
    " --path:" & quoteShell(spec.project.sourceDir) &
    " " & quoteShell(probePath)

proc parseMeasurements*(spec: MachineSpec; output: string): Measurements =
  var found: seq[string]
  for line in output.splitLines:
    let marker = "openxy-measure "
    let position = line.find(marker)
    if position < 0:
      continue
    let payload = line[position + marker.len .. ^1].strip
    let equals = payload.find('=')
    if equals < 0:
      continue
    let key = payload[0 ..< equals]
    let values = payload[equals + 1 .. ^1].split(',')
    if values.len != 2:
      continue
    let size = values[0].strip.parseInt
    let alignment = values[1].strip.parseInt
    found.add key
    case key
    of "voice":
      result.voiceBytes = size
      result.voiceAlignment = alignment
    of "shared":
      result.sharedBytes = if size == 1 and alignment == 1: 0 else: size
    of "display":
      result.displayBytes = size
      result.displayAlignment = alignment
    of "frame":
      result.frameBytes = size
      result.frameAlignment = alignment
    of "state":
      result.stateBytes = size
      result.stateAlignment = alignment
    of "preparation":
      result.preparationBytes = size
      result.preparationAlignment = alignment
    else:
      discard
  if spec.kind in {mkSynth, mkSample} and "voice" notin found:
    raise newException(ValueError, "the machine does not export a Voice type")
  case spec.kind
  of mkSynth:
    for key in ["shared", "display", "frame"]:
      if key notin found:
        raise newException(ValueError, "the synth does not export " & key)
  of mkSample:
    if spec.hasAnalysis and "preparation" notin found:
      raise newException(ValueError, "sampleAnalysis requires an exported Preparation type")
  of mkEffect:
    if "state" notin found:
      raise newException(ValueError, "the effect does not export a State type")

proc measure*(spec: MachineSpec; probePath, openxySrc: string): Measurements =
  ## Run the probe with `nim check`; the build folder keeps no nimcache.
  ensureDir(probePath.parentDir)
  writeFile(probePath, probeSource(spec))
  let (output, code) = gorgeEx(probeCommand(spec, probePath, openxySrc))
  if code != 0:
    raise newException(ValueError, "machine measurement failed:\n" & output)
  parseMeasurements(spec, output)
