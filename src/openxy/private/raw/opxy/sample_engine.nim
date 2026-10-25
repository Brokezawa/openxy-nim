import openxy/private/raw/opxy/[sample_analysis, transport]

type
  PadSettings* = uint16

  SampleRegion* {.importcpp: "opxy::SampleRegion",
    header: "opxy/sample_engine.hpp".} = object
    begin*: uint32
    `end`*: uint32
    level*: int32
    reverse*: bool
    pitch_cents*: int32

  SampleAssignment* {.importcpp: "opxy::SampleAssignment",
    header: "opxy/sample_engine.hpp".} = object
    filename*: cstring
    filename_bytes*: uint32
    frames*: uint32
    rate*: uint32
    bpm_x10*: uint32
    replacing*: bool
    previous*: PadSettings
    recorded*: bool

  DrumControl* {.importcpp: "opxy::DrumControl",
    header: "opxy/sample_engine.hpp".} = object
    knob*: uint32
    direction*: int32
    pressed*: bool
    shifted*: bool
    held*: bool

  DrumPanel* {.importcpp: "opxy::DrumPanel",
    header: "opxy/sample_engine.hpp".} = object
    pitch_cents*: int32
    repeat*: bool
    reverse*: bool
    level*: uint32
    shifted*: array[2, array[16, char]]

  SampleBlock* {.importcpp: "opxy::SampleBlock",
    header: "opxy/sample_engine.hpp".} = object
    output*: ptr int32
    parameters*: ptr int32
    pitch*: ptr uint32
    transport*: Transport
    region*: SampleRegion
    analysis*: ptr SampleAnalysis
    settings*: PadSettings
    output_channels*: uint32
    track_transpose*: int32
    drum_transpose*: int32

const
  sample_unity_level*: int32 = 1 shl 27
