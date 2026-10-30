import std/assertions

import openxy
import mynotify

var notifications: seq[string]

proc fakeInsert(raw: pointer; context: Context; track: uint32;
                notes: ptr UncheckedArray[Note]; count: uint32): uint32
    {.cdecl, raises: [].} = 0

proc fakeReplace(raw: pointer; context: Context; track: uint32;
                 notes: ptr UncheckedArray[Note]; count: uint32): uint32
    {.cdecl, raises: [].} = 0

proc fakeNotify(raw: pointer; text: cstring): bool {.cdecl, raises: [].} =
  notifications.add($text)
  true

let actions = initActions(nil, fakeInsert, fakeReplace, fakeNotify)
let context = Context()
var clock = 0'u64

proc event(pressed: bool; key = RecordKey; elapsed = 50_000'u64;
           unmodified = true) =
  clock += elapsed
  hooks.queuedControl(context,
    Control(key: key, pressed: pressed, accepted: true,
      unmodified: unmodified, time: Time(clock)), actions)

block single_tap:
  resetGesture()
  notifications.setLen(0)
  event(true)
  event(false)
  doAssert notifications.len == 0

block double_tap:
  resetGesture()
  notifications.setLen(0)
  event(true)
  event(false)
  event(true)
  event(false)
  doAssert notifications == @["nim extension"]

block hold:
  resetGesture()
  notifications.setLen(0)
  event(true)
  event(false, elapsed = 300_000)
  doAssert notifications.len == 0

block repeat:
  resetGesture()
  notifications.setLen(0)
  event(true)
  event(true, elapsed = 10_000)
  event(false)
  doAssert notifications.len == 0

block timeout:
  resetGesture()
  notifications.setLen(0)
  event(true)
  event(false)
  event(true, elapsed = 400_000)
  event(false)
  doAssert notifications.len == 0

block other_key_cancels:
  resetGesture()
  notifications.setLen(0)
  event(true)
  event(true, key = 1)
  event(false, key = 1)
  event(false)
  doAssert notifications.len == 0
