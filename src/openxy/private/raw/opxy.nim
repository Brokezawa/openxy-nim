## Raw OP-XY bindings generated from the pinned SDK headers by Henka.
##
## Henka does not instantiate C++ class templates or evaluate every static
## constant. The checked-in result therefore carries the small normalization
## patch in `henka.patch` (concrete raw draw storage and const initializers).
## `nim regen` regenerates the upstream output and applies that patch.

import openxy/private/raw/opxy/[types, audio, q31, draw, sample, sample_engine,
  sample_analysis, effect, transport]

export types, audio, q31, draw, sample, sample_engine, sample_analysis, effect,
  transport
