# My Sample

A sample engine for the OP-XY, written in Nim with `openxy`.

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
- `machine.json` declares the SDK version, sample kind, identity, and amp
  defaults.
- `definition.json` owns the controls, presets, and sample resources. The stock
  sample page is page 7 when pad settings or drum controls are enabled.
- `src/mysample.nim` implements `Voice`, `Preparation`, and the sample
  callbacks. `openxyValidate(mkSample, Voice)` checks the required callbacks.

The sample engine implements every optional service: pad defaults and
assignment, drum controls and panel, and sample analysis. Remove a service from
`definition.json.resources` and its callback from the source together.

## Build

```sh
nim test       # host tests, checks enabled
nim gen        # validate, measure, prepare, compile
nim compile    # Blackfin development module
nim build      # firmware package; edit stockOs first
nim clean
```

`nim preview` reports that the SDK only previews synths. Use `nim compile` for
the fast device check and `nim test` for the host sound checks.

For `nim build`, set `stockOs` to the stock OP-XY OS 1.2.1 image, for example
`../stock-1.2.1/os.ldr`, and optionally `layout` to the `layout.json` from the
previous package.

## Callbacks

```nim
proc initialize*(voice: var Voice; sample: SampleView) {.raises: [].}
proc start*(voice: var Voice) {.raises: [].}
proc renderSample*(voice: var Voice; block: SampleBlock) {.raises: [].}
proc sampleDefaults*(): PadSettings {.raises: [].}
proc sampleAssign*(assignment: SampleAssignment): PadSettings {.raises: [].}
proc drumControl*(value: var PadSettings; event: DrumControl) {.raises: [].}
proc drumPanel*(value: PadSettings; saved: SampleRegion;
                parameters: openArray[Q31]; panel: var DrumPanel) {.raises: [].}
proc analysisWords*(sample: SampleView): uint32 {.raises: [].}
proc prepareBegin*(job: var Preparation; sample: SampleView;
                   storage: ptr uint32; words: uint32): bool {.raises: [].}
proc prepareStep*(job: var Preparation; frames: uint32;
                  cursor: var uint32): PrepareStatus {.raises: [].}
proc prepared*(job: Preparation; analysis: var SampleAnalysis): bool {.raises: [].}
```
