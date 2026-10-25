## Materialize an SDK machine folder from a validated Nim machine.

import std/[json, os, strutils]

import openxy/kind
import openxy/util/fscompat
import openxy/util/project
import openxy/util/validate

proc cppStorage(name: string; bytes, alignment: int; extra = ""): string =
  result = "struct alignas(" & $alignment & ") " & name & " {\n"
  if bytes > 0:
    result.add "    unsigned char storage[" & $bytes & "];\n"
  result.add "};\n"
  result.add extra

proc writeText(path, content: string) =
  ensureDir(path.parentDir)
  writeFile(path, content)

proc copyPath(source, destination: string) =
  if dirExists(source):
    if not dirExists(destination):
      copyDirCompat(source, destination)
  else:
    ensureDir(destination.parentDir)
    copyFileCompat(source, destination)

proc writeVendor(directory: string) =
  let vendor = directory / "vendor" / "openxy"
  ensureDir(vendor)
  let nimbase = nimbasePath()
  if not fileExists(nimbase):
    raise newException(IOError, "nimbase.h not found next to the active nim compiler: " & nimbase)
  copyFileCompat(nimbase, vendor / "nimbase.h")
  writeText(vendor / "openxy_nimbase.h", """
#pragma once
#define HAVE_STDINT_H
#include "nimbase.h"
#include "warnings.hpp"
""")
  writeText(vendor / "warnings.hpp", """
#pragma once
#if defined(__GNUC__)
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wunused-variable"
#pragma GCC diagnostic ignored "-Wunused-function"
#pragma GCC diagnostic ignored "-Wsign-compare"
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#endif
""")
  writeText(directory / "string.h", """
#pragma once
#include <stddef.h>
extern "C" {
void* memset(void* destination, int value, size_t size);
void* memcpy(void* destination, const void* source, size_t size);
}
""")
  writeText(directory / "limits.h", """
#pragma once
#define CHAR_BIT 8
#define SCHAR_MIN (-128)
#define SCHAR_MAX 127
#define UCHAR_MAX 255
#define SHRT_MIN (-32768)
#define SHRT_MAX 32767
#define USHRT_MAX 65535
#define INT_MIN (-2147483647 - 1)
#define INT_MAX 2147483647
#define UINT_MAX 4294967295U
#define LONG_MIN (-2147483647L - 1L)
#define LONG_MAX 2147483647L
#define ULONG_MAX 4294967295UL
#define LLONG_MIN (-9223372036854775807LL - 1LL)
#define LLONG_MAX 9223372036854775807LL
#define ULLONG_MAX 18446744073709551615ULL
""")

proc writeMachineJson(spec: MachineSpec; directory: string) =
  var machine = spec.machine
  if spec.kind == mkSynth:
    if not machine.hasKey("includes"):
      machine["includes"] = newJArray()
    var includes = machine["includes"]
    var found = false
    for item in includes:
      if item.kind == JString and item.getStr == "vendor/openxy":
        found = true
    if not found:
      includes.add %"vendor/openxy"
    machine["includes"] = includes
  writeText(directory / "machine.json", pretty(machine) & "\n")

proc writeDefinition(spec: MachineSpec; directory: string) =
  writeText(directory / "definition.json", pretty(spec.definition) & "\n")

