# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- `ApplesoftBASICAppCore` Swift package (root `Package.swift`) holding the app's
  platform-independent logic, so `swift build`/`swift test` and the SPM quality-gate
  checkers run instead of skipping on this formerly Xcode-only project.
- `TerminalBuffer` moved into the package with a full swift-testing unit suite
  (ANSI/CSI parsing, scrollback, cursor movement).
- `ProgramStore` + `REPLParser`: the program-editing and REPL-command logic
  extracted from `TerminalViewModel` into pure, tested value types (line storage,
  `LIST`/`DEL` ranges, source parsing/rendering, command classification).

### Changed
- The Xcode app now consumes `TerminalBuffer` and `ProgramStore` from the local
  package via XcodeGen; `TerminalViewModel` delegates program/REPL logic to them.

### Fixed
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
