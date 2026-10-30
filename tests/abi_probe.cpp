#include <cstddef>
#include <opxy/audio.hpp>
#include <opxy/draw.hpp>
#include <opxy/effect.hpp>
#include <opxy/extension.hpp>
#include <opxy/sample_analysis.hpp>
#include <opxy/sample_engine.hpp>
#include <opxy/transport.hpp>

static_assert(sizeof(opxy::draw::Point) == 8, "Point layout");
static_assert(sizeof(opxy::draw::Turn) == 8, "Turn layout");
static_assert(sizeof(opxy::draw::Node) == 28, "Node layout");
static_assert(sizeof(opxy::draw::Text) == 36, "Text layout");
static_assert(sizeof(opxy::draw::Input) == 76, "Input layout");
static_assert(sizeof(opxy::draw::NoteTracker) == 16, "NoteTracker layout");
static_assert(sizeof(opxy::draw::Frame<2, 64, 2, 0, 16>) == 1156, "Frame layout");
static_assert(sizeof(opxy::draw::Frame<0, 0, 2, 0, 16>) == 128, "empty Frame layout");
static_assert(offsetof(opxy::draw::Input, elapsed) == 16, "Input elapsed offset");
static_assert(offsetof(opxy::draw::Input, held_notes) == 68, "Input held offset");
static_assert(sizeof(opxy::SampleRegion) == 20, "SampleRegion layout");
static_assert(sizeof(opxy::PadSettings) == 4, "PadSettings layout");
static_assert(sizeof(opxy::DrumControl) == 12, "DrumControl layout");
static_assert(sizeof(opxy::DrumPanel) == 44, "DrumPanel layout");
static_assert(sizeof(opxy::Transport) == 12, "Transport layout");
static_assert(sizeof(opxy::SampleBlock) == (sizeof(void*) == 8 ? 80 : 64), "SampleBlock layout");

static_assert(sizeof(opxy::SampleView) == (sizeof(void*) == 8 ? 24 : 16), "SampleView layout");
static_assert(sizeof(opxy::SampleAssignment) == (sizeof(void*) == 8 ? 40 : 32),
              "SampleAssignment layout");
static_assert(sizeof(opxy::SampleAnalysis) == (sizeof(void*) == 8 ? 40 : 28),
              "SampleAnalysis layout");
static_assert(sizeof(opxy::Buffer) == (sizeof(void*) == 8 ? 16 : 8), "Buffer layout");

using namespace opxy::extensions;
static_assert(sizeof(RecordingContext) == 28, "RecordingContext layout");
static_assert(sizeof(Context) == 32, "Context layout");
static_assert(sizeof(Note) == 12, "Note layout");
static_assert(sizeof(LiveNote) == 20, "LiveNote layout");
static_assert(sizeof(NoteOff) == 8, "NoteOff layout");
static_assert(sizeof(Tick) == 8, "Tick layout");
static_assert(sizeof(Control) == 16, "Control layout");
static_assert(sizeof(Actions) == (sizeof(void*) == 8 ? 24 : 12), "Actions layout");
static_assert(sizeof(Hooks) == (sizeof(void*) == 8 ? 48 : 24), "Hooks layout");
static_assert(offsetof(Note, position) == 0, "Note position offset");
static_assert(offsetof(Note, length) == 4, "Note length offset");
static_assert(offsetof(Note, pitch) == 8, "Note pitch offset");
static_assert(offsetof(Note, velocity) == 9, "Note velocity offset");
