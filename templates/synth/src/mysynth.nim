## A small, complete OP-XY synth written in Nim.

import openxy

type
  Control* = enum
    blend, width, level, motion

  Voice* = object
    phase: Phase

  Shared* = object

  DisplayState* = object
    phase: uint32
    notes: NoteTracker

  Frame* = openxy.Frame[2, 64, 2, 0, 16]

const
  PulseCenter = 0x4000_0000'u32
  PhaseMask = 0x7FFF_FFFF'u32
  PhaseTopBit = 0x8000_0000'u32

  NodeX = 240
  NodeOffset = 32
  NodeY = 120
  SpokeRadius = 40
  InnerRadius = 24
  PointsPerTurn = 64
  TurnTenths = 3600
  PathPhaseOffset = 900
  PathKeyStride = 64
  DisplayElapsedMax = 102
  DisplayPhaseMask = 8191'u32


proc initialize*(voice: var Voice; shared: var Shared; owner: VoiceId) {.raises: [].} =
  voice.phase = Phase(0)

proc start*(voice: var Voice; shared: var Shared; owner: VoiceId) {.raises: [].} =
  voice.phase = Phase(0)

proc destroy*(voice: var Voice; shared: var Shared; owner: VoiceId) {.raises: [].} =
  discard

proc render*(voice: var Voice; shared: var Shared; owner: VoiceId;
             output: var openArray[Q31]; parameters: openArray[Q31];
             pitch: openArray[PhaseIncrement]) {.raises: [].} =
  let blendAmount = parameters[blend]
  let widthAmount = PulseCenter + toUint32(parameters[width])
  for index in 0 ..< output.len:
    let raw = toUint32(voice.phase)
    var folded = raw and PhaseMask
    if (raw and PhaseTopBit) != 0:
      folded = PhaseMask - folded
    let triangle = Q31(int32(folded) - toInt32(Q31Half))
    let pulse = if raw < widthAmount: Q31Half else: -Q31Half
    let mixed = triangle * (Q31Max - blendAmount) + pulse * blendAmount
    output[index] = mixed * parameters[level]
    voice.phase += pitch[index]

proc displayReset*(state: var DisplayState) {.raises: [].} =
  state.phase = 0
  state.notes.reset()

proc display*(state: var DisplayState; input: Input; frame: var Frame) {.raises: [].} =
  let events = state.notes.update(input)
  if events.holdStarted or events.noteReleased:
    state.phase = 0
  if input.heldNotes > 0 and input.heldNotes <= MaxHeldNotes and
      input.reducedMotion == 0:
    state.phase = (state.phase +
      uint32(clampQ10(toInt32(input.elapsed), 0, DisplayElapsedMax))) and
      DisplayPhaseMask
  let motionAmount: int32 =
    if input.reducedMotion != 0: 0
    else: (int32(state.phase shr 7) - 32) *
      (toInt32(input.parameters[motion]) shr 26) div 32

  place(frame, 0, q10(NodeX - NodeOffset + motionAmount), q10(NodeY),
    UnitQ10, 15, PaintStroke)
  place(frame, 1, q10(NodeX + NodeOffset - motionAmount), q10(NodeY),
    UnitQ10, 10, PaintStroke)
  header(frame, 0, "NIM")

  for path in 0 .. 1:
    frame.paths[path].key = state.phase div 8'u32 + 1'u32 +
      uint32(path * PathKeyStride)
    let radius: int32 = if path == 0: SpokeRadius else: InnerRadius
    for point in 0 ..< PointsPerTurn:
      let angle = int32(point) * TurnTenths div PointsPerTurn +
        int32(path * PathPhaseOffset)
      let direction = rotation(angle)
      frame.paths[path].points[point] = Point(
        x: direction.cos * radius,
        y: direction.sin * radius,
      )

openxyValidate(mkSynth, Voice, Shared)
