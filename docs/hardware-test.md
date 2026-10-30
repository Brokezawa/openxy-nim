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
| Candidate commit | `7d66066746be` plus the display-fix working tree; final Git commit pending |
| Candidate package path | `templates/sample/build/out/0.1.0-candidate-displayfix2` |
| Package hash (`candidate/os.ldr`) | `92b541aeff49c8e35468b61b2e84a71415d500ba749786ab963ead9d297b1891` |
| Stock OS version | 1.2.1 |
| SDK tag / API | v0.0.3 / 1.6 |
| SDK commit | `17840e39a0e427be827cd1c8cbc62d8015205bcd` |
| Stock OS SHA-256 | `60358afdaa9b58ed40411602f6d5d4e1e3e02553ff2da7e25038e71dd002b52f` |
| Machines / extension | mysynth, mysynth8, mysample, myeffect, mynotify (experimental) |
| Tester and date | User, 2026-10-31 |
| Build profile | `opxy-1.2.1`, profiling enabled, SDK 1.6, previous layout preserved, extension linked |

The SDK build report contains `os_sha256` and memory sizes. Record the command
used to build the package.

## Test matrix

Mark each check only after observing it on the device.

### Install and boot

- [x] Copy the candidate `os.ldr` to `/os.ldr` using the SDK install steps.
- [x] Copy `content/op1_factory.json` to `/content/op1_factory.json`.
- [x] Copy `content/display/mysynth.svg` to `/content/display/mysynth.svg`.
- [x] Copy `content/display/mysynth8.svg` to `/content/display/mysynth8.svg`.
- [x] Reboot the device.
- [x] The device reaches the normal OS and does not hang.

### Synth

- [x] The synth is selectable from the stock UI.
- [x] Notes produce audio.
- [x] The four controls change the sound.
- [x] The display draws and animates without corruption.
- [x] Note release and voice reuse do not crash or hang.

### Synth-eight

- [x] `mysynth8` is selectable from the stock UI.
- [x] Notes produce audio.
- [x] All eight controls change the sound.
- [x] The two-row header switches pages when an encoder is pressed.
- [x] The header titles and values update without corruption.
- [x] The two-ring display draws and animates without corruption.
- [x] Note release and voice reuse do not crash or hang.

### Sample

- [x] A sample can be assigned and played.
- [x] Pad settings and playback work with the drum sampler base.
- [x] The drum page opens and its controls respond.
- [x] The sample does not crash or leave a stuck voice.

### Effect

- [x] The effect is selectable on a send track.
- [x] The effect changes the send audio.
- [x] The dry control works.
- [x] The effect does not crash or hang when bypassed or removed.

### Extension (experimental)

- [x] `mynotify` is present in the combined candidate.
- [x] Double-tapping Record shows the extension popup.
- [x] A single Record press/release still behaves as stock.
- [x] No crash, stuck popup, or recovery screen occurs.

### Reboot

- [x] A second reboot reaches the OS.
- [x] The four machines and the extension remain available.
- [x] No repeated crash or recovery screen occurs.

## Result

| Result | Meaning |
| --- | --- |
| PASS | Every required check above was observed on the recorded configuration. |
| FAIL | At least one required check failed, or the device did not boot. |

Result: **PASS**

Notes:

```text
All four machines and the experimental mynotify extension booted and behaved as
expected on the centered/moving mysynth candidate. mysynth rings are centered
and move with the Motion control; mysynth8 still shows its two moving rings; the
mynotify popup appears on a Record double-tap without changing a single stock
Record press. No crash, stuck voice, display corruption, or recovery screen was
observed.
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
