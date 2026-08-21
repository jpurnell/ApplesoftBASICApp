# Applesoft BASIC App Master Plan

**Purpose:** Source of truth for project vision, architecture, and goals.

---

## Project Overview

### Mission
An iPad, Mac, and Vision Pro app that runs Applesoft BASIC programs with a
retro terminal experience — editor, terminal, lo-res/hi-res graphics, and
speaker sound — on top of the ApplesoftBASICLib interpreter.

### Target Users
- People revisiting the Apple II BASIC they grew up with, on modern hardware
- Learners meeting a small, complete, immediately legible language for the
  first time
- Owners of vintage listings (books, magazines, type-ins) with nowhere to run
  them

### Key Differentiators
- Runs the real language, not a subset — including graphics and sound
- Native on iPad, Mac, and Vision Pro from one codebase
- Period-accurate presentation: PrintChar21/PRNumber3 fonts, green-on-black

---

## Architecture

### Technology Stack
- **Language:** Swift 6.x
- **Build System:** Swift Package Manager (core) + XcodeGen → `.xcodeproj` (app)
- **UI:** SwiftUI, with `@Observable` view models
- **Testing:** Swift Testing framework
- **Concurrency:** Swift 6 strict concurrency (`SWIFT_STRICT_CONCURRENCY: complete`)
- **Dependencies:** [ApplesoftBASICLib](https://github.com/jpurnell/ApplesoftBASIC)
  (interpreter), swift-docc-plugin

### Module Structure

```
Sources/ApplesoftBASICAppCore/   Platform-independent core library
├── TerminalBuffer.swift         Screen grid, scrollback, ANSI/CSI handling
├── ProgramStore.swift           Line storage, LIST/DEL ranges, REPL parsing
├── BlockingInputChannel.swift   UI → interpreter input handoff
└── ApplesoftBASICAppCore.docc/  DocC catalogue
Tests/ApplesoftBASICAppCoreTests/  Core unit tests

App/          App entry point
Views/        SwiftUI views (editor, terminal, settings, sample picker)
ViewModels/   TerminalViewModel — bridges interpreter ↔ UI
IO/           InputHandler/OutputHandler conformances for the interpreter
Theme/        Retro theme and display settings
Sound/        Tone generation and sound adapter
Resources/    Fonts, sample .bas programs, privacy manifest
```

The split is deliberate: anything that can be reasoned about without SwiftUI or
the interpreter lives in the package, where `swift test` and the SPM quality-gate
checkers reach it. `IO/`, `Views/`, and `ViewModels/` hold only what genuinely
needs a UI framework.

### Key Types

| Type | Purpose |
|------|---------|
| `TerminalBuffer` | Screen grid, cursor, scrollback, and ANSI/CSI escape handling |
| `ProgramStore` | Line-numbered program storage, `LIST`/`DEL` ranges, source parse/render |
| `REPLParser` / `REPLCommand` | Classifies a typed line as stored line, direct statement, or empty |
| `BlockingInputChannel` | Hands input to the blocked interpreter thread; bounded waits, latched cancellation |
| `TerminalViewModel` | `@MainActor @Observable` bridge; owns the handlers and the terminal state |
| `InterpreterRun` | Holds the detached run task; cancels on replacement and on `deinit`, which a `@MainActor` type cannot do for itself |
| `ProgramCommands` | The menu bar: New / Open Sample / Run / Stop / List / Clear, with their key equivalents |
| `SwiftUIInputHandler` | `InputHandler` conformance; prompts the UI, delegates blocking to `BlockingInputChannel` |
| `SwiftUIOutputHandler` | `OutputHandler` conformance; forwards output actions to the main actor |
| `iPadSoundAdapter` | `SoundHandler` conformance; speaker tone generation |
| `TerminalTheme` / `TerminalFont` / `ThemeSettings` | Retro appearance and display settings |

### Data Flow

```
User types → TerminalViewModel → REPLParser
                                   ├── .store    → ProgramStore
                                   └── .direct   → executeSource
                                                     ↓
                    Lexer → Parser → Interpreter (detached background task)
                                                     ↓
        OutputHandler ─┐                    InputHandler ─┐
                       ↓                                  ↓
        main actor → TerminalBuffer            BlockingInputChannel
                       ↓                                  ↑
                  TerminalView                   UI submit / STOP
```

The interpreter is synchronous and runs on a detached task. Output crosses to
the main actor via callbacks; input crosses back by blocking that thread until
the UI answers.

---

## Core Architectural Decisions

1. **Platform-independent logic lives in an SPM package, not the app target.**
   The app began Xcode-only, which meant `swift test` and most quality-gate
   checkers had nothing to analyze. Logic moves into `ApplesoftBASICAppCore`
   as it is made testable.
2. **The interpreter runs synchronously on a detached task, not as async code.**
   ApplesoftBASICLib is a synchronous interpreter; wrapping it in async would
   mean rewriting it. The cost is that `INPUT` must block a real thread, which
   makes the input handoff the delicate part of the design.
3. **Blocking waits carry a deadline, always.** Input itself never times out —
   a user may take as long as they like to type — but every wait is sliced so
   the parked thread re-reads its state rather than depending on a signal that
   may never arrive.
4. **`project.yml` is the source of truth for build settings.** The `.xcodeproj`
   is generated by XcodeGen and should never be hand-edited.
5. **One codebase for iPad, Mac, and Vision Pro.** Platform differences are
   handled with scoped `#if os(...)` adjustments rather than forked views.

---

## Current Status

### What's Working
- [x] Applesoft BASIC interpreter app shipping on iPad (v1.0.0, 2026-06-07)
- [x] ApplesoftBASICAppCore — the platform-independent core: `TerminalBuffer`,
      `ProgramStore`/`REPLParser`, and `BlockingInputChannel`, with swift-testing
      suites (54 tests green) and a DocC catalogue
- [x] Native macOS and visionOS builds alongside iPad (v1.1.0)
- [x] `PrivacyInfo.xcprivacy` privacy manifest for App Store submission
- [x] `project.yml` is the single source of truth for build settings; the
      `.xcodeproj` is generated via XcodeGen
- [x] macOS UI audit — three iPad-shaped assumptions found and fixed for v1.1.0:
      sheets collapsing (macOS sizes sheets to content), dark-on-black chrome
      (window appearance did not follow the theme), and the split view opening
      with the editor pane hidden
- [x] visionOS verified in the simulator (visionOS 27.0) — split view, themed
      chrome, and program execution all render correctly
- [x] Desktop-shaped interface: a menu bar (`ProgramCommands`) covering New /
      Open Sample / Run / Stop / List / Clear, a macOS `Settings` scene on ⌘,
      and a sample browser that previews a listing before loading it. The scene
      owns the interpreter and the theme settings so the menu bar, the Settings
      window, and the window's toolbar all address the same objects
- [x] Accessibility pass: VoiceOver labels on every glyph-only control, Dynamic
      Type on the terminal fonts (`relativeTo: .body` over the size slider), and
      High Contrast variants for all six theme colours in the asset catalogue
- [x] Interpreter input handoff bounded and tested — `BlockingInputChannel`
      replaces the unbounded `DispatchSemaphore.wait()` that could strand the
      interpreter thread, and fixes the banked-signal bug where a STOP between
      prompts made the next `INPUT` return stale text

### What's Next
- [ ] Exercise visionOS on device; simulator coverage is not a substitute
- [ ] The macOS sheet minimum frames are scoped `#if os(macOS)`. If visionOS or a
      future platform sizes sheets to content the same way, that floor needs to
      widen rather than be rediscovered as a new bug.
- [ ] `TerminalViewModel` still holds untested UI-adjacent logic. It is the last
      large piece not reachable from `swift test`; extract as testable seams
      emerge rather than in one sweep.

---

## Quality Standards

### Code Quality
- All code follows `coding_rules.md`
- TDD: failing tests before implementation
- Documentation for all public APIs
- No warnings in build output
- Quality gate: 0 errors, 0 warnings before every commit

### Documentation Quality
- DocC comments for all public functions
- Usage examples in documentation
- Articles for complex topics

---

## Collaboration Principles

### AI as Sparring Partner, Not Oracle

AI proposes; the human interrogates. High AI confidence triggers harder questions, not faster acceptance.

- **Interrogate confident outputs.** When the AI states something with certainty, ask for the counterargument before accepting.
- **Demand counterarguments.** Before locking in an approach, require an explicit case for the strongest alternative.
- **Sit with discomfort.** Resist the pull to take the first plausible answer.

This principle is operationalized in the **Adversarial Review** step of `design_proposal.md`.

---

## Roadmap

### Phase 1: [Name]
- [ ] [Milestone]

### Phase 2: [Name]
- [ ] [Milestone]

### Future
- [Ideas not yet committed to]

---

**Last Updated:** 2026-08-19 (recorded the HIG work — menu bar commands, the macOS
Settings scene, the sample browser's preview pane — and then cleared the rest of the
gate backlog behind it: `concurrency`, `accessibility`, `memory-lifecycle`, and
`consistency`. The gate is at 0 errors / 0 warnings across all 28 enabled checkers,
with no exemption comments added. The phosphor palette moved to the asset catalogue
with High Contrast variants rather than being exempted as intentional — the colours
are still the ones chosen here, but Increase Contrast now reaches them.)

**Previously:** 2026-08-17 (filled in the Architecture sections against shipped
code — they had been template placeholders since the project began, so the module
structure, key types, data flow, and architectural decisions are now recorded
rather than assumed. Added the `Modules` checklist the `status` checker was asking
for, and recorded the `BlockingInputChannel` extraction and input-wait fix. The
Roadmap phases remain template placeholders awaiting product direction — that is a
real gap, not an oversight, and inventing milestones here would be worse than
leaving it visible.

Note for future edits: the `status` checker only looks for module entries under
`### What's Working`. A `- [x] ApplesoftBASICAppCore` line under any other heading
is not seen, and the module name must be followed by an em-dash or end of line —
`- [x] ApplesoftBASICAppCore package extracted` does not match.)