proc writeSynthHeaders(spec: MachineSpec; measurements: Measurements; directory: string) =
  let sharedBytes = if measurements.sharedBytes == 1: 0 else: measurements.sharedBytes
  var core = "#pragma once\n#include <opxy/audio.hpp>\n\nnamespace " & spec.project.id & " {\n"
  core.add cppStorage("Voice", measurements.voiceBytes, measurements.voiceAlignment)
  core.add cppStorage("Shared", sharedBytes, if sharedBytes == 0: 1 else: measurements.voiceAlignment)
  core.add "\nvoid initialize(Voice&, Shared&, opxy::u32);\n"
  core.add "void start(Voice&, Shared&, opxy::u32);\n"
  core.add "void destroy(Voice&, Shared&, opxy::u32);\n"
  core.add "void render(Voice&, Shared&, opxy::u32, opxy::Output, opxy::Parameters, opxy::Pitch);\n"
  core.add "}\n"
  writeText(directory / "core.h", core)

  var display = "#pragma once\n#include <opxy/draw.hpp>\n\nnamespace " & spec.project.id & " {\n"
  display.add "using Frame = opxy::draw::Frame<" & $spec.display.paths & ", " & $spec.display.points &
    ", " & $spec.display.nodes & ", " & $spec.display.texts & ", " & $spec.display.palette & ">;\n"
  display.add cppStorage("DisplayState", measurements.displayBytes, measurements.displayAlignment)
  display.add "\nvoid display_reset(DisplayState&);\n"
  display.add "void display(DisplayState&, const opxy::draw::Input&, Frame&);\n"
  display.add "}\n"
  writeText(directory / "display.h", display)
  writeText(directory / "engine.cpp", "#include \"core.h\"\n#include \"generated/machine.cpp\"\n")
  writeText(directory / "display.cpp", "#include \"display.h\"\n")

proc writeSampleHeaders(spec: MachineSpec; measurements: Measurements; directory: string) =
  var header = "#pragma once\n#include <opxy/sample_engine.hpp>\n"
  if spec.hasAnalysis:
    header.add "#include <opxy/sample_analysis.hpp>\n"
  header.add "\nnamespace " & spec.project.id & " {\n"
  header.add cppStorage("Voice", measurements.voiceBytes, measurements.voiceAlignment)
  if spec.hasAnalysis:
    header.add cppStorage("Preparation", measurements.preparationBytes, measurements.preparationAlignment)
  header.add "\nvoid initialize(Voice&, const opxy::SampleView&);\n"
  header.add "void start(Voice&);\n"
  header.add "void render_sample(Voice&, const opxy::SampleBlock&);\n"
  if spec.hasPadSettings:
    header.add "opxy::PadSettings sample_defaults();\n"
    header.add "opxy::PadSettings sample_assign(const opxy::SampleAssignment&);\n"
  if spec.hasDrumControls:
    header.add "void drum_control(opxy::PadSettings&, const opxy::DrumControl&);\n"
    header.add "void drum_panel(opxy::PadSettings, const opxy::SampleRegion&, opxy::Parameters, opxy::DrumPanel&);\n"
  if spec.hasAnalysis:
    header.add "opxy::u32 analysis_words(const opxy::SampleView&);\n"
    header.add "bool prepare_begin(Preparation&, const opxy::SampleView&, opxy::u32*, opxy::u32);\n"
    header.add "opxy::u32 prepare_step(Preparation&, opxy::u32, opxy::u32&);\n"
    header.add "bool prepared(const Preparation&, opxy::SampleAnalysis&);\n"
  header.add "}\n"
  writeText(directory / "sample.h", header)
  writeText(directory / "sample.cpp", "#include \"sample.h\"\n#include \"generated/machine.cpp\"\n")

proc writeEffectHeaders(spec: MachineSpec; measurements: Measurements; directory: string) =
  var header = "#pragma once\n#include <opxy/effect.hpp>\n\nnamespace " & spec.project.id & " {\n"
  header.add cppStorage("State", measurements.stateBytes, 4)
  header.add "\nvoid initialize(State&);\n"
  let audio = "opxy::Channel, opxy::Channel, opxy::Parameters"
  if not spec.hasBuffer and not spec.hasTransport:
    header.add "void process(State&, " & audio & ");\n"
  elif spec.hasBuffer and not spec.hasTransport:
    header.add "void process(State&, opxy::Buffer, " & audio & ");\n"
  elif not spec.hasBuffer and spec.hasTransport:
    header.add "void process(State&, const opxy::Transport&, " & audio & ");\n"
  else:
    header.add "void process(State&, opxy::Buffer, const opxy::Transport&, " & audio & ");\n"
  header.add "}\n"
  writeText(directory / "fx.h", header)
  writeText(directory / "fx.cpp", "#include \"fx.h\"\n#include \"generated/machine.cpp\"\n")

