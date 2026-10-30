## A minimal OP-XY extension: show a popup on a Record double-tap.

import openxy

var tap: DoubleTap

proc resetGesture*() =
  ## Test helper: clear the gesture without changing the module state shape.
  tap = DoubleTap()

proc queuedControl(context: Context; control: Control; actions: Actions)
    {.cdecl, raises: [].} =
  if control.key != RecordKey:
    tap.cancel()
    return
  if control.pressed:
    discard tap.press(control.time, control.unmodified)
  elif tap.release(control.time):
    discard actions.notify("nim extension")

const hooks* = initHooks().withQueuedControl(queuedControl)
