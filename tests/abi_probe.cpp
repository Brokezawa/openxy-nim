#include <cstddef>
#include <opxy/audio.hpp>
#include <opxy/draw.hpp>
#include <opxy/effect.hpp>
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