proc writeShim(directory: string) =
  writeText(directory / "generated" / "machine.cpp",
    "#include \"../vendor/openxy/machine.cpp\"\n")

proc synthWrapper(spec: MachineSpec; measurements: Measurements): string =
  let module = spec.project.sourceModule
  let sharedBytes = if measurements.sharedBytes == 1: 0 else: measurements.sharedBytes
  result = "import std/assertions\nimport openxy\nimport " & module & "\n\n"
  result.add "type\n"
  result.add "  CVoice {.importcpp: \"Voice\", header: \"core.h\".} = object\n"
  result.add "  CShared {.importcpp: \"Shared\", header: \"core.h\".} = object\n"
  result.add "  CDisplayState {.importcpp: \"DisplayState\", header: \"display.h\".} = object\n"
  result.add "  CFrame {.importcpp: \"Frame\", header: \"display.h\".} = object\n"
  result.add "  ConstInput {.importcpp: \"const opxy::draw::Input&\", header: \"display.h\".} = object\n"
  result.add "  COutput {.importcpp: \"opxy::Output\", header: \"opxy/audio.hpp\".} = object\n"
  result.add "  CParameters {.importcpp: \"opxy::Parameters\", header: \"opxy/audio.hpp\".} = object\n"
  result.add "  CPitch {.importcpp: \"opxy::Pitch\", header: \"opxy/audio.hpp\".} = object\n\n"
  result.add "static:\n"
  result.add "  doAssert sizeof(" & module & ".Voice) == " & $measurements.voiceBytes & "\n"
  result.add "  doAssert alignof(" & module & ".Voice) == " & $measurements.voiceAlignment & "\n"
  result.add "  doAssert sizeof(" & module & ".Shared) == " &
    (if sharedBytes == 0: "1" else: $sharedBytes) & "\n"
  result.add "  doAssert sizeof(" & module & ".DisplayState) == " & $measurements.displayBytes & "\n"
  result.add "  doAssert sizeof(" & module & ".Frame) == " & $measurements.frameBytes & "\n\n"
  result.add """
proc initialize(voice: var CVoice; shared: var CShared; owner: uint32)
    {.exportcpp: "initialize", raises: [].} =
  mysynth.initialize(cast[ptr mysynth.Voice](addr voice)[],
    cast[ptr mysynth.Shared](addr shared)[], VoiceId(owner))

proc start(voice: var CVoice; shared: var CShared; owner: uint32)
    {.exportcpp: "start", raises: [].} =
  mysynth.start(cast[ptr mysynth.Voice](addr voice)[],
    cast[ptr mysynth.Shared](addr shared)[], VoiceId(owner))

proc destroy(voice: var CVoice; shared: var CShared; owner: uint32)
    {.exportcpp: "destroy", raises: [].} =
  mysynth.destroy(cast[ptr mysynth.Voice](addr voice)[],
    cast[ptr mysynth.Shared](addr shared)[], VoiceId(owner))

proc render(voice: var CVoice; shared: var CShared; owner: uint32;
            output: COutput; parameters: CParameters; pitch: CPitch)
    {.exportcpp: "render", raises: [].} =
  var localOutput: array[openxy.BlockFrames, Q31]
  let rawOutput = cast[ptr UncheckedArray[Q31]](output)
  for index in 0 ..< openxy.BlockFrames:
    localOutput[index] = rawOutput[index]
  mysynth.render(cast[ptr mysynth.Voice](addr voice)[],
    cast[ptr mysynth.Shared](addr shared)[], VoiceId(owner), localOutput,
    toOpenArray(cast[ptr UncheckedArray[Q31]](parameters), 0, openxy.ParameterSlots - 1),
    toOpenArray(cast[ptr UncheckedArray[PhaseIncrement]](pitch), 0, openxy.BlockFrames - 1))
  for index in 0 ..< openxy.BlockFrames:
    rawOutput[index] = localOutput[index]

proc display_reset(state: var CDisplayState) {.exportcpp: "display_reset", raises: [].} =
  mysynth.displayReset(cast[ptr mysynth.DisplayState](addr state)[])

proc display(state: var CDisplayState; input: ConstInput; frame: var CFrame)
    {.exportcpp: "display", raises: [].} =
  let inputValue = cast[ptr openxy.Input](unsafeAddr input)[]
  mysynth.display(cast[ptr mysynth.DisplayState](addr state)[], inputValue,
    cast[ptr mysynth.Frame](addr frame)[])
"""
  result = result.replace("mysynth.", module & ".")

