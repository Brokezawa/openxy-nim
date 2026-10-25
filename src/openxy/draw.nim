## Retained display frame, input snapshot, and drawing helpers.
##
## This is a plain Nim mirror of `opxy/draw.hpp`. The generated adapter casts
## SDK-owned storage to these types.

import openxy/audio
import openxy/q31
import openxy/units

const
  Unit* = UnitQ10
  PathExtent* = 64
  NodeLeft* = -64
  NodeRight* = 640
  NodeTop* = -64
  NodeBottom* = 320
  HiddenX* = Q10(NodeRight * 1024)
  HiddenY* = Q10(NodeBottom * 1024)
  TextCapacity* = 24
  HeaderCapacity* = 8
  NotesUnavailable* = 0xffffffff'u32

type
  Point* = object
    x*, y*: int32

  Turn* = object
    cos*, sin*: int32

  Path*[Points: static int] = object
    key*: uint32
    points*: array[Points, Point]

  Node* = object
    x*, y*, scale*, cos*, sin*: int32
    shade*: uint32
    paint*: Paint

  Text* = object
    x*, y*, scale*: int32
    chars*: array[TextCapacity, char]

  Frame*[Paths, Points, Nodes, Texts, Palette: static int] = object
    paths*: array[max(Paths, 1), Path[Points]]
    nodes*: array[Nodes, Node]
    texts*: array[max(Texts, 1), Text]
    header*: array[PageControls, array[HeaderCapacity, char]]

  Input* = object
    parameters*: array[PageControls, Q31]
    elapsed*: Q10
    track*: uint32
    noteSerial*: uint32
    reducedMotion*: uint32
    shown*: array[PageControls, uint8]
    slots*: array[ParameterSlots, Q31]
    heldNotes*: uint32
    noteOffSerial*: uint32

  NoteEvents* = object
    holdStarted*, holdEnded*, noteReleased*: bool

  NoteTracker* = object
    initialized*: uint32
    track*: uint32
    heldNotes*: uint32
    noteOffSerial*: uint32

template noteOnSerial*(input: Input): uint32 = input.noteSerial

func reset*(tracker: var NoteTracker) {.inline.} =
  tracker.initialized = 0

func update*(tracker: var NoteTracker; input: Input): NoteEvents =
  result = NoteEvents()
  if input.heldNotes > 128:
    tracker.initialized = 0
    return
  if tracker.initialized != 0 and tracker.track == input.track:
    result.holdStarted = tracker.heldNotes == 0 and input.heldNotes != 0
    result.holdEnded = tracker.heldNotes != 0 and input.heldNotes == 0
    result.noteReleased = tracker.noteOffSerial != input.noteOffSerial
  tracker.initialized = 1
  tracker.track = input.track
  tracker.heldNotes = input.heldNotes
  tracker.noteOffSerial = input.noteOffSerial

func clampQ10*(value, low, high: int32): int32 {.inline.} =
  if value < low: low
  elif value > high: high
  else: value

func q10Pixels*(pixels: int32): Q10 {.inline.} = q10(pixels)

func place*[Paths, Points, Nodes, Texts, Palette](
    frame: var Frame[Paths, Points, Nodes, Texts, Palette];
    node: int;
    x, y, scale: Q10;
    shade: uint32;
    paint = PaintKeep;
) =
  if node < 0 or node >= Nodes:
    return
  let destination = addr frame.nodes[node]
  destination.x = int32(x)
  destination.y = int32(y)
  destination.scale = int32(scale)
  destination.cos = int32(Unit)
  destination.sin = 0
  destination.shade = shade
  destination.paint = paint

func hide*[Paths, Points, Nodes, Texts, Palette](
    frame: var Frame[Paths, Points, Nodes, Texts, Palette]; node: int;
) =
  place(frame, node, HiddenX, HiddenY, Unit, 0, PaintKeep)

func shade*[Paths, Points, Nodes, Texts, Palette](
    frame: var Frame[Paths, Points, Nodes, Texts, Palette];
    node: int;
    shade: uint32;
    paint: Paint;
) =
  if node < 0 or node >= Nodes:
    return
  frame.nodes[node].shade = shade
  frame.nodes[node].paint = paint

func turn*[Paths, Points, Nodes, Texts, Palette](
    frame: var Frame[Paths, Points, Nodes, Texts, Palette]; node: int; value: Turn;
) =
  if node < 0 or node >= Nodes:
    return
  frame.nodes[node].cos = value.cos
  frame.nodes[node].sin = value.sin

