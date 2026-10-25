## A small, complete OP-XY synth written in Nim.

import openxy

type
  Voice* = object
    phase: Phase

  Shared* = object

  DisplayState* = object
    phase: uint32
    notes: NoteTracker

  Frame* = openxy.Frame[2, 64, 2, 0, 16]


proc initialize*(voice: var Voice; shared: var Shared; owner: VoiceId) {.raises: [].} =
  voice.phase = Phase(0)

proc start*(voice: var Voice; shared: var Shared; owner: VoiceId) {.raises: [].} =
  voice.phase = Phase(0)

proc destroy*(voice: var Voice; shared: var Shared; owner: VoiceId) {.raises: [].} =
  discard

proc render*(voice: var Voice; shared: var Shared; owner: VoiceId;
             output: var openArray[Q31]; parameters: openArray[Q31];
             pitch: openArray[PhaseIncrement]) {.raises: [].} =
  let blend = parameters[0]
  let width = 0x40000000'u32 + uint32(toInt32(parameters[1]))
  for index in 0 ..< output.len:
    let phase = uint32(voice.phase)
    var folded = phase and 0x7fffffff'u32
    if (phase and 0x80000000'u32) != 0:
      folded = 0x7fffffff'u32 - folded
    let triangle = Q31(cast[int32](folded) - 0x40000000)
    let pulse = if phase < width: Q31(0x40000000) else: Q31(-0x40000000)
    let mixed = triangle * (Q31Max - blend) + pulse * blend
    output[index] = mixed * parameters[2]
    voice.phase += pitch[index]

proc displayReset*(state: var DisplayState) {.raises: [].} =
  state.phase = 0
  state.notes.reset()

proc display*(state: var DisplayState; input: Input; frame: var Frame) {.raises: [].} =
  let events = state.notes.update(input)
  if events.holdStarted or events.noteReleased:
    state.phase = 0
  inc state.phase
  let motion = int32(toInt32(input.parameters[3]) shr 20)
  let spin = int32(state.phase mod 360) * 10 + motion
  let left = q10(320) - q10(72)
  let right = q10(320) + q10(72)
  let middle = q10(160)

  place(frame, 0, left, middle, UnitQ10, uint32(motion and 7), PaintStroke)
  place(frame, 1, right, middle, UnitQ10, uint32((motion + 3) and 7), PaintFillAndStroke)
  turn(frame, 0, rotation(spin))
  turn(frame, 1, rotation(-spin))
  header(frame, 0, "NIM")

  for path in 0 .. 1:
    frame.paths[path].key = state.phase div 8'u32 + 1'u32 + uint32(path * 64)
    let radius: int32 = if path == 0: 40 else: 24
    for point in 0 ..< 64:
      let angle = int32(point) * 3600 div 64 + spin + int32(path * 900)
      let direction = rotation(angle)
      frame.paths[path].points[point] = Point(
        x: direction.cos * radius div 1024,
        y: direction.sin * radius div 1024,
      )

openxyValidate(mkSynth, Voice, Shared)