proc sampleWrapper(spec: MachineSpec; measurements: Measurements): string =
  let module = spec.project.sourceModule
  result = "import std/assertions\nimport std/options\nimport openxy\nimport " & module & "\n\n"
  result.add "type\n"
  result.add "  CVoice {.importcpp: \"Voice\", header: \"sample.h\".} = object\n"
  result.add "  CConstSampleView {.importcpp: \"const opxy::SampleView&\", header: \"opxy/sample.hpp\".} = object\n"
  result.add "  CConstSampleBlock {.importcpp: \"const opxy::SampleBlock&\", header: \"opxy/sample_engine.hpp\".} = object\n"
  result.add "  CConstSampleAssignment {.importcpp: \"const opxy::SampleAssignment&\", header: \"opxy/sample_engine.hpp\".} = object\n"
  result.add "  CConstDrumControl {.importcpp: \"const opxy::DrumControl&\", header: \"opxy/sample_engine.hpp\".} = object\n"
  result.add "  CConstSampleRegion {.importcpp: \"const opxy::SampleRegion&\", header: \"opxy/sample_engine.hpp\".} = object\n"
  result.add "  CParameters {.importcpp: \"opxy::Parameters\", header: \"opxy/audio.hpp\".} = object\n"
  result.add "  CDrumPanel {.importcpp: \"opxy::DrumPanel\", header: \"opxy/sample_engine.hpp\".} = object\n"
  if spec.hasAnalysis:
    result.add "  CPreparation {.importcpp: \"Preparation\", header: \"sample.h\".} = object\n"
    result.add "  ConstPreparation {.importcpp: \"const Preparation&\", header: \"sample.h\".} = object\n"
    result.add "  CSampleAnalysis {.importcpp: \"opxy::SampleAnalysis\", header: \"opxy/sample_analysis.hpp\".} = object\n"
  result.add """
type
  CSampleBlock = object
    output: ptr UncheckedArray[Q31]
    parameters: ptr UncheckedArray[Q31]
    pitch: ptr UncheckedArray[PhaseIncrement]
    transport: Transport
    region: SampleRegion
    analysis: ptr SampleAnalysis
    settings: PadSettings
    outputChannels: uint32
    trackTranspose: int32
    drumTranspose: int32

static:
  when sizeof(pointer) == 8:
    doAssert sizeof(CSampleBlock) == 80
  else:
    doAssert sizeof(CSampleBlock) == 64
"""
  result.add "  doAssert sizeof(" & module & ".Voice) == " & $measurements.voiceBytes & "\n"
  if spec.hasAnalysis:
    result.add "  doAssert sizeof(" & module & ".Preparation) == " & $measurements.preparationBytes & "\n"
  result.add """

proc initialize(voice: var CVoice; sample: CConstSampleView)
    {.exportcpp: "initialize", raises: [].} =
  mysynth.initialize(cast[ptr mysynth.Voice](addr voice)[],
    cast[ptr SampleView](unsafeAddr sample)[])

proc start(voice: var CVoice) {.exportcpp: "start", raises: [].} =
  mysynth.start(cast[ptr mysynth.Voice](addr voice)[])

proc render_sample(voice: var CVoice; sampleBlock: CConstSampleBlock)
    {.exportcpp: "render_sample", raises: [].} =
  let raw = cast[ptr CSampleBlock](unsafeAddr sampleBlock)[]
  var analysis = none(ptr SampleAnalysis)
  if raw.analysis != nil:
    analysis = some(raw.analysis)
  var sampleBlock = SampleBlock(
    output: initMutableAudioView(cast[ptr UncheckedArray[Q31]](raw.output),
      int(raw.outputChannels) * openxy.BlockFrames),
    parameters: initAudioView(cast[ptr UncheckedArray[Q31]](raw.parameters),
      openxy.ParameterSlots),
    pitch: initAudioView(cast[ptr UncheckedArray[PhaseIncrement]](raw.pitch),
      openxy.BlockFrames),
    transport: raw.transport,
    region: raw.region,
    analysis: analysis,
    settings: raw.settings,
    outputChannels: raw.outputChannels,
    trackTranspose: raw.trackTranspose,
    drumTranspose: raw.drumTranspose,
  )
  mysynth.renderSample(cast[ptr mysynth.Voice](addr voice)[], sampleBlock)
"""
  if spec.hasPadSettings:
    result.add """
proc sample_defaults(): uint16 {.exportcpp: "sample_defaults", raises: [].} =
  uint16(mysynth.sampleDefaults())

proc sample_assign(assignment: CConstSampleAssignment): uint16
    {.exportcpp: "sample_assign", raises: [].} =
  uint16(mysynth.sampleAssign(
    cast[ptr SampleAssignment](unsafeAddr assignment)[]))
"""
  if spec.hasDrumControls:
    result.add """
proc drum_control(value: var uint16; event: CConstDrumControl)
    {.exportcpp: "drum_control", raises: [].} =
  var settings = PadSettings(value)
  mysynth.drumControl(settings, cast[ptr DrumControl](unsafeAddr event)[])
  value = uint16(settings)

proc drum_panel(value: uint16; saved: CConstSampleRegion; parameters: CParameters;
                panel: var CDrumPanel) {.exportcpp: "drum_panel", raises: [].} =
  mysynth.drumPanel(PadSettings(value),
    cast[ptr SampleRegion](unsafeAddr saved)[],
    toOpenArray(cast[ptr UncheckedArray[Q31]](parameters), 0, openxy.ParameterSlots - 1),
    cast[ptr DrumPanel](addr panel)[])
"""
  if spec.hasAnalysis:
    result.add """
proc analysis_words(sample: CConstSampleView): uint32
    {.exportcpp: "analysis_words", raises: [].} =
  mysynth.analysisWords(cast[ptr SampleView](unsafeAddr sample)[])

proc prepare_begin(job: var CPreparation; sample: CConstSampleView;
                   storage: ptr uint32; words: uint32): bool
    {.exportcpp: "prepare_begin", raises: [].} =
  mysynth.prepareBegin(cast[ptr Preparation](addr job)[],
    cast[ptr SampleView](unsafeAddr sample)[], storage, words)

proc prepare_step(job: var CPreparation; frames: uint32; cursor: var uint32): uint32
    {.exportcpp: "prepare_step", raises: [].} =
  uint32(mysynth.prepareStep(cast[ptr Preparation](addr job)[], frames, cursor))

proc prepared(job: ConstPreparation; analysis: var CSampleAnalysis): bool
    {.exportcpp: "prepared", raises: [].} =
  mysynth.prepared(cast[ptr Preparation](unsafeAddr job)[],
    cast[ptr SampleAnalysis](addr analysis)[])
"""
  result = result.replace("mysynth.", module & ".")

