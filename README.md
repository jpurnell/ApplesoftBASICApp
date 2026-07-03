# Applesoft BASIC App

An iPad app that interprets and runs Applesoft BASIC programs with a retro terminal experience. Built with SwiftUI, it provides a code editor, terminal output, lo-res/hi-res graphics, and sound — powered by the [ApplesoftBASICLib](https://github.com/jpurnell/ApplesoftBASIC) interpreter.

## Features

- **Code Editor** — syntax-aware editor with authentic retro fonts (PrintChar21, PRNumber3)
- **Terminal Emulator** — scrollable output buffer with classic green-on-black theme
- **Graphics** — lo-res and hi-res drawing modes
- **Sound** — speaker tone generation via `PEEK`/`POKE` emulation
- **Sample Programs** — bundled collection including Adventure, Fibonacci, Sine Wave, and more
- **Settings** — configurable theme and display options

## Requirements

- Xcode 17.0+
- iOS 17.0+ (iPad, also runs on Mac via Designed for iPad)
- Swift 6.x with strict concurrency enabled

## Building

Open `ApplesoftBASICApp.xcodeproj` in Xcode. The project resolves the `ApplesoftBASIC` package (from GitHub) and the local `ApplesoftBASICAppCore` package automatically. The `.xcodeproj` is generated from `project.yml` via [XcodeGen](https://github.com/yonaskolb/XcodeGen) — run `xcodegen generate` after editing `project.yml`.

```
xcodebuild -project ApplesoftBASICApp.xcodeproj \
  -scheme ApplesoftBASICApp \
  -destination 'platform=iOS Simulator,name=iPad Pro'
```

The platform-independent core has its own Swift package and unit tests:

```
swift build      # builds ApplesoftBASICAppCore
swift test       # runs the core unit tests
```

## Project Structure

```
Package.swift     ApplesoftBASICAppCore — platform-independent core library
Sources/          Core library sources (TerminalBuffer, ProgramStore)
Tests/            Core library unit tests
App/              App entry point
Views/            SwiftUI views (editor, terminal, settings, sample picker)
ViewModels/       TerminalViewModel — bridges interpreter ↔ UI
IO/               SwiftUI input/output handlers for the interpreter
Theme/            Retro theme and display settings
Sound/            Tone generation and sound adapter
Resources/        Fonts and sample .bas programs
```

## License

Copyright (c) Justin Purnell. All rights reserved.
