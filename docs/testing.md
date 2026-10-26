# Testing

This document records the release checks for openxy. Run commands from the
repository root unless a command changes directory.

## Environment

```sh
nim --version
nim doctor
git submodule status
```

Expected:

- Nim 2.2.12 or newer.
- Every `nim doctor` line starts with `ok:`.
- The `open-xy` submodule line reports the commit recorded in `open-xy.lock`.

`nim doctor` checks the SDK checkout, Python, wasm-capable Clang, the Blackfin
toolchain, and Node. A failure prints the command that fixes it.

## Fast checks

```sh
nim test
nim checkTemplates
nimble check
```

Expected:

```text
All 9 test files completed.
Template checks passed.
The package "openxy" is valid.
```

`nim checkTemplates` runs each template's host tests and generation. It also
runs deliberate failure cases for a wrong definition ID and a wrong `Frame`
size. Error logs from those cases are expected; the final line must be
`Template checks passed.`

## Full template checks

```sh
nim checkTemplates -- --full
```

Expected:

```text
My Synth preview built: .../sdkPreview
Template checks passed.
```

This also runs:

- Synth browser preview ABI and drawing checks.
- Synth Blackfin device compile.
- Sample Blackfin device compile.

The effect is not compiled standalone because the SDK rejects an effect-only
collection. The three-machine collection check covers the effect.

## Unit tests

`nim test` runs:

- `t_q31` — Q31/SatQ31 arithmetic and boundaries.
- `t_units` — unit sizes and conversions.
- `t_draw` — display layout and helpers.
- `t_sample_effect` — sample/effect mirrors.
- `t_project` — machine ID and path rules.
- `t_validate` — metadata validation.
- `t_compile_failures` — invalid callback and unit-mixing cases.
- `t_abi` — C++ ABI and generated-header checks.
- `t_raw` — raw generated bindings.

## Template checks

From a template directory inside the repository:

```sh
cd templates/synth
nim test --skipParentCfg:on
nim gen --skipParentCfg:on
nim compile --skipParentCfg:on
```

Sample:

```sh
cd templates/sample
nim test --skipParentCfg:on
nim gen --skipParentCfg:on
nim compile --skipParentCfg:on
```

Effect:

```sh
cd templates/effect
nim test --skipParentCfg:on
nim gen --skipParentCfg:on
```

A standalone effect compile is expected to fail with:

```text
Startup needs distinct engine prefixes
```

The effect is compiled with a synth or sample in a collection.

## Preview

```sh
cd templates/synth
nim preview --skipParentCfg:on
```

Expected:

```text
PASS: preview ABI, fixed memory, controls/pitch ownership, peak bounds, lifecycle and drawing smoke checks.
My Synth preview built: .../sdkPreview
```

The preview output contains `manifest.json`, `engine.wasm`, and `panel.svg`.

## Device compile

Synth:

```sh
cd templates/synth
nim compile --skipParentCfg:on
```

Sample:

```sh
cd templates/sample
nim compile --skipParentCfg:on
```

The SDK prints a JSON memory report and a line like:

```text
Memory 12.5 of 2040 KiB: mysynth 8.7 KiB, sdk 3.8 KiB
Memory 75.5 of 2040 KiB: sdk 51.9 KiB, mysample 23.6 KiB
```

Memory values can change; the important result is a successful link below the
shared reservation.

## Three-machine collection

The current workspace can compile all three generated machines:

```sh
python3 open-xy/sdk.py compile \
  --machine templates/synth/build/synth/mysynth \
  --machine templates/sample/build/sample/mysample \
  --machine templates/effect/build/effect/myeffect \
  --out /tmp/openxy-collection
```

Expected: a memory report for all three machines and the SDK, then:

```text
Non-bootable development module; not an OS image.
```

For firmware, see [release](release.md) and [hardware testing](hardware-test.md).
A firmware package is not part of CI.

## Raw binding regeneration

This is optional and needs the `regen` feature:

```sh
atlas install --features=regen
nim regen
```

Expected:

```text
Regenerated raw bindings in .../src/openxy/private/raw
```

`nim regen` checks the SDK commit, runs Henka, applies `henka.patch`, and runs
`nim check` on the raw module. Normal `import openxy` does not require Henka or
libclang.

## CI mapping

The GitHub Actions workflow runs the same commands:

| Job | Commands |
| --- | --- |
| Linux | `nimble check`, `nim test`, `nim checkTemplates` |
| macOS | `nim doctor`, `nim test`, `nim checkTemplates -- --full` |
| Atlas | `atlas init`, `atlas link`, `atlas install`, `nim test`, `nim gen` |

CI does not build firmware. The hardware test is the primary release gate; see
[hardware testing](hardware-test.md).