proc effectWrapper(spec: MachineSpec; measurements: Measurements): string =
  let module = spec.project.sourceModule
  result = "import std/assertions\nimport openxy\nimport " & module & "\n\n"
  result.add "type\n"
  result.add "  CState {.importcpp: \"State\", header: \"fx.h\".} = object\n"
  result.add "  CChannel {.importcpp: \"opxy::Channel\", header: \"opxy/effect.hpp\".} = object\n"
  result.add "  CBuffer {.importcpp: \"opxy::Buffer\", header: \"opxy/effect.hpp\".} = object\n"
  result.add "    words: ptr UncheckedArray[Q31]\n"
  result.add "    count: uint32\n"
  result.add "  ConstTransport {.importcpp: \"const opxy::Transport&\", header: \"opxy/transport.hpp\".} = object\n"
  result.add "  CParameters {.importcpp: \"opxy::Parameters\", header: \"opxy/audio.hpp\".} = object\n\n"
  result.add "static:\n"
  result.add "  doAssert sizeof(" & module & ".State) == " & $measurements.stateBytes & "\n\n"
  result.add """
proc makeBlock(left, right: CChannel; parameters: CParameters;
               buffer: Buffer; transport: Transport): EffectBlock =
  EffectBlock(
    left: initMutableAudioView(cast[ptr UncheckedArray[Q31]](left), openxy.BlockFrames),
    right: initMutableAudioView(cast[ptr UncheckedArray[Q31]](right), openxy.BlockFrames),
    parameters: initAudioView(cast[ptr UncheckedArray[Q31]](parameters),
      openxy.ParameterSlots),
    buffer: buffer,
    transport: transport,
  )

proc initialize(state: var CState) {.exportcpp: "initialize", raises: [].} =
  mysynth.initialize(cast[ptr mysynth.State](addr state)[])

"""
  if spec.hasBuffer and spec.hasTransport:
    result.add """
proc process(state: var CState; buffer: CBuffer; transport: ConstTransport;
             left, right: CChannel; parameters: CParameters)
    {.exportcpp: "process", raises: [].} =
  mysynth.process(cast[ptr mysynth.State](addr state)[], makeBlock(left, right, parameters,
    Buffer(words: buffer.words, count: buffer.count),
    cast[ptr Transport](unsafeAddr transport)[]))
"""
  elif spec.hasBuffer:
    result.add """
proc process(state: var CState; buffer: CBuffer; left, right: CChannel;
             parameters: CParameters) {.exportcpp: "process", raises: [].} =
  mysynth.process(cast[ptr mysynth.State](addr state)[], makeBlock(left, right, parameters,
    Buffer(words: buffer.words, count: buffer.count), Transport()))
"""
  elif spec.hasTransport:
    result.add """
proc process(state: var CState; transport: ConstTransport; left, right: CChannel;
             parameters: CParameters) {.exportcpp: "process", raises: [].} =
  mysynth.process(cast[ptr mysynth.State](addr state)[], makeBlock(left, right, parameters,
    Buffer(), cast[ptr Transport](unsafeAddr transport)[]))
"""
  else:
    result.add """
proc process(state: var CState; left, right: CChannel; parameters: CParameters)
    {.exportcpp: "process", raises: [].} =
  mysynth.process(cast[ptr mysynth.State](addr state)[], makeBlock(left, right, parameters,
    Buffer(), Transport()))
"""
  result = result.replace("mysynth.", module & ".")

