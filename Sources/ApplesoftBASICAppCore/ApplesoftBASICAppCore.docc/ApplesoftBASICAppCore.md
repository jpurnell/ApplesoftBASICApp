# ``ApplesoftBASICAppCore``

The platform-independent models behind the Applesoft BASIC app.

## Overview

These types hold the app's state and behavior with no dependency on SwiftUI or
on the interpreter, so they can be exercised directly by tests.

## Topics

### Editing a program

- ``ProgramStore``

### Reading what the user typed

- ``REPLParser``
- ``REPLCommand``

### Driving the terminal

- ``TerminalBuffer``

### Waiting for input

- ``BlockingInputChannel``
