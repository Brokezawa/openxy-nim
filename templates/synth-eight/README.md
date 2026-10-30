# My Synth 8

A two-page synth for the OP-XY, written in Nim with `openxy`.

This template mirrors the SDK's `synth-eight` starter: eight controls, a shared
two-row header, page switching, and 16 display text slots.

## Set up

```sh
atlas init
atlas install
git -C deps/openxy submodule update --init --recursive
```

If the template is copied into an existing project, use
`atlas use https://github.com/Brokezawa/openxy-nim` instead and run `atlas install`.

## Edit

- `config.nims` owns `machineId`, `machineSource`, `buildRoot`, `stockOs`,
  `layout`, and the task names.
- `machine.json` declares SDK 1.6 and amp defaults. The build layout gives the
  machine its numbers; with the supplied layout it keeps engine 47 and page 94.
- `definition.json` owns the eight controls, the page map, presets, and the
  display budget. `"press": "page"` switches all four encoder positions.
- `src/mysynth8.nim` implements `Voice`, `Shared`, `DisplayState`,
  `PageHeader`, and the callbacks.
- `panel.svg.fragment` contains the shared header bars, 16 text slots, two path
  nodes, and palette.

## Build

```sh
nim test       # host tests, checks enabled
nim gen        # validate, measure, prepare, compile
nim preview    # browser preview
nim compile    # Blackfin development module
nim build      # firmware package; edit stockOs first
nim clean
```

`nim preview`/`compile`/`build` run `nim gen` in a subprocess, package the
generated C++, and then call `sdk.py`.

The page header uses `PageHeader` from `openxy/draw`. The header bar nodes are
2 through 9, the text slots are 0 through 15, and the two path nodes are 0 and
1. Keep the header artwork above the machine graphics.

## Callbacks

```nim
proc initialize*(voice: var Voice; shared: var Shared; owner: VoiceId)
proc start*(voice: var Voice; shared: var Shared; owner: VoiceId)
proc destroy*(voice: var Voice; shared: var Shared; owner: VoiceId)
proc render*(voice: var Voice; shared: var Shared; owner: VoiceId;
             output: var openArray[Q31]; parameters: openArray[Q31];
             pitch: openArray[PhaseIncrement])
proc displayReset*(state: var DisplayState)
proc display*(state: var DisplayState; input: Input; frame: var Frame)
```