proc prepare*(spec: var MachineSpec; measurements: Measurements): string =
  validateMeasurements(spec, measurements)
  let directory = spec.project.machineDir
  if dirExists(directory):
    removeDirCompat(directory)
  ensureDir(directory)
  writeDefinition(spec, directory)
  let panel = spec.project.root / "panel.svg.fragment"
  if fileExists(panel):
    copyPath(panel, directory / "panel.svg.fragment")
  elif spec.kind == mkSynth:
    raise newException(IOError, "synth machines need panel.svg.fragment")
  for key in ["sources", "includes"]:
    if spec.machine.hasKey(key):
      for item in spec.machine[key]:
        let relative = item.getStr
        copyPath(spec.project.root / relative, directory / relative)
  writeMachineJson(spec, directory)
  writeVendor(directory)
  writeShim(directory)
  case spec.kind
  of mkSynth:
    writeSynthHeaders(spec, measurements, directory)
    writeText(directory / "generated" / "wrapper.nim", synthWrapper(spec, measurements))
  of mkSample:
    writeSampleHeaders(spec, measurements, directory)
    writeText(directory / "generated" / "wrapper.nim", sampleWrapper(spec, measurements))
  of mkEffect:
    writeEffectHeaders(spec, measurements, directory)
    writeText(directory / "generated" / "wrapper.nim", effectWrapper(spec, measurements))
  directory


