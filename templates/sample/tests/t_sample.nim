import std/assertions

import openxy
import openxy/testkit
import mysample

const TotalFrames = 64

var source: array[TotalFrames * 2, int16]
for index in 0 ..< source.len:
  source[index] = int16((index mod 19) * 1200 - 10000)

let view = initSampleView(source, 44100, 2)
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
  parameters[volume] = Q31Half
  var pitch = zeroPitch()
  let sampleBlock = initSampleBlock(output, parameters, pitch, region,
    outputChannels = 2,
    transport = Transport(bpmX10: 1200, ticks96: 0, playing: true))
  renderSample(voice, sampleBlock)
  var nonzero = false
  for sample in output:
    if sample != Q31(0):
      nonzero = true
  doAssert nonzero, "the sample engine should produce audio"
  doAssert not sampleBlock.transport.isEmpty

block pad_services:
  doAssert toUint32(sampleDefaults()) == 0
  var settings = PadSettings(0)
  drumControl(settings, DrumControl(knob: 0, direction: 0, pressed: true))
  doAssert toUint32(settings) == 1
  var panel: DrumPanel
  drumPanel(settings, region, zeroParameters(), panel)
  doAssert not panel.repeat
  doAssert panel.level == toUint32(Q31Max)
  doAssert sampleAssign(SampleAssignment(replacing: true, previous: PadSettings(7))) ==
    PadSettings(7)
  doAssert sampleAssign(SampleAssignment(replacing: false)) == PadSettings(0)

block analysis_service:
  doAssert analysisWords(view) == 1
  var preparation: Preparation
  var storage: array[1, uint32]
  doAssert prepareBegin(preparation, view, initWordView(storage))
  var cursor = 0'u32
  while prepareStep(preparation, 512, cursor) == prepareRunning:
    discard
  var analysis: SampleAnalysis
  doAssert prepared(preparation, analysis)
  doAssert analysis.wordCount == 1
  doAssert analysis.sample.frames == TotalFrames
  doAssert analysis.words.len == 1
  doAssert storage[0] > 0
