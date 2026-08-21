# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- A menu bar for the app (`ProgramCommands`): New Program (⌘N), Open Sample
  (⌘O), Run (⌘R), Stop (⌘.), List Program, Clear Editor, and Clear Terminal
  (⌘K). On macOS this is the discoverable list of what the app does; on iPad the
  same commands populate the Command-key shortcut overlay. Run/Stop and List are
  enabled against the interpreter's running state.
- A macOS `Settings` scene, so ⌘, opens preferences in a window rather than the
  app having no answer to the standard shortcut. The toolbar's gear becomes a
  `SettingsLink` there; iPad and Vision Pro keep the sheet.
- A listing preview in the sample-program browser. Selecting a sample shows its
  source beside the list with an explicit Load Program button, instead of a tap
  replacing the editor's contents sight-unseen. Rows also carry a context menu.
- Tooltips (`.help`) on the toolbar buttons, and ⌘J for the console toggle.
- Accessibility labels on every glyph-only control, so VoiceOver announces
  "Sample Programs" or "Submit Input" rather than an SF Symbol name.
- High Contrast variants for the terminal palette. The six theme colours moved
  from literals in `RetroTheme` into the asset catalogue, where each carries a
  second value used when Increase Contrast is on: the phosphors brighten, and
  Paper goes to black on white.
- `BlockingInputChannel` in `ApplesoftBASICAppCore`: the UI-to-interpreter input
  handoff, extracted from `SwiftUIInputHandler` so it can be tested without
  SwiftUI or the interpreter. 15 unit tests cover the state machine directly and
  the blocking waits through detached tasks.
- A DocC catalogue for `ApplesoftBASICAppCore`, curating the package's public
  types into topic groups. The `doc-lint` checker had been failing because no
  target owned a catalogue, so it was examining nothing.
- `liveness` added to `enabledCheckers`. It was not in the default set, which is
  how the unbounded waits below reached `main` in the first place.

### Changed
- The interpreter and the appearance settings moved from `ContentView` up to the
  `App` scene. The menu bar and the macOS Settings window are siblings of the
  window, not children of it, so all three now drive the same objects.
- Settings and the sample browser no longer wrap themselves in a
  `NavigationStack`. Neither had anything to push: the settings sheet supplies
  its own title and Done button, and the browser is a two-column split view. The
  form itself is now `SettingsForm`, which both the sheet and the macOS Settings
  scene present.
- The terminal fonts scale with Dynamic Type. `relativeTo: .body` layers the
  system text-size setting on top of the size slider, so the slider sets the
  base rather than fixing the result. The monospaced option now names Menlo,
  because only `Font.custom` accepts `relativeTo:` — a system font pinned to a
  point size cannot scale.
- `SwiftUIOutputHandler` and `iPadSoundAdapter` dropped their `@unchecked
  Sendable` conformances. Both protocols already require `Sendable` and both
  types satisfy it as written — immutable stored properties that are themselves
  Sendable — so the `@unchecked` was suppressing a check that passes.

### Fixed
- A second `RUN` dropped the previous interpreter task still running instead of
  cancelling it. The task handle now lives in `InterpreterRun`, whose `start`
  cancels whatever is in flight and whose `deinit` cancels on the way out — a
  `@MainActor` type's `deinit` is non-isolated and cannot safely reach its own
  stored task, which is why the handle moved out of `TerminalViewModel`.
- The `INPUT`/`GET` prompt callback wrote three pieces of main-actor state
  directly from the interpreter's thread. It now hops through one isolated
  method, `beginWaitingForInput(prompt:mode:)`.
- `SwiftUIInputHandler` parked the interpreter's background thread on
  `DispatchSemaphore.wait()` with no deadline. If the signal never arrived, that
  thread was stranded for the life of the process. Waits are now sliced with
  `wait(timeout:)`, so the thread re-reads its state instead of sleeping
  forever. Input itself still never times out — a user may take as long as they
  like to type.