func copyText(destination: var openArray[char]; source: openArray[char]) =
  var index = 0
  while index + 1 < destination.len and index < source.len and source[index] != '\0':
    destination[index] = source[index]
    inc index
  while index < destination.len:
    destination[index] = '\0'
    inc index

func text*[Paths, Points, Nodes, Texts, Palette](
    frame: var Frame[Paths, Points, Nodes, Texts, Palette];
    slot: int;
    x, y, scale: Q10;
    value: openArray[char];
) =
  if slot < 0 or slot >= Texts:
    return
  let destination = addr frame.texts[slot]
  destination.x = int32(x)
  destination.y = int32(y)
  destination.scale = int32(scale)
  copyText(destination.chars, value)

func header*[Paths, Points, Nodes, Texts, Palette](
    frame: var Frame[Paths, Points, Nodes, Texts, Palette];
    position: int;
    value: openArray[char];
) =
  if position < 0 or position >= PageControls:
    return
  copyText(frame.header[position], value)

const sineQ10*: array[91, uint16] = [
  0, 18, 36, 54, 71, 89, 107, 125, 143, 160, 178, 195, 213, 230, 248,
  265, 282, 299, 316, 333, 350, 367, 384, 400, 416, 433, 449, 465, 481,
  496, 512, 527, 543, 558, 573, 587, 602, 616, 630, 644, 658, 672, 685,
  698, 711, 724, 737, 749, 761, 773, 784, 796, 807, 818, 828, 839, 849,
  859, 868, 878, 887, 896, 904, 912, 920, 928, 935, 943, 949, 956, 962,
  968, 974, 979, 984, 989, 994, 998, 1002, 1005, 1008, 1011, 1014, 1016,
  1018, 1020, 1022, 1023, 1023, 1024, 1024,
]

func sine*(tenths: int32): int32 =
  var angle: int32 = tenths mod 3600
  if angle < 0:
    angle += 3600
  let sign = if angle >= 1800: -1 else: 1
  angle = angle mod 1800
  if angle > 900:
    angle = 1800 - angle
  let degree = angle div 10
  let fraction = angle mod 10
  let low = int32(sineQ10[degree])
  let high = int32(sineQ10[if degree < 90: degree + 1 else: 90])
  int32(sign) * (low + (high - low) * fraction div 10)

func rotation*(tenths: int32): Turn =
  Turn(cos: sine(tenths + 900), sin: sine(tenths))

func sweep*(value: Q31; half: int32): Turn =
  var control = int32(value)
  if control < 0:
    control = 0
  let bound = clampQ10(half, 0, 1800)
  let scaled = (control div 65536) * 2 * bound div 32767
  rotation(-bound + scaled)

func terminated*(value: openArray[char]): bool =
  for character in value:
    if character == '\0':
      return true

func placement*(x, y, scale: Q10): bool =
  int32(x) >= NodeLeft * 1024 and int32(x) <= NodeRight * 1024 and
    int32(y) >= NodeTop * 1024 and int32(y) <= NodeBottom * 1024 and
    int32(scale) > 0 and int32(scale) <= 2 * 1024

func rotationValid*(value: Turn): bool =
  if value.cos < -1024 or value.cos > 1024 or value.sin < -1024 or value.sin > 1024:
    return false
  let length = value.cos * value.cos + value.sin * value.sin
  length >= 1024 * 1024 div 16 * 15 and length <= 1024 * 1024 div 16 * 17

func valid*[Paths, Points, Nodes, Texts, Palette](
    frame: Frame[Paths, Points, Nodes, Texts, Palette];
): bool =
  for path in 0 ..< Paths:
    if frame.paths[path].key == 0:
      return false
    for point in 0 ..< Points:
      let value = frame.paths[path].points[point]
      if value.x < -PathExtent * 1024 or value.x > PathExtent * 1024 or
          value.y < -PathExtent * 1024 or value.y > PathExtent * 1024:
        return false
  for node in 0 ..< Nodes:
    let value = frame.nodes[node]
    if not placement(Q10(value.x), Q10(value.y), Q10(value.scale)) or
        not rotationValid(Turn(cos: value.cos, sin: value.sin)) or
        value.shade >= uint32(Palette) or uint32(value.paint) > uint32(PaintFillAndStroke):
      return false
  for slot in 0 ..< Texts:
    let value = frame.texts[slot]
    if not placement(Q10(value.x), Q10(value.y), Q10(value.scale)) or
        not terminated(value.chars):
      return false
  for position in 0 ..< PageControls:
    if not terminated(frame.header[position]):
      return false
  true
