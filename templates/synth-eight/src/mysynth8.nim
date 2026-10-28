## A two-page OP-XY synth written in Nim.

import openxy

type
  Voice* = object
    phase: Phase
    filtered: int32

  Shared* = object

  DisplayState* = object
    phase: uint32
    header: PageHeader

  Frame* = openxy.Frame[2, 64, 10, 16, 16]


proc initialize*(voice: var Voice; shared: var Shared; owner: VoiceId) {.raises: [].} =
  voice.phase = Phase(0)
  voice.filtered = 0

proc start*(voice: var Voice; shared: var Shared; owner: VoiceId) {.raises: [].} =
  voice.phase = Phase(0)
  voice.filtered = 0

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
    var sample = int32(mixed) shr 16
    let gain = 1 + (int32(parameters[4]) shr 28)
    sample = sample * gain
    if sample < -16384:
      sample = -16384
    elif sample > 16384:
      sample = 16384
    let bits = (int32(parameters[5]) shr 16) * 10 shr 15
    sample = (sample shr bits) shl bits
    let positive = if sample < 0: -sample else: sample
    sample = sample + (((positive - sample) * (int32(parameters[6]) shr 16)) shr 15)
    let smoothing = (int32(parameters[7]) shr 16) * 31 shr 5
    voice.filtered = sample + (((voice.filtered - sample) * smoothing) shr 15)
    output[index] = Q31(voice.filtered * 65536) * parameters[2]
    voice.phase += pitch[index]

proc displayReset*(state: var DisplayState) {.raises: [].} =
  state.phase = 0
  state.header.reset()

proc display*(state: var DisplayState; input: Input; frame: var Frame) {.raises: [].} =
  const titles: array[8, string] = [
    "Blend", "Width", "Level", "Motion", "Drive", "Crush", "Rectify", "Smooth",
  ]
  var values: array[8, HeaderText]
  for index in 0 ..< values.len:
    headerAmount(values[index], input.slots[index])
  const slots: PageHeaderSlots = [[0'u8, 1, 2, 3], [4'u8, 5, 6, 7]]
  pageHeader(state.header, input, frame, titles, values, 2, slots)

  if input.heldNotes > 0 and input.heldNotes <= 128 and input.reducedMotion == 0:
    state.phase = (state.phase + uint32(clampQ10(int32(input.elapsed), 0, 102))) and 8191'u32
  let motion: int32 =
    if input.reducedMotion != 0: 0
    else: (int32(state.phase shr 7) - 32) * (int32(input.slots[3]) shr 26) div 32

  for path in 0 ..< 2:
    frame.paths[path].key = state.phase div 8 + 1 + uint32(path * 64)
    let radius: int32 = if path == 0: 40 else: 24
    for point in 0 ..< 64:
      let angle: int32 = int32(point) * 3600 div 64 + motion + int32(path * 900)
      let direction = rotation(angle)
      frame.paths[path].points[point] = Point(
        x: direction.cos * radius div 1024,
        y: direction.sin * radius div 1024,
      )

  place(frame, 0, q10(208 + motion), q10(120), Unit, 15, PaintStroke)
  place(frame, 1, q10(272 - motion), q10(120), Unit, 10, PaintStroke)

openxyValidate(mkSynth, Voice, Shared)
