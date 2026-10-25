import std/assertions

import openxy

block layouts:
  when sizeof(pointer) == 8:
    doAssert sizeof(SampleView) == 24
    doAssert sizeof(SampleAssignment) == 32
    doAssert sizeof(SampleAnalysis) == 40
    doAssert sizeof(Buffer) == 16
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
  let view = SampleView(data: cast[ptr UncheckedArray[int16]](addr pcm[0]),
                        frames: 2, rate: 44100, channels: 2)
  doAssert view.sampleAt(0, 0) == 1
  doAssert view.sampleAt(0, 1) == 2
  doAssert view.sampleAt(1, 0) == 3
  doAssert view.sampleAt(2, 0) == 0
  doAssert view.sampleAt(0, 9) == 1

block audio_views:
  var values = [Q31(10), Q31(20), Q31(30)]
  let view = initAudioView(cast[ptr UncheckedArray[Q31]](addr values[0]), values.len)
  doAssert view.len == 3
  doAssert view[1] == Q31(20)
  var mutable = initMutableAudioView(cast[ptr UncheckedArray[Q31]](addr values[0]),
                                     values.len)
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
  let mutable = initMutableAudioView(cast[ptr UncheckedArray[Q31]](addr output[0]),
                                     output.len)
  let sampleBlock = SampleBlock(output: mutable, outputChannels: 2)
  doAssert sampleBlock.frames == BlockFrames
  doAssert not sampleBlock.mono
