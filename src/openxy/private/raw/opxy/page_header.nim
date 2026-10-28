## Raw SDK 1.4 page-header surface. The generated C++ template is not usable
## through the plain Nim `Frame` mirror, so the public helper is pure Nim. This
## raw module keeps the pinned type and constants available for provenance.

type
  PageHeader* {.importcpp: "opxy::draw::PageHeader",
    header: "opxy/page_header.hpp".} = object
    initialized*: uint32
    track*: uint32
    page*: uint32
    position*: int32
    elapsed*: int32

const
  page_header_nodes*: uint32 = 8
  page_header_texts*: uint32 = 16
  page_header_slots*: array[2, array[4, uint8]] = [[0, 1, 2, 3], [4, 5, 6, 7]]

proc reset*(state: var PageHeader) {.
  importcpp: "#.reset(@)", header: "opxy/page_header.hpp".}

proc header_amount*(output: cstring; capacity: uint32; value: int32) {.
  importcpp: "opxy::draw::header_amount(@)", header: "opxy/page_header.hpp".}
