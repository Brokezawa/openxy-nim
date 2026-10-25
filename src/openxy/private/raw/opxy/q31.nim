const maximum*: cint = 2147483647

proc multiply*(a, b: cint): cint {.
  importcpp: "opxy::q31::multiply(@)", header: "opxy/q31.hpp".}
proc half*(value: cint): cint {.
  importcpp: "opxy::q31::half(@)", header: "opxy/q31.hpp".}
