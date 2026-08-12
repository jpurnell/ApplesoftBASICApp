# 2026-08-12 — macOS sheet fix and v1.1.0 release prep

## Starting point

A "safety fix on newlines" had been committed to `ProgramStore.swift`; the question was
whether it warranted re-tagging. It did not — `v1.0.0` was already pushed and pointed
eight commits back, so moving it would have rewritten history for anyone who had fetched
it. The fix belongs in a new tag.

Reviewing that commit surfaced three things worth settling before any tag, and the user
then reported a live bug: the bundled sample programs were unreachable on macOS.

## The macOS bug

**Symptom:** on the native Mac build, opening Sample Programs produced a sheet showing
only its title and Cancel button — no list.

**Not the cause:** resource bundling. The `.bas` files ship correctly in both layouts —
`Contents/Resources/Samples/` on macOS, `Samples/` at the bundle root on iOS — and
`Bundle.main.url(forResource:withExtension:subdirectory:)` resolves them on both.
That was verified against the actual built bundles before touching any code.

**Actual cause:** a macOS sheet sizes itself to its content, and `List` supplies no
intrinsic height, so the sheet collapsed to its chrome. `System Events` reported the
sheet window at 280×168. On iOS the system supplies a sheet size, which is why the bug
appeared only when Mac support was added — the code had not changed.

**Fix:** a minimum frame on macOS for both `SampleProgramPicker` and `SettingsView`
(`Form` has the same problem). Also replaced a duplicated dead fallback in
`loadSample` — the second branch reran the identical lookup — with a real bundle-root
fallback.

## Correcting the newline claim

The newline change was initially described as fixing a CRLF bug. Checked empirically:
`components(separatedBy: .newlines)` does yield a phantom empty component on `\r\n`
(scalar-wise splitting), but `load` discards non-numbered lines, so the parsed result
was identical. It is a clarity/robustness improvement, not a behavior fix. A
characterization test now locks LF/CRLF/CR equivalence in place.

## Cleanup

- **Emacs lock file** — `Sources/ApplesoftBASICAppCore/.#ProgramStore.swift`, a dangling
  symlink, had been committed. Removed, and `.#*` added to `.gitignore`.
- **`project.yml` drift** — the Mac/visionOS settings (`SUPPORTED_PLATFORMS`,
  `TARGETED_DEVICE_FAMILY = "2,7"`, sandbox/hardened runtime, `DEVELOPMENT_TEAM`) existed
  only in the generated `.pbxproj`. The next `xcodegen generate` would have silently
  reverted Mac support. Mirrored into `project.yml`, regenerated, and confirmed the
  settings survive and both platforms still build.
- **Docs** — CHANGELOG `[1.1.0]`, README platform claims, and `project/master_plan.md`
  Current Status reconciled against shipped code.

## State at end

- 39 package tests green; macOS and iOS builds clean, no warnings.
- Quality gate: 0 warnings. The single `release-readiness` error is the expected
  chicken-and-egg — CHANGELOG names 1.1.0 before the tag exists — and clears once tagged.

## Next

- **macOS UI audit.** The sheet bug is unlikely to be the only iPad-shaped assumption.
  Notably, the split-view sidebar starts collapsed on a fresh macOS launch, which hides
  the editor pane and its toolbar entirely.
- **visionOS is enabled but unexercised** — it is in `SUPPORTED_PLATFORMS` and
  `TARGETED_DEVICE_FAMILY`, but has not been run in the simulator or on device.
- **Master plan roadmap** phases are still template placeholders awaiting product
  direction.