func definitionKey(line: string): tuple[key: string; braced: bool] =
  let stripped = line.strip
  if stripped.startsWith("struct ") or stripped.startsWith("union ") or
      stripped.startsWith("enum ") or stripped.startsWith("class "):
    let firstSpace = stripped.find(' ')
    var name = stripped[firstSpace + 1 .. ^1]
    let stop = name.find({' ', '{', ':'})
    if stop >= 0: name = name[0 ..< stop]
    if name.len > 0 and stripped.contains("{"):
      return ("type_" & name, true)
  elif stripped.startsWith("static ") and stripped.contains(")(") and
      stripped.contains("{"):
    let marker = stripped.find(")(")
    let comma = stripped.rfind(',', 0, marker)
    if comma >= 0 and marker > comma:
      let name = stripped[comma + 1 ..< marker].strip
      if name.len > 0:
        return ("func_" & name, true)
  ("", false)

func safeMacro(value: string): string =
  for character in value:
    if character in {'A'..'Z', 'a'..'z', '0'..'9', '_'}:
      result.add character
    else:
      result.add '_'

proc deduplicateCpp(content: string): string =
  ## Nim emits shared type and inline-helper definitions in every translation
  ## unit. One amalgamation must define each exactly once.
  let lines = content.splitLines
  var seen: seq[string]
  var index = 0
  while index < lines.len:
    let line = lines[index]
    let (key, braced) = definitionKey(line)
    if key.len == 0:
      result.add line
      result.add '\n'
      inc index
      continue
    if key in seen:
      if braced:
        var depth = line.count('{') - line.count('}')
        inc index
        while index < lines.len and depth > 0:
          depth += lines[index].count('{') - lines[index].count('}')
          inc index
      else:
        inc index
      continue
    seen.add key
    let macroName = "OPENXY_AMALGAMATION_" & safeMacro(key)
    result.add "#ifndef " & macroName & "\n#define " & macroName & "\n"
    if braced:
      var depth = line.count('{') - line.count('}')
      result.add line
      result.add '\n'
      inc index
      while index < lines.len and depth > 0:
        depth += lines[index].count('{') - lines[index].count('}')
        result.add lines[index]
        result.add '\n'
        inc index
    else:
      result.add line
      result.add '\n'
      inc index
    result.add "#endif\n"

proc package*(directory: string; cacheText = "") =
  let cachePath = directory / "nimcache" / "wrapper.json"
  if not fileExists(cachePath):
    raise newException(IOError, "generated C++ not found; run `nim gen` before packaging: " & cachePath)
  let cache = parseJson(if cacheText.len == 0: readFile(cachePath) else: cacheText)
  if not cache.hasKey("compile"):
    raise newException(ValueError, "nimcache JSON has no compile list: " & cachePath)
  var amalgamation = "// generated by openxy from the Nim compiler cache\n"
  var count = 0
  for entry in cache["compile"]:
    if entry.kind != JArray or entry.len < 1 or entry[0].kind != JString:
      continue
    let source = entry[0].getStr
    if source.endsWith(".cpp") and fileExists(source):
      amalgamation.add "\n// " & extractFilename(source) & "\n"
      amalgamation.add readFile(source)
      inc count
  if count == 0:
    raise newException(ValueError, "nimcache JSON lists no C++ translation units")
  writeText(directory / "vendor" / "openxy" / "machine.cpp", deduplicateCpp(amalgamation))
  writeText(directory / "generated" / "machine.cpp",
    "#include \"../vendor/openxy/machine.cpp\"\n")
  removeDirCompat(directory / "nimcache")
