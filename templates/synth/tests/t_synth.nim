import std/assertions

import openxy
import openxy/testkit
import mysynth

block audio_block:
  var voice: Voice
  var shared: Shared
  initialize(voice, shared, VoiceId(1))
  var parameters = zeroParameters()
  parameters[2] = Q31(0x40000000)
  var output: array[BlockFrames, Q31]
  render(voice, shared, VoiceId(1), output, parameters, zeroPitch())
  doAssert output.len == BlockFrames
  var nonzero = false
  for sample in output:
    doAssert int32(sample) >= low(int32) and int32(sample) <= high(int32)
    if sample != Q31(0):
      nonzero = true
  doAssert nonzero, "the synth should produce audio"

block frame_block:
  var state: DisplayState
  displayReset(state)
  var frame: mysynth.Frame
  var input = Input(track: 1, heldNotes: 1, noteOffSerial: 1)
  discard displayFrame(state, input, frame)
  assertFrameValid(frame)
  doAssert frame.paths[0].key != 0
  doAssert frame.paths[1].key != 0
  doAssert frame.nodes[0].x == int32(q10(208))
  doAssert frame.nodes[1].x == int32(q10(272))
  doAssert frame.nodes[0].y == int32(q10(120))
  doAssert frame.nodes[1].y == int32(q10(120))
  var radiusSquared: int64
  for point in frame.paths[0].points:
    let squared = int64(point.x) * int64(point.x) +
      int64(point.y) * int64(point.y)
    if squared > radiusSquared:
      radiusSquared = squared
  doAssert radiusSquared > int64(20 * 1024) * int64(20 * 1024)
  doAssert radiusSquared <= int64(64 * 1024) * int64(64 * 1024)
  doAssert frame.nodes[0].shade > 0
  doAssert frame.nodes[1].shade > 0

  input.parameters[motion] = Q31(0x40000000)
  input.elapsed = Q10(102)
  discard displayFrame(state, input, frame)
  doAssert frame.nodes[0].x == int32(q10(192))
  doAssert frame.nodes[1].x == int32(q10(288))
  doAssert frame.nodes[0].y == int32(q10(120))
  doAssert frame.nodes[1].y == int32(q10(120))

block note_events:
  var tracker: NoteTracker
  doAssert tracker.update(Input(track: 2, heldNotes: 0)).holdStarted == false
  let started = tracker.update(Input(track: 2, heldNotes: 3))
  doAssert started.holdStarted
  let ended = tracker.update(Input(track: 2, heldNotes: 0, noteOffSerial: 1))
  doAssert ended.holdEnded
  doAssert ended.noteReleased
