# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
