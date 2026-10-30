// 32-bit layout probe for the extension API. Compiled with a freestanding
// i386 target by tests/t_extension_abi.nim.
#include <opxy/extension.hpp>

using namespace opxy::extensions;

static_assert(sizeof(void*) == 4, "32-bit target");
static_assert(sizeof(RecordingContext) == 28, "RecordingContext layout");
static_assert(sizeof(Context) == 32, "Context layout");
static_assert(sizeof(Note) == 12, "Note layout");
static_assert(sizeof(LiveNote) == 20, "LiveNote layout");
static_assert(sizeof(NoteOff) == 8, "NoteOff layout");
static_assert(sizeof(Tick) == 8, "Tick layout");
static_assert(sizeof(Control) == 16, "Control layout");
static_assert(sizeof(Actions) == 12, "Actions layout");
static_assert(sizeof(Hooks) == 24, "Hooks layout");
