# Hardware testing

Hardware testing is the primary gate for the 0.1.0 release. CI cannot replace
it because CI has no stock OS and no OP-XY device.

## Safety

- Use a stock OP-XY OS 1.2.1 image that you own and the SDK tag `v0.0.3`
  (API 1.6).
- Keep a copy of the stock OS outside the repository.
- Do not commit the stock OS, firmware package, sample content, or device
  identifiers.
- Do not publish the candidate package.
- A passing test does not guarantee recovery from a failed write.

## Candidate record

Fill this table from the combined candidate package and the SDK build report.

| Field | Value |
| --- | --- |
| Candidate commit | `<pending combined candidate>` |
| Candidate package path | `<pending combined candidate>` |
| Package hash (`candidate/os.ldr`) | `<pending>` |
| Stock OS version | 1.2.1 |
| SDK tag / API | v0.0.3 / 1.6 |
| SDK commit | `17840e39a0e427be827cd1c8cbc62d8015205bcd` |
| Stock OS SHA-256 | `60358afdaa9b58ed40411602f6d5d4e1e3e02553ff2da7e25038e71dd002b52f` |
| Machines / extension | mysynth, mysynth8, mysample, myeffect, mynotify (experimental) |
| Tester and date | `<pending>` |
| Build profile | `opxy-1.2.1`, profiling enabled, SDK 1.6, previous layout preserved |

The SDK build report contains `os_sha256` and memory sizes. Record the command
used to build the package.

## Test matrix

Mark each check only after observing it on the device.

### Install and boot

- [ ] Copy the candidate `os.ldr` to `/os.ldr` using the SDK install steps.
- [ ] Copy `content/op1_factory.json` to `/content/op1_factory.json`.
- [ ] Copy `content/display/mysynth.svg` to `/content/display/mysynth.svg`.
- [ ] Copy `content/display/mysynth8.svg` to `/content/display/mysynth8.svg`.
- [ ] Reboot the device.
- [ ] The device reaches the normal OS and does not hang.

### Synth

- [ ] The synth is selectable from the stock UI.
- [ ] Notes produce audio.
- [ ] The four controls change the sound.
- [ ] The display draws and animates without corruption.
- [ ] Note release and voice reuse do not crash or hang.

### Synth-eight

- [ ] `mysynth8` is selectable from the stock UI.
- [ ] Notes produce audio.
- [ ] All eight controls change the sound.
- [ ] The two-row header switches pages when an encoder is pressed.
- [ ] The header titles and values update without corruption.
- [ ] Note release and voice reuse do not crash or hang.

### Sample

- [ ] A sample can be assigned and played.
- [ ] Pad settings and playback work with the drum sampler base.
- [ ] The drum page opens and its controls respond.
- [ ] The sample does not crash or leave a stuck voice.

### Effect

- [ ] The effect is selectable on a send track.
- [ ] The effect changes the send audio.
- [ ] The dry control works.
- [ ] The effect does not crash or hang when bypassed or removed.

### Extension (experimental)

- [ ] `mynotify` is present in the combined candidate.
- [ ] Double-tapping Record shows the extension popup.
- [ ] A single Record press/release still behaves as stock.
- [ ] No crash, stuck popup, or recovery screen occurs.

### Reboot

- [ ] A second reboot reaches the OS.
- [ ] The four machines and the extension remain available.
- [ ] No repeated crash or recovery screen occurs.

## Result

| Result | Meaning |
| --- | --- |
| PASS | Every required check above was observed on the recorded configuration. |
| FAIL | At least one required check failed, or the device did not boot. |

Result: **Pending**

Notes:

```text
Awaiting the combined SDK 1.6, hardened machine API, and experimental extension
candidate. Do not reuse the previous v0.0.2 package hash or PASS record.
```

## If the result is FAIL

Do not tag the release. Record the failing check and the package hash. Fix the
machine or extension code, generator, or documentation as appropriate. Rebuild
the package. Repeat this matrix if machine code, extension code, runtime, or
generator changed.

## If the result is PASS

Record the exact configuration in the release notes:

```text
Tested on OP-XY OS 1.2.1 with the <candidate-commit> package on <date>.
SDK tag v0.0.3, API 1.6. Extension mynotify is experimental.
Still experimental; no recovery guarantee.
```

See [release](release.md) for the remaining tag steps.
