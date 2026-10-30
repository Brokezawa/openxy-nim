# My Synth

A synth machine for the OP-XY, written in Nim with `openxy`.

## Set up

Install the openxy dependency and the pinned SDK:

```sh
atlas init
atlas install
git -C deps/openxy submodule update --init --recursive
```

If you copied this template into an existing project, install the dependency
into that project instead:

```sh
atlas use https://github.com/Brokezawa/openxy-nim
atlas install
```

## Edit

- `config.nims` owns `machineId`, `machineSource`, `buildRoot`, `stockOs`,
  `layout`, and the task names.
- `machine.json` declares the SDK version, kind, description, and optional
  services. SDK 1.5+ machines have no `identity`; the build layout gives them
  engine and page numbers. Set `layout` to the previous `layout.json` to keep
  existing numbers.
- `definition.json` owns the controls, presets, and resource budget. Do not
  hand-edit the generated copy under `build/`.
- `src/mysynth.nim` implements `Voice`, `Shared`, `DisplayState`, `Frame`, and
  the callback procs. `openxyValidate(mkSynth, Voice, Shared)` checks the
  callback shapes. The source uses a `Control` enum, named phase/display
  constants, and no `cast`, `ptr`, or `addr`.
- `panel.svg.fragment` is the artwork for the two display nodes and palette.

The machine ID must be a lowercase letter followed by lowercase letters, digits,
or underscores, at most 15 characters. It cannot be an SDK stock name, a C++ or
Nim keyword, a reserved prefix, or a name that differs from the source filename.

## Build

```sh
# In this repository, add --skipParentCfg:on so the maintainer tasks in the
# parent checkout do not shadow the template tasks.
nim test       # host tests, checks enabled
nim gen        # validate, measure, prepare, compile into build/.../nimcache
nim preview    # browser preview through sdk.py
nim compile    # Blackfin development module
nim build      # firmware package; edit stockOs first
nim clean
```

`nim preview`/`compile`/`build` run `nim gen` in a subprocess, package the
generated C++, and only then call `sdk.py`. For `nim build`, set `stockOs` to
the stock OP-XY OS image and optionally `layout` to the `layout.json` from your
previous build.

## Callback names

A synth implements the ordinary SDK callback names in Nim:

```nim
proc initialize*(voice: var Voice; shared: var Shared; owner: VoiceId) {.raises: [].}
proc start*(voice: var Voice; shared: var Shared; owner: VoiceId) {.raises: [].}
proc destroy*(voice: var Voice; shared: var Shared; owner: VoiceId) {.raises: [].}
proc render*(voice: var Voice; shared: var Shared; owner: VoiceId;
             output: var openArray[Q31]; parameters: openArray[Q31];
             pitch: openArray[PhaseIncrement]) {.raises: [].}
proc displayReset*(state: var DisplayState) {.raises: [].}
proc display*(state: var DisplayState; input: Input; frame: var Frame) {.raises: [].}
```

`render` receives 64 output samples, eight read-only parameter slots, and 64
phase increments. Write every output sample. `display` receives a by-value
`Input` snapshot and fills the retained `Frame`; use the frame helpers rather
than raw fields when possible.

## Generated folder

`build/synth/<machineId>/` contains the SDK folder, opaque headers,
`generated/wrapper.nim`, `vendor/openxy/` (nimbase wrapper, unmodified
nimbase.h copy, string.h shim, warnings), and the build-local nimcache. After
`nim preview`/`compile`/`build`, the package step writes the deduplicated C++
translation unit under `vendor/openxy/machine.cpp` and removes the nimcache.
