import std/[assertions, options]

import openxy
import openxy/testkit
import mysample

const TotalFrames = 64

var source: array[TotalFrames * 2, int16]
for index in 0 ..< source.len:
  source[index] = int16((index mod 19) * 1200 - 10000)

let view = SampleView(
  data: cast[ptr UncheckedArray[int16]](addr source),
  frames: TotalFrames,
  rate: 44100,
  channels: 2,
)
let region = SampleRegion(
  begin: 0,
  `end`: TotalFrames,
  level: Q27(0x8000000),
  reverse: false,
  pitchCents: Cents(0),
)

block playback:
  var voice: Voice
  initialize(voice, view)
  start(voice)
  var output: array[StereoOutputWords, Q31]
  var parameters = zeroParameters()
  parameters[2] = Q31(0x40000000)
  var pitch = zeroPitch()
  let sampleBlock = SampleBlock(
    output: initMutableAudioView(cast[ptr UncheckedArray[Q31]](addr output), output.len),
    parameters: initAudioView(cast[ptr UncheckedArray[Q31]](addr parameters),
      parameters.len),
    pitch: initAudioView(cast[ptr UncheckedArray[PhaseIncrement]](addr pitch), pitch.len),
    transport: Transport(bpmX10: 1200, ticks96: 0, playing: true),
    region: region,
    analysis: none(ptr SampleAnalysis),
    settings: PadSettings(0),
    outputChannels: 2,
    trackTranspose: 0,
    drumTranspose: 0,
  )
  renderSample(voice, sampleBlock)
  var nonzero = false
  for sample in output:
    if sample != Q31(0):
      nonzero = true
  doAssert nonzero, "the sample engine should produce audio"
  doAssert not sampleBlock.transport.isEmpty

block pad_services:
  doAssert uint16(sampleDefaults()) == 0
  var settings = PadSettings(0)
  drumControl(settings, DrumControl(knob: 0, direction: 0, pressed: true))
  doAssert uint16(settings) == 1
  var panel: DrumPanel
  drumPanel(settings, region, zeroParameters(), panel)
  doAssert not panel.repeat
  doAssert panel.level == 0x7fffffff'u32
  doAssert sampleAssign(SampleAssignment(replacing: true, previous: PadSettings(7))) ==
    PadSettings(7)
  doAssert sampleAssign(SampleAssignment(replacing: false)) == PadSettings(0)

block analysis_service:
  doAssert analysisWords(view) == 1
  var preparation: Preparation
  var storage: array[1, uint32]
  doAssert prepareBegin(preparation, view, addr storage[0], 1)
  var cursor = 0'u32
  while prepareStep(preparation, 512, cursor) == prepareRunning:
    discard
  var analysis: SampleAnalysis
  doAssert prepared(preparation, analysis)
  doAssert analysis.wordCount == 1
  doAssert analysis.sample.frames == TotalFrames
  doAssert storage[0] > 0
