import openxy

proc mutate(pitch: openArray[PhaseIncrement]) =
  pitch[0] = PhaseIncrement(1)

var pitch: array[PitchSlots, PhaseIncrement]
mutate(pitch)
