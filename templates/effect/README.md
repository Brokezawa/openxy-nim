# My Effect

A send effect for the OP-XY, written in Nim with `openxy`.

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
- `machine.json` declares the SDK version, effect kind, and the `dryParameter`
  the SDK mixes outside the callback. The build layout gives the effect its
  number.
- `definition.json` owns the controls, presets, delay-buffer size and transport
  resource.
- `src/myeffect.nim` implements `State`, `initialize`, and `process`.
  `openxyValidate(mkEffect, State)` checks the callback shapes.

The effect declares both optional inputs, so `process` receives a `Buffer` and
a `Transport`. An absent buffer or transport is represented by an empty value;
check `isEmpty` before using the pointer or timing fields.

## Build

```sh
nim test       # host tests, checks enabled
nim gen        # validate, measure, prepare, compile
nim compile    # Blackfin development module
nim build      # firmware package; edit stockOs first
nim clean
```

`nim preview` reports that the SDK only previews synths. Use `nim compile` for
the fast device check and `nim test` for the host audio checks.

For `nim build`, set `stockOs` to the stock OP-XY OS 1.2.1 image, for example
`../stock-1.2.1/os.ldr`, and optionally `layout` to the `layout.json` from the
previous package.

## Callbacks

```nim
proc initialize*(state: var State) {.raises: [].}
proc process*(state: var State; block: EffectBlock) {.raises: [].}
```
