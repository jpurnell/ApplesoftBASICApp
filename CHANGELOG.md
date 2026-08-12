# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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
