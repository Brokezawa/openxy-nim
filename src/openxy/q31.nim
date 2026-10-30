## Signed Q1.31 audio values.
##
## `Q31` addition and subtraction wrap modulo 2^32; multiplication uses the
## SDK's saturating Q1.31 multiply. Use `SatQ31` when addition and subtraction
## must saturate instead.

type
  Q31* = distinct int32
  SatQ31* = distinct int32

  Q31Like* = concept value
    value is Q31 or value is SatQ31
    value + value is typeof(value)
    value - value is typeof(value)
    value * value is typeof(value)
    toInt32(value) is int32

const
  Q31Min* = Q31(low(int32))
  Q31Max* = Q31(high(int32))
  Q31Half* = Q31(0x4000_0000)
  SatQ31Min* = SatQ31(low(int32))
  SatQ31Max* = SatQ31(high(int32))

func toInt32*(value: Q31): int32 {.inline.} = int32(value)
func toInt32*(value: SatQ31): int32 {.inline.} = int32(value)

func toUint32*(value: Q31): uint32 {.inline.} = uint32(int32(value))

func fromQ15*(value: int16): Q31 {.inline.} =
  ## Convert a Q1.15 sample to Q1.31.
  Q31(int32(value) * 0x8000)

func `[]`*[T: enum](values: openArray[Q31]; index: T): Q31 {.inline.} =
  ## Index a parameter or header array by a machine control enum.
  values[ord(index)]

func `[]`*[T: enum](values: var openArray[Q31]; index: T): var Q31 {.inline.} =
  ## Mutable enum lookup for host-test parameter arrays.
  values[ord(index)]

func toQ31*(value: SatQ31): Q31 {.inline.} = Q31(int32(value))

converter toSatQ31*(value: Q31): SatQ31 {.inline.} = SatQ31(int32(value))

func saturatingAdd*(a, b: int32): int32 {.inline.} =
  let sum = cast[int32](cast[uint32](a) + cast[uint32](b))
  if ((a xor sum) and (b xor sum)) < 0:
    if a < 0: low(int32) else: high(int32)
  else:
    sum

func saturatingSub*(a, b: int32): int32 {.inline.} =
  let difference = cast[int32](cast[uint32](a) - cast[uint32](b))
  if ((a xor b) and (a xor difference)) < 0:
    if a < 0: low(int32) else: high(int32)
  else:
    difference

func `==`*(a, b: Q31): bool {.inline.} = int32(a) == int32(b)
func `<`*(a, b: Q31): bool {.inline.} = int32(a) < int32(b)
func `<=`*(a, b: Q31): bool {.inline.} = int32(a) <= int32(b)
func `==`*(a, b: SatQ31): bool {.inline.} = int32(a) == int32(b)
func `<`*(a, b: SatQ31): bool {.inline.} = int32(a) < int32(b)
func `<=`*(a, b: SatQ31): bool {.inline.} = int32(a) <= int32(b)

func `+`*(a, b: Q31): Q31 {.inline.} =
  Q31(cast[int32](cast[uint32](int32(a)) + cast[uint32](int32(b))))

func `-`*(a, b: Q31): Q31 {.inline.} =
  Q31(cast[int32](cast[uint32](int32(a)) - cast[uint32](int32(b))))

func `-`*(value: Q31): Q31 {.inline.} = Q31(0) - value

func `*`*(a, b: Q31): Q31 {.
  importcpp: "opxy::q31::multiply(@)",
  header: "opxy/q31.hpp",
  inline.}

func `+`*(a, b: SatQ31): SatQ31 {.inline.} =
  SatQ31(saturatingAdd(int32(a), int32(b)))

func `-`*(a, b: SatQ31): SatQ31 {.inline.} =
  SatQ31(saturatingSub(int32(a), int32(b)))

func `-`*(value: SatQ31): SatQ31 {.inline.} =
  if int32(value) == low(int32): SatQ31(high(int32))
  else: SatQ31(-int32(value))

func `*`*(a, b: SatQ31): SatQ31 {.
  importcpp: "opxy::q31::multiply(@)",
  header: "opxy/q31.hpp",
  inline.}

func saturatingAdd*(a, b: Q31): SatQ31 {.inline.} =
  SatQ31(saturatingAdd(int32(a), int32(b)))

func saturatingSub*(a, b: Q31): SatQ31 {.inline.} =
  SatQ31(saturatingSub(int32(a), int32(b)))

func saturatingAdd*(a, b: SatQ31): SatQ31 {.inline.} =
  SatQ31(saturatingAdd(int32(a), int32(b)))

func saturatingSub*(a, b: SatQ31): SatQ31 {.inline.} =
  SatQ31(saturatingSub(int32(a), int32(b)))

func half*(value: Q31): Q31 {.
  importcpp: "opxy::q31::half(@)",
  header: "opxy/q31.hpp",
  inline.}

func half*(value: SatQ31): SatQ31 {.
  importcpp: "opxy::q31::half(@)",
  header: "opxy/q31.hpp",
  inline.}

func `$`*(value: Q31): string = $int32(value)
func `$`*(value: SatQ31): string = $int32(value)
