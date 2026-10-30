import std/assertions

import openxy
import openxy/testkit

block layouts:
  when sizeof(pointer) == 8:
    doAssert sizeof(SampleView) == 24
    doAssert sizeof(SampleAssignment) == 40
    doAssert sizeof(SampleAnalysis) == 40
    doAssert sizeof(Buffer) == 16
  doAssert sizeof(PadSettings) == 4
  doAssert sizeof(SampleRegion) == 20
  doAssert sizeof(DrumControl) == 12
  doAssert sizeof(DrumPanel) == 44
  doAssert sizeof(Transport) == 12

block absent_values:
  doAssert SampleView().isEmpty
  doAssert SampleRegion().isEmpty
  doAssert Transport().isEmpty
  doAssert Buffer().isEmpty
  doAssert not SampleBlock().hasAnalysis

block sample_view:
  var pcm = [int16(1), int16(2), int16(3), int16(4)]
  let view = initSampleView(pcm, 44100, 2)
  doAssert view.frames == 2
  doAssert view.rate == 44100
  doAssert view.channels == 2
  doAssert view.sampleAt(0, 0) == 1
  doAssert view.sampleAt(0, 1) == 2
  doAssert view.sampleAt(1, 0) == 3
  doAssert view.sampleAt(2, 0) == 0
  doAssert view.sampleAt(0, 9) == 1
  doAssert initSampleView(pcm, 44100, 0).isEmpty

block word_view:
  var words = [1'u32, 2'u32]
  let view = initWordView(words)
  doAssert view.len == 2
  doAssert view[0] == 1
  view[1] = 3
  doAssert words[1] == 3
  doAssert view[9] == 0
  view[9] = 7
  doAssert words.len == 2
  doAssert initWordView(nil, 0).isEmpty

block buffer_view:
  var data = [Q31(1), Q31(2)]
  var buffer = initBuffer(data)
  doAssert buffer.len == 2
  doAssert buffer[0] == Q31(1)
  buffer[1] = Q31(4)
  doAssert data[1] == Q31(4)
  doAssert buffer[5] == Q31(0)
  buffer[5] = Q31(9)
  doAssert buffer.len == 2
  doAssert initBuffer(nil, 0).isEmpty

block sample_analysis:
  var pcm = [int16(3), int16(4)]
  var words = [9'u32]
  let sample = initSampleView(pcm, 44100, 1)
  let analysis = initSampleAnalysis(sample, initWordView(words), 7)
  doAssert analysis.wordCount == 1
  doAssert analysis.info == 7
  doAssert analysis.sample.frames == 2
  doAssert analysis.words.len == 1
  doAssert analysis.words[0] == 9

block audio_views:
  var values = [Q31(10), Q31(20), Q31(30)]
  let view = initAudioView(values)
  doAssert view.len == 3
  doAssert view[1] == Q31(20)
  var mutable = initMutableAudioView(values)
  mutable[0] = Q31(99)
  doAssert values[0] == Q31(99)
  var visited = 0
  samples(view.toOpenArray, 3, inc visited)
  doAssert visited == 3

block division_control:
  doAssert division(Q31(0)) == 0
  doAssert division(Q31(high(int32))) == 7
  doAssert divisionSixteenths(Q31(high(int32))) == 32

block sample_block_frames:
  var output: array[StereoOutputWords, Q31]
  let sampleBlock = initSampleBlock(output, zeroParameters(), zeroPitch(),
    SampleRegion(), outputChannels = 2)
  doAssert sampleBlock.frames == BlockFrames
  doAssert not sampleBlock.mono
