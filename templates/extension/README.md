# My Notify

A minimal OP-XY firmware extension written in Nim with `openxy`.

It claims the `record_double_tap` gesture and uses the `notify` action. A
double-tap of Record shows a short popup; a single tap, hold, repeat, or chord
keeps stock Record behavior unchanged.

## Set up

```sh
atlas init
atlas install
git -C deps/openxy submodule update --init --recursive
```

If the template is copied into an existing project, use
`atlas use https://github.com/Brokezawa/openxy-nim` instead and run `atlas install`.

## Edit

- `extension.json` is the source of truth for the extension ID, the site text,
  and the claims and actions it uses. Claims and actions come from the pinned
  SDK registry.
- `config.nims` owns `extensionId`, `extensionSource`, `buildRoot`, `stockOs`,
  and `machine`.
- `src/mynotify.nim` implements the callback and the gesture. Extension state
  is module-global because the SDK callbacks have no userdata pointer.
- `tests/t_mynotify.nim` drives the callback with a fake action table.

The template claims `record_double_tap` and uses `notify`. To use
`edit_notes`, add it to `actions` and call `insertNotes` or `replaceNotes` from
the `queuedControl` callback. `machine.json` is not used: extensions are not
machines.

## Build

```sh
nim test       # host tests, checks enabled
nim gen        # validate, generate, and package the extension folder
nim compile    # compile with a machine collection
nim build      # firmware package; edit stockOs and machine first
nim clean
```

`nim compile` and `nim build` need `machine` set to a generated synth or sample
folder, because the SDK collection needs a bootable engine. For example:

```nim
machine = "../synth/build/synth/mysynth"
```

`nim gen` writes `build/extension/mynotify/` with `extension.json`, the
generated `extension.cpp` adapter, and the Nim C++ under
`build/extension/nim/mynotify/`. The adapter is generated; do not edit it.

`sdk.py test --extension` is optional: it expects a C++ `tests/*.cpp` host
test. The Nim tests are the primary suite. `nim compile` uses
`sdk.py compile --extension <build-folder> --machine <machine-folder>`.

## Callbacks

A `Hooks` value names the events the extension takes:

```nim
const hooks* = initHooks().withQueuedControl(queuedControl)
```

Callbacks are `{.cdecl, raises: [].}`, run serially on the controller path, and
must not allocate, block, perform I/O, or raise. `Context`, `Actions`, and a
`Note` array are borrowed for the callback; copy any value that must outlive it.

`Actions` methods return counts or bools:

- `insertNotes` and `replaceNotes` return the inserted prefix length; `0` means
  refused or nothing written.
- `notify` returns false for text outside 1–31 characters; the SDK may still
  refuse the popup.

The extension API is experimental in 0.1.0. It is source-level, not a dynamic
loader or binary ABI.
