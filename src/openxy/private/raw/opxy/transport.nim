type
  Transport* {.importcpp: "opxy::Transport", header: "opxy/transport.hpp".} = object
    bpm_x10*: uint32
    ticks96*: uint32
    playing*: bool
