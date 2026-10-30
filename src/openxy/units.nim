## Domain units that must not mix accidentally.

type
  Phase* = distinct uint32
  PhaseIncrement* = distinct uint32
  Q10* = distinct int32
  Q27* = distinct uint32
  Cents* = distinct int32
  Semitones* = distinct int32
  SampleFrame* = distinct uint32
  VoiceId* = distinct uint32
  PadSettings* = distinct uint32
  Paint* = distinct uint32

const
  UnitQ10* = Q10(1024)
  SampleUnityLevel* = Q27(1'u32 shl 27)
  PadSettingsMask* = 0x3_ffff'u32
  PaintKeep* = Paint(0)
  PaintStroke* = Paint(1)
  PaintFillAndStroke* = Paint(2)

func toUint32*(value: Phase): uint32 {.inline.} = uint32(value)
func toUint32*(value: PhaseIncrement): uint32 {.inline.} = uint32(value)
func toUint32*(value: SampleFrame): uint32 {.inline.} = uint32(value)
func toUint32*(value: VoiceId): uint32 {.inline.} = uint32(value)
func toUint32*(value: Q27): uint32 {.inline.} = uint32(value)
func toUint32*(value: Paint): uint32 {.inline.} = uint32(value)
func toInt32*(value: Q10): int32 {.inline.} = int32(value)
func toInt32*(value: Cents): int32 {.inline.} = int32(value)
func toInt32*(value: Semitones): int32 {.inline.} = int32(value)
func toUint32*(value: PadSettings): uint32 {.inline.} = uint32(value)
func toUint16*(value: PadSettings): uint16 {.inline.} =
  uint16(uint32(value) and PadSettingsMask)

func toPhase*(value: uint32): Phase {.inline.} = Phase(value)
func toPhaseIncrement*(value: uint32): PhaseIncrement {.inline.} = PhaseIncrement(value)
func toSampleFrame*(value: uint32): SampleFrame {.inline.} = SampleFrame(value)
func toVoiceId*(value: uint32): VoiceId {.inline.} = VoiceId(value)
func toQ10*(value: int32): Q10 {.inline.} = Q10(value)
func toCents*(value: int32): Cents {.inline.} = Cents(value)
func toSemitones*(value: int32): Semitones {.inline.} = Semitones(value)
func toPadSettings*(value: uint32): PadSettings {.inline.} =
  PadSettings(value and PadSettingsMask)
func toPaint*(value: uint32): Paint {.inline.} = Paint(value)

func q10*(pixels: int32): Q10 {.inline.} = Q10(pixels * int32(UnitQ10))

func `==`*(a, b: Phase): bool {.inline.} = uint32(a) == uint32(b)
func `<`*(a, b: Phase): bool {.inline.} = uint32(a) < uint32(b)
func `<=`*(a, b: Phase): bool {.inline.} = uint32(a) <= uint32(b)

func `+`*(phase: Phase; increment: PhaseIncrement): Phase {.inline.} =
  Phase(uint32(phase) + uint32(increment))

func `+=`*(phase: var Phase; increment: PhaseIncrement) {.inline.} =
  phase = phase + increment

func `==`*(a, b: PhaseIncrement): bool {.inline.} = uint32(a) == uint32(b)
func `<`*(a, b: PhaseIncrement): bool {.inline.} = uint32(a) < uint32(b)
func `<=`*(a, b: PhaseIncrement): bool {.inline.} = uint32(a) <= uint32(b)
func `+`*(a, b: PhaseIncrement): PhaseIncrement {.inline.} = PhaseIncrement(uint32(a) + uint32(b))
func `-`*(a, b: PhaseIncrement): PhaseIncrement {.inline.} = PhaseIncrement(uint32(a) - uint32(b))

func `==`*(a, b: Q10): bool {.inline.} = int32(a) == int32(b)
func `<`*(a, b: Q10): bool {.inline.} = int32(a) < int32(b)
func `<=`*(a, b: Q10): bool {.inline.} = int32(a) <= int32(b)
func `+`*(a, b: Q10): Q10 {.inline.} = Q10(int32(a) + int32(b))
func `-`*(a, b: Q10): Q10 {.inline.} = Q10(int32(a) - int32(b))
func `*`*(value: Q10; factor: int32): Q10 {.inline.} = Q10(int32(value) * factor)
func `*`*(factor: int32; value: Q10): Q10 {.inline.} = value * factor

func floorQ10*(value: Q10): int32 {.inline.} =
  int32(value) div 1024 - (if int32(value) < 0 and int32(value) mod 1024 != 0: 1 else: 0)

func `==`*(a, b: Q27): bool {.inline.} = uint32(a) == uint32(b)
func `<`*(a, b: Q27): bool {.inline.} = uint32(a) < uint32(b)
func `<=`*(a, b: Q27): bool {.inline.} = uint32(a) <= uint32(b)

func `==`*(a, b: Cents): bool {.inline.} = int32(a) == int32(b)
func `<`*(a, b: Cents): bool {.inline.} = int32(a) < int32(b)
func `<=`*(a, b: Cents): bool {.inline.} = int32(a) <= int32(b)
func `+`*(a, b: Cents): Cents {.inline.} = Cents(int32(a) + int32(b))
func `-`*(a, b: Cents): Cents {.inline.} = Cents(int32(a) - int32(b))

func `==`*(a, b: Semitones): bool {.inline.} = int32(a) == int32(b)
func `<`*(a, b: Semitones): bool {.inline.} = int32(a) < int32(b)
func `<=`*(a, b: Semitones): bool {.inline.} = int32(a) <= int32(b)
func `+`*(a, b: Semitones): Semitones {.inline.} = Semitones(int32(a) + int32(b))
func `-`*(a, b: Semitones): Semitones {.inline.} = Semitones(int32(a) - int32(b))

func `==`*(a, b: SampleFrame): bool {.inline.} = uint32(a) == uint32(b)
func `<`*(a, b: SampleFrame): bool {.inline.} = uint32(a) < uint32(b)
func `<=`*(a, b: SampleFrame): bool {.inline.} = uint32(a) <= uint32(b)
func `+`*(frame: SampleFrame; count: int): SampleFrame {.inline.} =
  SampleFrame(uint32(frame) + uint32(count))
func `-`*(frame: SampleFrame; count: int): SampleFrame {.inline.} =
  SampleFrame(uint32(frame) - uint32(count))

func `==`*(a, b: VoiceId): bool {.inline.} = uint32(a) == uint32(b)
func `<`*(a, b: VoiceId): bool {.inline.} = uint32(a) < uint32(b)
func `<=`*(a, b: VoiceId): bool {.inline.} = uint32(a) <= uint32(b)
func isValid*(id: VoiceId): bool {.inline.} = uint32(id) != 0

func `==`*(a, b: PadSettings): bool {.inline.} = uint32(a) == uint32(b)
func `and`*(a, b: PadSettings): PadSettings {.inline.} =
  PadSettings(uint32(a) and uint32(b))
func `or`*(a, b: PadSettings): PadSettings {.inline.} =
  PadSettings(uint32(a) or uint32(b))
func `xor`*(a, b: PadSettings): PadSettings {.inline.} =
  PadSettings(uint32(a) xor uint32(b))
func `not`*(value: PadSettings): PadSettings {.inline.} =
  PadSettings((not uint32(value)) and PadSettingsMask)

func `==`*(a, b: Paint): bool {.inline.} = uint32(a) == uint32(b)
func `<`*(a, b: Paint): bool {.inline.} = uint32(a) < uint32(b)
func `<=`*(a, b: Paint): bool {.inline.} = uint32(a) <= uint32(b)
