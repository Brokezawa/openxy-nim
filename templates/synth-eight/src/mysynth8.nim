## A two-page OP-XY synth written in Nim.

import openxy

type
  Control* = enum
    blend, width, level, motion, drive, crush, rectify, smooth

  Voice* = object
    phase: Phase
    filtered: int32

  Shared* = object

  DisplayState* = object
    phase: uint32
    header: PageHeader

  Frame* = openxy.Frame[2, 64, 10, 16, 16]

const
  PulseCenter = 0x4000_0000'u32
  PhaseMask = 0x7FFF_FFFF'u32
  PhaseTopBit = 0x8000_0000'u32
  Q15ToQ31 = 65536
  HeaderFirstNode = 2
  DisplayPhaseMask = 8191'u32
  DisplayElapsedMax = 102

  NodeX = 240
  NodeOffset = 32
  NodeY = 120
  SpokeRadius = 40
  InnerRadius = 24
  PointsPerTurn = 64
  TurnTenths = 3600
  PathPhaseOffset = 900
  PathKeyStride = 64

func drive(sample, control: int32): int32 {.inline, raises: [].} =
  const GainShift = 28
  sample * (1 + (control shr GainShift))

func clipQ15(sample: int32): int32 {.inline, raises: [].} =
  const Limit = 16384
  max(-Limit, min(sample, Limit))

func crush(sample, control: int32): int32 {.inline, raises: [].} =
  const ControlShift = 16
  const Levels = 10
  const Scale = 15
  let bits = (control shr ControlShift) * Levels shr Scale
  (sample shr bits) shl bits

func rectify(sample, control: int32): int32 {.inline, raises: [].} =
  const ControlShift = 16
  const Scale = 15
  let positive = if sample < 0: -sample else: sample
  sample + (((positive - sample) * (control shr ControlShift)) shr Scale)

func smooth(sample, control, previous: int32): int32 {.inline, raises: [].} =
  const ControlShift = 16
  const Steps = 31
  const ControlScale = 5
  const MixScale = 15
  let amount = (control shr ControlShift) * Steps shr ControlScale
  sample + (((previous - sample) * amount) shr MixScale)

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
    var sample = toInt32(mixed) shr 16
    sample = drive(sample, toInt32(parameters[drive]))
    sample = clipQ15(sample)
    sample = crush(sample, toInt32(parameters[crush]))
    sample = rectify(sample, toInt32(parameters[rectify]))
    voice.filtered = smooth(sample, toInt32(parameters[smooth]), voice.filtered)
    output[index] = Q31(voice.filtered * Q15ToQ31) * parameters[level]
    voice.phase += pitch[index]

proc displayReset*(state: var DisplayState) {.raises: [].} =
  state.phase = 0
  state.header.reset()

proc display*(state: var DisplayState; input: Input; frame: var Frame) {.raises: [].} =
  const titles: array[Control, string] = [
    "Blend", "Width", "Level", "Motion",
    "Drive", "Crush", "Rectify", "Smooth",
  ]
  var values: array[Control, HeaderText]
  for control in Control:
    headerAmount(values[control], input.slots[control])
  pageHeader(state.header, input, frame, titles, values, HeaderFirstNode)

  if input.heldNotes > 0 and input.heldNotes <= MaxHeldNotes and
      input.reducedMotion == 0:
    state.phase = (state.phase +
      uint32(clampQ10(toInt32(input.elapsed), 0, DisplayElapsedMax))) and DisplayPhaseMask
  let motionAmount: int32 =
    if input.reducedMotion != 0: 0
    else: (int32(state.phase shr 7) - 32) * (toInt32(input.slots[motion]) shr 26) div 32

  for path in 0 ..< 2:
    frame.paths[path].key = state.phase div 8 + 1 + uint32(path * PathKeyStride)
    let radius: int32 = if path == 0: SpokeRadius else: InnerRadius
    for point in 0 ..< PointsPerTurn:
      let angle: int32 = int32(point) * TurnTenths div PointsPerTurn + motionAmount +
        int32(path * PathPhaseOffset)
      let direction = rotation(angle)
      frame.paths[path].points[point] = Point(
        x: direction.cos * radius,
        y: direction.sin * radius,
      )

  place(frame, 0, q10(NodeX - NodeOffset + motionAmount), q10(NodeY), Unit, 15, PaintStroke)
  place(frame, 1, q10(NodeX + NodeOffset - motionAmount), q10(NodeY), Unit, 10, PaintStroke)

openxyValidate(mkSynth, Voice, Shared)