- A stop issued while the interpreter was between prompts could make the *next*
  `INPUT` return immediately with stale text. `stop()` calls `cancel()`
  unconditionally, and the counting semaphore banked that signal and spent it on
  the following wait. The semaphore is now only a wake-up hint; locked state is
  the source of truth, reads consume, and cancellation latches.
- `pendingInput` was written from the main actor and read from the interpreter
  thread with no synchronization, under an `@unchecked Sendable` conformance
  that silenced the compiler. It is now guarded by a lock.

## [1.1.0] - 2026-08-12

### Added
- `ApplesoftBASICAppCore` Swift package (root `Package.swift`) holding the app's
  platform-independent logic, so `swift build`/`swift test` and the SPM quality-gate
  checkers run instead of skipping on this formerly Xcode-only project.
- `TerminalBuffer` moved into the package with a full swift-testing unit suite
  (ANSI/CSI parsing, scrollback, cursor movement).
- `ProgramStore` + `REPLParser`: the program-editing and REPL-command logic
  extracted from `TerminalViewModel` into pure, tested value types (line storage,
  `LIST`/`DEL` ranges, source parsing/rendering, command classification).
- Native macOS and visionOS builds, alongside the existing iPad build
  (`SUPPORTED_PLATFORMS` gains `macosx`/`xros`, `TARGETED_DEVICE_FAMILY` gains `7`).
- App Sandbox and Hardened Runtime enabled for the macOS build.
- `PrivacyInfo.xcprivacy` privacy manifest.

### Changed
- The Xcode app now consumes `TerminalBuffer` and `ProgramStore` from the local
  package via XcodeGen; `TerminalViewModel` delegates program/REPL logic to them.
- `ProgramStore.load(from:)` splits on `Character.isNewline` rather than
  `CharacterSet.newlines`, so a CRLF pair is treated as one separator instead of
  two. The parsed result is unchanged — non-numbered lines were already
  discarded — but the intermediate split no longer contains phantom empty lines.

### Fixed
- Sample programs and Settings were unreachable on macOS. Both sheets collapsed
  to their title bar and buttons, because a macOS sheet sizes itself to its
  content and `List`/`Form` supply no intrinsic height. Both now carry a minimum
  frame on macOS. The `.bas` resources were bundled correctly throughout — the
  list simply had zero height to draw into.
- The split view opened collapsed on a first macOS launch, so the editor pane —
  half the app — was hidden behind a toolbar button, leaving a bare terminal with
  no obvious way to reach it. The sidebar is now visible by default and carries a
  minimum width, and the split view uses the balanced style so both panes share
  the window rather than the editor overlaying the terminal.
- The editor's toolbar icons, the navigation title, and the window toolbar glyphs
  were invisible in every theme except Paper. The phosphor themes paint a black
  background, but the window stayed in light appearance, so system-default
  foreground colours drew dark-on-black. The root view now matches the window
  appearance to the theme, and the editor icons take the phosphor colour.
- `SampleProgramPicker.loadSample` had a duplicated fallback branch that reran
  the identical lookup; the second branch now searches the bundle root, so the
  samples resolve under both folder-reference and flattened resource layouts.
- `TerminalBuffer.reset()` now fully clears scrollback. Previously it emptied
  scrollback and then re-captured the still-visible screen into it, so a reset
  left the last screenful of text behind.

## [1.0.0] - 2026-06-07

### Added
- Initial Applesoft BASIC interpreter app for iPad
- Code editor with retro fonts (PrintChar21, PRNumber3)
- Terminal emulator with scrollable output buffer
- Lo-res and hi-res graphics support
- Sound support via AudioSoundHandler
- Sample program picker with bundled .bas programs (Adventure, Fibonacci, Sine Wave, etc.)
- Settings view with theme configuration
- Long-press trash button menu: clear editor, terminal, or both
- Multi-scene support for iPad multitasking
- Mac Designed for iPad support

### Fixed
- Clear terminal now stops running program and empties display
- Sound uses AudioSoundHandler directly instead of ToneGenerator
- Quality gate config: exclude SPM build checker (Xcode-only project)
- Added latestReport.json to .gitignore
