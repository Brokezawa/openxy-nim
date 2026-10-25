## Raw SDK C++ helpers used by the public layer.
##
## The checked-in bindings are intentionally small: the machine ABI is exposed
## through the generated wrapper, while only SDK typedefs and inline arithmetic
## belong here. `scripts/regen.nims` can replace this surface with Henka output
## when the optional `regen` feature is installed.

import openxy/q31

type
  COutput* {.importcpp: "opxy::Output", header: "opxy/audio.hpp".} = object
  CParameters* {.importcpp: "opxy::Parameters", header: "opxy/audio.hpp".} = object
  CPitch* {.importcpp: "opxy::Pitch", header: "opxy/audio.hpp".} = object
  CInput* {.importcpp: "opxy::draw::Input", header: "opxy/draw.hpp".} = object
  CConstInput* {.importcpp: "const opxy::draw::Input&", header: "opxy/draw.hpp".} = object
  CSampleView* {.importcpp: "opxy::SampleView", header: "opxy/sample.hpp".} = object
  CConstSampleView* {.importcpp: "const opxy::SampleView&",
    header: "opxy/sample.hpp".} = object
  CSampleBlock* {.importcpp: "opxy::SampleBlock",
    header: "opxy/sample_engine.hpp".} = object
  CConstSampleBlock* {.importcpp: "const opxy::SampleBlock&",
    header: "opxy/sample_engine.hpp".} = object
  CEffectBuffer* {.importcpp: "opxy::Buffer", header: "opxy/effect.hpp".} = object
  CEffectChannel* {.importcpp: "opxy::Channel", header: "opxy/effect.hpp".} = object

func sdkMultiply*(a, b: Q31): Q31 {.
  importcpp: "opxy::q31::multiply(@)",
  header: "opxy/q31.hpp",
  inline.
.}

func sdkHalf*(value: Q31): Q31 {.
  importcpp: "opxy::q31::half(@)",
  header: "opxy/q31.hpp",
  inline.
.}
