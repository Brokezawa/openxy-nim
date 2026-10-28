// Reference probe for the SDK 1.4 two-row page header. The Nim test prints
// the same fields and compares the output.
#include <opxy/page_header.hpp>
#include <cstdio>

using namespace opxy::draw;
using opxy::u8;

static void emit(const Frame<2, 64, 10, 16, 16>& frame) {
    std::printf("node=%d,%d,%d text0=%s text8=%s header0=%s\n",
                frame.nodes[2].x, frame.nodes[2].y, frame.nodes[2].scale,
                frame.texts[0].chars, frame.texts[8].chars, frame.header[0]);
}

int main() {
    PageHeader state;
    state.reset();
    Frame<2, 64, 10, 16, 16> frame = {};
    const char* const titles[8] = {"One", "Two", "Three", "Four",
                                   "Five", "Six", "Seven", "Eight"};
    char values[8][header_capacity] = {};
    for (unsigned i = 0; i < 8; ++i)
        header_amount(values[i], header_capacity, 0x40000000);
    const u8 slots[2][4] = {{0, 1, 2, 3}, {4, 5, 6, 7}};
    Input input = {};
    emit(frame);
    for (unsigned i = 0; i < 4; ++i) input.shown[i] = static_cast<u8>(i + 4);
    input.elapsed = 16;
    page_header(state, input, frame, titles, values, 2, slots);
    emit(frame);
    page_header(state, input, frame, titles, values, 2, slots);
    emit(frame);
    input.elapsed = 154;
    page_header(state, input, frame, titles, values, 2, slots);
    emit(frame);
    ++input.track;
    page_header(state, input, frame, titles, values, 2, slots);
    emit(frame);
    for (unsigned i = 0; i < 4; ++i) input.shown[i] = static_cast<u8>(i);
    input.reduced_motion = 1;
    page_header(state, input, frame, titles, values, 2, slots);
    emit(frame);
    return 0;
}
