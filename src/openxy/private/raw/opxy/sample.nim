type
  SampleView* {.importcpp: "opxy::SampleView", header: "opxy/sample.hpp".} = object
    data*: ptr int16
    frames*: uint32
    rate*: uint32
    channels*: uint32

proc sample_at*(view: SampleView; frame: uint32; channel: uint32): int16 {.
  importcpp: "opxy::sample_at(@)", header: "opxy/sample.hpp".}
