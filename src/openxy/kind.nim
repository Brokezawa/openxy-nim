## Machine kinds shared by the authoring and generation layers.

type
  MachineKind* = enum
    mkSynth = "synth"
    mkSample = "sample"
    mkEffect = "effect"

func parseMachineKind*(value: string): MachineKind =
  case value
  of "synth": mkSynth
  of "sample": mkSample
  of "effect": mkEffect
  else: raise newException(ValueError, "unknown machine kind: " & value)
