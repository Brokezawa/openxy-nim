# openxy

Idiomatic Nim bindings and an authoring SDK for the unofficial Teenage
Engineering OP-XY machine SDK.

A machine is a freestanding C++ callback bundle. `openxy` lets you write the
machine in Nim, validates the SDK metadata, measures the Nim storage types, and
generates the C++ headers, adapters, vendor headers, and NuM translation units
that the OP-XY SDK compiles.

The C/C++ target is implemented first. Browser/wasm and the web authoring flow
follow after the native path is stable.

## Requirements

- Nim 2.2.12 or newer
- [Atlas](https://github.com/nim-lang/atlas) for dependency setup
- Python 3.10+ for the OP-XY SDK
- A Clang/LLVM build with the WebAssembly target for previews
- The pinned Blackfin toolchain for `compile`/`build`

## Repository layout

```
src/openxy/          public SDK, units, display, sample/effect views, testkit
src/openxy/util/     validation, measurement, generation, SDK invocation
templates/synth/     self-contained synth machine and build tasks
templates/sample/    self-contained sample engine and build tasks
templates/effect/    self-contained send effect and build tasks
scripts/             maintainer and template task implementations
open-xy/             pinned OP-XY SDK checkout (submodule target)
open-xy.lock         SDK commit checked by `nim doctor`
```

## SDK pin

`open-xy.lock` records the SDK commit this checkout expects. Initialize the SDK
once after cloning an openxy project:

```sh
git -C deps/openxy submodule update --init --recursive
```

In a development checkout of this repository the SDK lives at `open-xy/`
instead of `deps/openxy/open-xy/`. `nim doctor` reports the checked-out commit
and the expected lock value.

## Use a template

Copy one of `templates/synth`, `templates/sample`, or `templates/effect` to
your project, then:

```sh
atlas init
atlas install
git -C deps/openxy submodule update --init --recursive
nim test
nim gen
```

| Template | Machine kind | Preview |
| --- | --- | --- |
| `templates/synth` | synth with a retained display | browser preview |
| `templates/sample` | sample engine with pad, drum and analysis services | device only |
| `templates/effect` | send effect with buffer and transport | device only |

Edit the constants at the top of the template's `config.nims` and the metadata
in `machine.json`/`definition.json`. The machine source is
`src/<machineId>.nim`; a synth exports `Voice`, `Shared`, `DisplayState`, and
`Frame`, while sample/effect machines export their `Voice`/`State` and optional
service types.

Build tasks:

| Task | What it does |
| --- | --- |
| `nim test` | Runs the machine's host tests with checks enabled. |
| `nim gen` | Validates, measures, prepares the SDK folder, and compiles the Nim wrapper into a build-local nimcache. |
| `nim preview` | Runs `nim gen`, packages the Nim C++, then invokes the SDK browser preview. |
| `nim compile` | Packages and builds a non-bootable Blackfin development module. |
| `nim build` | Packages and builds a firmware package; requires `stockOs`. |
| `nim clean` | Removes the template's build directory. |

`nim preview`, `nim compile`, and `nim build` run `nim gen` as a subprocess
because NimScript queues `setCommand` compiles until the script exits. The C++
is packaged from the nimcache JSON only after that subprocess returns.

## Maintainer tasks

From the openxy checkout:

```sh
nim test
nim doctor
nim checkTemplates
nim checkTemplates -- --full
```

`nim doctor` checks the SDK checkout and lock, Python version, wasm-capable
Clang, the Blackfin toolchain, and Node. Each failure prints an actionable
command. `nim checkTemplates` runs the fast checks. Add `-- --full` for the
template preview and device compile. The `--` is the Nim separator for
arguments passed to a custom task.

## Firmware build inputs

`nim build` needs the exact stock OP-XY OS 1.2.0 image. Copy `os.ldr` from the
device (see the SDK's `docs/build.md`, step 2) and set the template's `stockOs`
to it, for example `stockOs = "../stock-1.2.0/os.ldr"`. The SDK's default stock
content catalog is used unless the SDK command is given another
`--stock-content` folder. Pass the previous package's `layout.json` through the
template's `layout` constant to keep machine numbers stable.

To build several machines together, use the SDK's collection support directly:

```sh
python3 open-xy/sdk.py build \
  --machine build/synth/mysynth \
  --machine build/sample/mysample \
  --machine build/effect/myeffect \
  --stock-os stock-1.2.0/os.ldr \
  --out builds/collection-001
```

Effect-only collections are not accepted by the SDK because the stock startup
table needs at least one synth or sample engine; include one alongside an
effect. The package records its collection and writes `layout.json` beside the
candidate files.

Raw C++ bindings are optional. Enable the feature to install Henka and libclang:

```sh
atlas install --features=regen
nim regen
```

Normal installs do not fetch Henka.

## Target profiles

- Host tests: C++ backend, checks enabled, SDK include path.
- Device: `--os:any --cpu:arm --mm:arc --exceptions:quirky --checks:off
  --panics:off --threads:off --stackTrace:off --lineTrace:off
  -d:useMalloc -d:nimPreviewSlimSystem -d:noSignalHandler -d:release`
- The generated wrapper is compiled with the machine ID as its C++ namespace
  and `--nimMainPrefix:<machineId>_`.

The device profile intentionally avoids libc formatting, `panicoverride`, and
the `_exit`/`_free` path that the goto exceptions mode pulls in. Generated
C++ lives under `vendor/openxy/` so the SDK's source-boundary lint never sees
Nim's conditional-compilation boilerplate.

## Status

The synth, sample, and effect paths are implemented: typed API, validation,
measurement, generator, templates, host tests, sample/effect service coverage,
browser preview for synths, Blackfin development compiles, and a three-machine
firmware collection build. The SDK's stock startup table requires at least one
synth or sample engine in a collection, so an effect is compiled with one.

Browser/application work and the zero-touch Henka normalization are deferred.

See `docs/api.md` and `docs/build.md` for the API and generation details.
