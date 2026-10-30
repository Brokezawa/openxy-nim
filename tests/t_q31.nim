import std/assertions

import openxy

block wrapping_add:
  doAssert (Q31Max + Q31(1)) == Q31Min
  doAssert (Q31Min - Q31(1)) == Q31Max

block saturating_add:
  doAssert (SatQ31Max + SatQ31(1)) == SatQ31Max
  doAssert (SatQ31Min - SatQ31(1)) == SatQ31Min

block mixed_promotion:
  let promoted: SatQ31 = Q31Max
  doAssert promoted == SatQ31Max
  doAssert (Q31Max + SatQ31(1)) == SatQ31Max
  doAssert (SatQ31Max + Q31(1)) == SatQ31Max

block saturating_multiply:
  doAssert (Q31Max * Q31Max) == Q31(2147483646)
  doAssert (Q31Min * Q31Min) == Q31Max
  doAssert (SatQ31Min * SatQ31Min) == SatQ31Max

block explicit_demotion:
  let wrapped = toQ31(SatQ31Max)
  doAssert wrapped == Q31Max

block helpers:
  doAssert saturatingAdd(Q31Max, Q31(1)) == SatQ31Max
  doAssert saturatingSub(Q31Min, Q31(1)) == SatQ31Min
  doAssert half(Q31(3)) == Q31(1)
  doAssert half(Q31(-3)) == Q31(-2)

block generic_contract:
  proc twice[T: Q31Like](value: T): T = value + value
  doAssert twice(Q31(2)) == Q31(4)
  doAssert twice(SatQ31Max) == SatQ31Max
  doAssert toInt32(twice(Q31(2))) == 4

block boundary_subtraction:
  doAssert saturatingSub(0'i32, low(int32)) == high(int32)
  doAssert saturatingSub(low(int32), 0'i32) == low(int32)
  doAssert saturatingAdd(high(int32), 0'i32) == high(int32)
  doAssert saturatingAdd(low(int32), -1'i32) == low(int32)

block half_and_bits:
  doAssert Q31Half == Q31(0x4000_0000)
  doAssert toInt32(Q31Half) == 0x4000_0000
  doAssert toUint32(Q31(-1)) == 0xFFFF_FFFF'u32
  doAssert toUint32(Q31Min) == 0x8000_0000'u32
  doAssert toUint32(Q31Max) == 0x7FFF_FFFF'u32

block q15_conversion:
  doAssert fromQ15(32767) == Q31(0x3FFF_8000)
  doAssert fromQ15(-32768) == Q31(-0x4000_0000)
  doAssert fromQ15(0) == Q31(0)

block enum_lookup:
  type Control = enum blend, width, level
  let values = [Q31(1), Q31(2), Q31(3)]
  doAssert values[blend] == Q31(1)
  doAssert values[width] == Q31(2)
  doAssert values[level] == Q31(3)
  type TooMany = enum a, b, c, d
  doAssertRaises(IndexDefect):
    discard values[d]
