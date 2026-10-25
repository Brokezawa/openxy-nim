import std/assertions

import openxy

block layouts:
  doAssert sizeof(Phase) == 4
  doAssert alignof(Phase) == 4
  doAssert sizeof(PhaseIncrement) == 4
  doAssert sizeof(Q10) == 4
  doAssert sizeof(Q27) == 4
  doAssert sizeof(Cents) == 4
  doAssert sizeof(Semitones) == 4
  doAssert sizeof(SampleFrame) == 4
  doAssert sizeof(VoiceId) == 4
  doAssert sizeof(PadSettings) == 2
  doAssert sizeof(Paint) == 4

block phase_wraps:
  var phase = Phase(0xffff_ffff'u32)
  phase += PhaseIncrement(1)
  doAssert phase == Phase(0)

block q10_floor:
  doAssert floorQ10(Q10(1024)) == 1
  doAssert floorQ10(Q10(-1)) == -1
  doAssert floorQ10(Q10(-1024)) == -1
  doAssert q10(2) == Q10(2048)

block pad_settings:
  let value = PadSettings(0b1010) xor PadSettings(0b0011)
  doAssert value == PadSettings(0b1001)
  doAssert (value and PadSettings(0b1000)) == PadSettings(0b1000)
  doAssert (not PadSettings(0)) == PadSettings(0xffff)

block voice_ids:
  doAssert not isValid(VoiceId(0))
  doAssert isValid(VoiceId(1))

block sample_frames:
  doAssert SampleFrame(2) + 3 == SampleFrame(5)
  doAssert SampleFrame(5) - 3 == SampleFrame(2)
