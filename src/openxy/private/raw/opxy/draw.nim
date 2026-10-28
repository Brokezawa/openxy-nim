## Concrete raw draw surface. Henka cannot instantiate the SDK's `Path` and
## `Frame` templates, so this module uses the largest SDK shapes as concrete
## storage. The generated wrapper uses the typed public mirrors instead.

type
  Paint* {.size: sizeof(uint32), pure, importcpp: "Paint",
    header: "opxy/draw.hpp".} = enum
    keep = 0
    stroke = 1
    fill_and_stroke = 2

  Point* {.importcpp: "opxy::draw::Point", header: "opxy/draw.hpp".} = object
    x*: int32
    y*: int32

  Turn* {.importcpp: "opxy::draw::Turn", header: "opxy/draw.hpp".} = object
    cos*: int32
    sin*: int32

  Path* {.importcpp: "opxy::draw::Path<64>", header: "opxy/draw.hpp".} = object
    key*: uint32
    points*: array[64, Point]

  Node* {.importcpp: "opxy::draw::Node", header: "opxy/draw.hpp".} = object
    x*: int32
    y*: int32
    scale*: int32
    cos*: int32
    sin*: int32
    shade*: uint32
    paint*: Paint

  Text* {.importcpp: "opxy::draw::Text", header: "opxy/draw.hpp".} = object
    x*: int32
    y*: int32
    scale*: int32
    chars*: array[24, char]

  Frame* {.importcpp: "opxy::draw::Frame<4, 64, 256, 4, 16>",
    header: "opxy/draw.hpp".} = object
    paths*: array[4, Path]
    nodes*: array[256, Node]
    texts*: array[16, Text]
    header*: array[4, array[8, char]]

  Input* {.importcpp: "opxy::draw::Input", header: "opxy/draw.hpp".} = object
    parameters*: array[4, int32]
    elapsed*: int32
    track*: uint32
    note_serial*: uint32
    reduced_motion*: uint32
    shown*: array[4, uint8]
    slots*: array[8, int32]
    held_notes*: uint32
    note_off_serial*: uint32

  NoteEvents* {.importcpp: "opxy::draw::NoteEvents",
    header: "opxy/draw.hpp".} = object
    hold_started*: bool
    hold_ended*: bool
    note_released*: bool

  NoteTracker* {.importcpp: "opxy::draw::NoteTracker",
    header: "opxy/draw.hpp".} = object
    initialized*: uint32
    track*: uint32
    held_notes*: uint32
    note_off_serial*: uint32

const
  unit*: int32 = 1024
  path_extent*: int32 = 64
  node_left*: int32 = -64
  node_right*: int32 = 640
  node_top*: int32 = -64
  node_bottom*: int32 = 320
  hidden_x*: int32 = 640
  hidden_y*: int32 = 320
  text_capacity*: uint32 = 24
  header_capacity*: uint32 = 8
  notes_unavailable*: uint32 = 0xffffffff'u32

proc reset*(tracker: var NoteTracker) {.
  importcpp: "#.reset(@)", header: "opxy/draw.hpp".}
proc update*(tracker: var NoteTracker; input: Input): NoteEvents {.
  importcpp: "#.update(@)", header: "opxy/draw.hpp".}
proc floor_q10*(value: int32): int32 {.
  importcpp: "opxy::draw::floor_q10(@)", header: "opxy/draw.hpp".}
proc clamp*(value, low, high: int32): int32 {.
  importcpp: "opxy::draw::clamp(@)", header: "opxy/draw.hpp".}
proc place*[F](frame: var F; node: uint32; x, y, scale: int32;
               shade: uint32; paint: Paint) {.
  importcpp: "opxy::draw::place<'*0>(@)", header: "opxy/draw.hpp".}
proc hide*[F](frame: var F; node: uint32) {.
  importcpp: "opxy::draw::hide<'*0>(@)", header: "opxy/draw.hpp".}
proc shade*[F](frame: var F; node: uint32; shade: uint32; paint: Paint) {.
  importcpp: "opxy::draw::shade<'*0>(@)", header: "opxy/draw.hpp".}
proc turn*[F](frame: var F; node: uint32; value: Turn) {.
  importcpp: "opxy::draw::turn<'*0>(@)", header: "opxy/draw.hpp".}
proc copy*(output: cstring; capacity: uint32; input: cstring) {.
  importcpp: "opxy::draw::copy(@)", header: "opxy/draw.hpp".}
proc text*[F](frame: var F; slot: uint32; x, y, scale: int32; input: cstring) {.
  importcpp: "opxy::draw::text<'*0>(@)", header: "opxy/draw.hpp".}
proc header*[F](frame: var F; position: uint32; input: cstring) {.
  importcpp: "opxy::draw::header<'*0>(@)", header: "opxy/draw.hpp".}
proc sine*(tenths: int32): int32 {.
  importcpp: "opxy::draw::sine(@)", header: "opxy/draw.hpp".}
proc rotation*(tenths: int32): Turn {.
  importcpp: "opxy::draw::rotation(@)", header: "opxy/draw.hpp".}
proc sweep*(value, half: int32): Turn {.
  importcpp: "opxy::draw::sweep(@)", header: "opxy/draw.hpp".}
proc terminated*(text: cstring; capacity: uint32): bool {.
  importcpp: "opxy::draw::terminated(@)", header: "opxy/draw.hpp".}
proc placement*(x, y, scale: int32): bool {.
  importcpp: "opxy::draw::placement(@)", header: "opxy/draw.hpp".}
proc rotation_valid*(cos, sin: int32): bool {.
  importcpp: "opxy::draw::rotation_valid(@)", header: "opxy/draw.hpp".}
proc valid*[F](frame: F): bool {.
  importcpp: "opxy::draw::valid<'*0>(@)", header: "opxy/draw.hpp".}
