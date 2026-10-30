# openxy manual

This manual is the entry point for writing an OP-XY machine in Nim. It covers
installation, the four templates, the build tasks, preview, device compile,
and firmware packaging. Detailed API and generator information lives in
[API](api.md) and [build](build.md).

## What openxy does

`openxy` turns a Nim machine source into the C++ machine folder that the OP-XY
SDK accepts:

1. Read `machine.json` and `definition.json`.
2. Validate names, controls, presets, resources, and the machine source.
3. Measure the Nim state types for the 32-bit device ABI.
4. Write the SDK headers, JSON, vendor files, and generated wrapper.
5. Compile the wrapper as C++.
6. Call the SDK to preview, compile, or build the machine.

The generated C++ lives under `build/<kind>/<id>/`. Source JSON is never
rewritten; the generated `definition.json` contains the measured layout fields.

## Requirements

- Nim 2.2.12 or newer.
- Atlas for dependency setup.
- Python 3.10 or newer for the OP-XY SDK.
- A Clang/LLVM build with the WebAssembly target for synth previews.
- The pinned Blackfin toolchain for `compile` and `build`.

The tested environment and the macOS-only local testing claim are in the
[README requirements](../README.md#requirements).

## Install with Atlas

Copy one of the templates to a project directory:

```sh
cp -R templates/synth my-machine
cd my-machine
atlas init
atlas install
git -C deps/openxy submodule update --init --recursive
```

If you already have a project, use:

```sh
atlas use https://github.com/Brokezawa/openxy-nim
atlas install
```

Atlas does not initialize Git submodules. Run the `git -C deps/openxy
submodule update --init --recursive` command once. The build and `nim doctor`
print the command when the SDK is missing.

A development checkout of openxy uses `open-xy/` instead of
`deps/openxy/open-xy/`. `openxy/paths.nim` resolves both layouts without
environment variables.

## First synth

1. Copy `templates/synth` and edit the constants at the top of `config.nims`:
   `machineId`, `machineSource`, `buildRoot`, `stockOs`, and `layout`.
2. Edit `machine.json` for the SDK version, kind, description, and (for a
   sample engine) the `sampler` or `drumSampler` base. SDK 1.5 and newer have no
   `identity`; the build layout assigns the machine numbers.
3. Edit `definition.json` for controls, presets, and resources.
4. Implement `Voice`, `Shared`, `DisplayState`, `Frame`, and the callbacks in
   `src/<machineId>.nim`.
5. Keep `openxyValidate(mkSynth, Voice, Shared)` at the end of the source.

Run the host tests and generate the machine:

```sh
nim test
nim gen
```

Start the browser preview:

```sh
nim preview
python3 deps/openxy/open-xy/tools/serve_harness.py \
  --preview build/out/<machineId>/sdkPreview
```

In a development checkout, replace the server path with
`open-xy/tools/serve_harness.py`. Open `http://127.0.0.1:8917/` in Chrome or
Edge and click **Enable audio**.

The preview is a snapshot. After changing the machine source, run `nim preview`
again and reload the browser.

## Sample and effect templates

- `templates/synth-eight` implements the SDK two-page synth: eight controls,
  page switching, the shared `PageHeader`, and 16 text slots.
- `templates/sample` implements a sample engine with pad defaults, sample
  assignment, drum controls, drum panel, and sample analysis.
- `templates/effect` implements a send effect with a delay buffer, transport,
  and a dry control.

Sample engines use `"base": "drumSampler"` when pad settings or drum controls
are enabled; a `"sampler"` base plays chromatically without the pad services.
Legacy SDK 1.4 sample engines use stock sample page 7. Effects use the stock FX
page and an effect number the layout assigns.

The SDK previews synths only. Both synth templates use the browser preview;
sample and effect machines use host tests and the device compile. The SDK also
rejects an effect-only collection because the stock startup table requires at
least one synth or sample engine.

The two-page synth uses `PageHeader` and a 16-slot frame. See
[the API display section](api.md#page-header) for the callback example.

## Build tasks

| Task | Purpose |
| --- | --- |
| `nim test` | Run machine host tests with checks enabled. |
| `nim gen` | Validate, measure, prepare the SDK folder, and compile the Nim wrapper into a build-local nimcache. |
| `nim preview` | Package the C++ and build a browser preview. Synths only. |
| `nim compile` | Package and build a non-bootable Blackfin development module. |
| `nim build` | Package and build firmware; requires a stock OS image. |
| `nim clean` | Remove the template build directory. |

`preview`, `compile`, and `build` run `nim gen` as a subprocess, then package the
nimcache and call `sdk.py`. This two-phase flow exists because NimScript queues
`setCommand` compiles until the script exits.

When a template is tested inside the openxy repository, add
`--skipParentCfg:on` to template commands so the parent maintainer tasks do not
shadow the template tasks.

## Preview

```sh
nim preview
```

Output: `build/out/<machineId>/sdkPreview/`.

Serve that folder with the SDK harness:

```sh
python3 deps/openxy/open-xy/tools/serve_harness.py \
  --preview build/out/<machineId>/sdkPreview
```

If port 8917 is busy, add `--port 8918`. Use the same port in the browser URL.
The harness is read-only and serves only the preview artifacts.

## Device compile

```sh
nim compile
```

Output: `build/out/<machineId>/sdkCompile/`.

This builds the Blackfin module without a stock OS. It is the fast device check.
The SDK prints the module memory. The current templates use about 76.1 KiB for
the synth, 79.8 KiB for the two-page synth, and 138.7 KiB for the sample engine
of the 2032 KiB module region; these numbers can change as the machine grows.

## Firmware build

`nim build` needs the exact stock OP-XY OS 1.2.1 image. Copy `os.ldr` from the
device; do not commit it. Set the template constant:

```nim
stockOs = "/absolute/path/to/stock-1.2.1/os.ldr"
```

Optionally set `layout` to the `layout.json` from the previous package so
machine numbers stay stable. Then run:

```sh
nim build
```

Output: `build/out/<machineId>/sdkBuild/`. The installable files are under
`candidate/`. The package also writes `layout.json`.

To build several machines together, call the SDK directly with repeated
`--machine` options or a collection file:

```sh
python3 open-xy/sdk.py build \
  --machine templates/synth/build/synth/mysynth \
  --machine templates/synth-eight/build/synth/mysynth8 \
  --machine templates/sample/build/sample/mysample \
  --machine templates/effect/build/effect/myeffect \
  --stock-os /path/to/stock-1.2.1/os.ldr \
  --out builds/collection-001
```

The SDK is the final authority on identity, registration, memory, and package
validity. Read its [build documentation](../open-xy/docs/build.md) before
installing a package on hardware.

## Troubleshooting

| Symptom | Action |
| --- | --- |
| `Python 3.10+` error | Install Python 3.10 or newer and put it on `PATH`. |
| Preview cannot compile WebAssembly | Install LLVM with `wasm32` support and `lld`; pass `--cxx` if needed. Apple Clang alone is insufficient. |
| Blackfin toolchain missing | Run `python3 deps/openxy/open-xy/sdk.py toolchain fetch` from the template, or `python3 open-xy/sdk.py toolchain fetch` from the openxy checkout. |
| Effect-only compile fails | Add a synth or sample to the collection. Stock startup needs an engine. |
| Preview port is in use | Pass `--port 8918` to the harness and use that URL. |
| Preview is stale | Run `nim preview` again and reload the browser. |
| Generated folder has no C++ | Run `nim gen` before `nim compile` or `nim build`. |
| Machine ID rejected | Use a lowercase letter, then lowercase letters, digits, or underscores; avoid stock names, language keywords, and reserved prefixes. |

## Platform and limits

- macOS Apple Silicon is the locally tested platform.
- Linux is tested in CI for host and template checks.
- Windows is untested.
- Browser preview is synth-only.
- A firmware build needs a user-supplied stock OS.
- The device profile uses `--os:any --cpu:arm --mm:arc`.
- `--mm:none` is experimental and not supported for 0.1.0.
- Nix and direnv are not part of the 0.1.0 setup.
- Hardware results are recorded in [hardware testing](hardware-test.md). A
  passing test is not a recovery guarantee.

## Related documents

- [API](api.md)
- [Build and generation](build.md)
- [Testing](testing.md)
- [Release process](release.md)
- [Hardware testing](hardware-test.md)
- [SDK updates](sdk-update.md)
