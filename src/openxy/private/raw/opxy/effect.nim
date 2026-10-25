type
  Buffer* {.importcpp: "opxy::Buffer", header: "opxy/effect.hpp".} = object
    words*: ptr int32
    count*: uint32

const
  effect_state_bytes*: uint32 = 476
  effect_buffered_state_bytes*: uint32 = 472
  effect_state_alignment*: uint32 = 4
  effect_buffer_bytes*: uint32 = 524288
  division_sixteenths*: array[8, uint32] = [2'u32, 3, 4, 6, 8, 12, 16, 32]

proc division*(control: int32): uint32 {.
  importcpp: "opxy::division(@)", header: "opxy/effect.hpp".}
