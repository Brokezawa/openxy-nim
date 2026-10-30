# Build and generation

The current SDK pin is tag `v0.0.3` at commit `17840e3`, with SDK API 1.6 and
firmware 1.2.1. The profile and stock OS names are part of the generated build.

## Template ownership

Each machine template owns its tasks in `config.nims` and its dependency
metadata in a `.nimble` file. There is no `openxy` CLI, no `openxy.json`, and no
setup task. A template declares explicit constants:

```nim
const
  machineId = "mysynth"
  machineSource = "src/mysynth.nim"
  buildRoot = "build"
  stockOs = ""
  layout = ""
```

The shared implementation lives in `scripts/template_tasks.nims`; the template
tasks delegate to it. This keeps the task names in the template while avoiding
copy-pasted build logic.

## The two phases

1. `prepare` validates the JSON, runs a host probe for `sizeof`/`alignof`,
   refuses mismatched layouts, writes the SDK folder, opaque headers, adapter
   C++, vendor files, and the generated Nim wrapper.
2. `nim gen` uses `setCommand("cpp", wrapper)` with a build-local nimcache and
   `--compileOnly`. NimScript queues that command until the script exits, so
   `preview`, `compile`, and `build` invoke `nim gen` as a subprocess. When it
   returns, `package` reads `nimcache/wrapper.json`, concatenates the generated
   C++ translation units, deduplicates shared type/inline-helper definitions,
   writes `vendor/openxy/machine.cpp`, and removes the nimcache.

The generated folder is:

```
build/<kind>/<id>/
  machine.json
  definition.json
  panel.svg.fragment
  core.h
  engine.cpp
  display.h
  display.cpp
  maybe sample.h/.cpp or fx.h/.cpp
  generated/machine.cpp   # lint-clean include shim
  generated/wrapper.nim
  vendor/openxy/
    machine.cpp           # packaged, deduplicated Nim C++
    nimbase.h             # unmodified compiler copy
    openxy_nimbase.h
    warnings.hpp
  string.h
  limits.h
```

Source `definition.json` is never rewritten. The build copy replaces only the
measured layout fields (`voiceBytes`, `voiceAlignment`, `sharedBytes`,
`display.stateBytes`, `display.stateAlignment`) and preserves authored
controls, presets, capacity, output peak, display budget, and sample services.

## Native ABI

The wrapper is a normal Nim module compiled with the C++ backend:

- `--cppCompileToNamespace:<machineId>`
- `--nimMainPrefix:<machineId>_`
- unqualified `{.exportcpp: "initialize".}` names inside that namespace

The generated headers use opaque `alignas` byte arrays for `Voice`, `Shared`,
`State`, `DisplayState`, and `Preparation`, plus the concrete `Frame` alias.
Nim `importcpp` aliases provide the SDK typedefs and const-reference parameters.
The wrapper casts SDK-owned storage to the machine's plain Nim types and checks
sizes/alignment before code generation. It constructs `WordView` and `Buffer`
from the SDK pointers and counts, so machine code receives safe views rather
than raw pointers.

Saturating Q31 add/sub are pure Nim 32-bit arithmetic. Multiply and half use
the SDK inline helpers through `importcpp`. No C++ `q31_ops` shim is generated.

## Profiles

Host tests keep checks enabled and compile with the C++ backend and the SDK
include path. The device wrapper uses:

```
--os:any --cpu:arm --mm:arc --exceptions:quirky
--checks:off --panics:off --threads:off --stackTrace:off --lineTrace:off
-d:useMalloc -d:nimPreviewSlimSystem -d:noSignalHandler -d:release
```

`--os:any` avoids standalone's mandatory `panicoverride`; `quirky` avoids the
libc `_exit`/`_free` path; checks and panics off avoid libc formatting.
`--nimBasePattern:vendor/openxy/openxy_nimbase.h` selects a wrapper that defines
`HAVE_STDINT_H` and includes an unmodified `nimbase.h` copy. The installed Nim
header is never patched. `string.h` declares the SDK's freestanding memcpy and
memset.

## SDK commands

The template task maps to:

```sh
python3 <sdk>/sdk.py preview --machine <generated> --out <out>
python3 <sdk>/sdk.py compile --machine <generated> --out <out>
python3 <sdk>/sdk.py build --machine <generated> --out <out> --stock-os <os>
```

`preview` requires Python 3.10+, NumPy, Node, and a wasm-capable Clang. It is
available for synth machines only; sample engines and effects have no browser
preview. `compile` requires the pinned Blackfin toolchain (`python3 sdk.py
toolchain fetch`). `build` additionally requires the stock OS image and stock
content catalog. The SDK is the final authority on identity, registration,
memory, and package validity.

An effect needs a synth or sample engine in the same collection because the
stock startup table requires at least one non-effect machine. Compile or build
a collection by repeating `--machine` (or by passing a collection JSON):

```sh
python3 <sdk>/sdk.py compile \
  --machine build/synth/mysynth \
  --machine build/sample/mysample \
  --machine build/effect/myeffect \
  --out <out>
```

The template `stockOs` and optional `layout` constants are passed to
`sdk.py build`. `layout.json` is written next to the package's candidate files;
use it to keep machine numbers stable across builds.

Generated Nim C++ stays under `vendor/openxy/` because the SDK's contributor
lint rejects conditional compilation and platform primitives outside `vendor`.
The `generated/machine.cpp` file is only a one-line include shim.
