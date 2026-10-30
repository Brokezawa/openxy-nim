// Reference probe for the SDK double-tap gesture. The Nim test drives the
// same sequence and compares the printed results.
#include <opxy/double_tap.hpp>
#include <cstdio>

using opxy::extensions::DoubleTap;

static void press(DoubleTap& tap, unsigned long long time, bool unmodified) {
    std::printf("press=%d\n", tap.press(time, unmodified) ? 1 : 0);
}

static void release(DoubleTap& tap, unsigned long long time) {
    std::printf("release=%d\n", tap.release(time) ? 1 : 0);
}

int main() {
    DoubleTap tap;
    press(tap, 0, true);
    release(tap, 50000);
    press(tap, 100000, true);
    release(tap, 150000);
    release(tap, 200000);
    press(tap, 300000, true);
    release(tap, 600000);
    press(tap, 700000, true);
    release(tap, 720000);
    press(tap, 800000, true);
    release(tap, 850000);
    press(tap, 1300000, true);
    release(tap, 1350000);
    press(tap, 1400000, false);
    release(tap, 1450000);
    return 0;
}
