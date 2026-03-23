# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Clocker is a macOS menu bar utility (Swift 5, AppKit) that helps users track time across different time zones. It's a native macOS app targeting Sierra 10.12+, distributed via the Mac App Store and Homebrew.

## Build & Test Commands

```bash
# Build
xcodebuild -project Clocker/Clocker.xcodeproj -scheme Clocker build

# Run all tests
xcodebuild -project Clocker/Clocker.xcodeproj -scheme Clocker test

# Run unit tests only
xcodebuild -project Clocker/Clocker.xcodeproj -scheme ClockerUnitTests test

# UI tests must be run from within Xcode — running them via xcodebuild fails due to
# a code signing Team ID mismatch between the app and the UI test runner bundle.

# Lint
swiftlint lint --path Clocker/Clocker

# Lint with analyzer rules (requires build)
swiftlint analyze --compiler-log-path build/CompileSwift.log
```

The project uses Xcode directly — open `Clocker/Clocker.xcodeproj` for day-to-day development.

## Architecture

### Module Structure

The app is split into the main `Clocker` target plus three Swift packages:
- **CoreModelKit** — data models (`TimezoneData`, `SearchResults`, etc.)
- **CoreLoggerKit** — centralized logging
- **StartupKit** — app initialization/startup orchestration

### Feature Modules (inside `Clocker/Clocker/`)

| Directory | Purpose |
|-----------|---------|
| `Overall App/` | App-wide services: `DataStore`, `AppDefaults`, `Themer`, `DateFormatterManager`, `NetworkManager` |
| `Menu Bar/` | `StatusItemHandler`, `MenubarHandler` — manages the menu bar status item |
| `Panel/` | Main UI panel: `ParentPanelController` (primary controller), `PanelController`, `FloatingWindowController`, `TimezoneDataSource`, `TimezoneDataOperations` |
| `Preferences/` | Settings UI split into General, Appearance, Menu Bar, Calendar, and About sub-controllers |
| `Onboarding/` | First-run flow: search, permissions, start-at-login, and final screens |
| `Events and Reminders/` | `EventCenter`, `CalendarHandler`, `RemindersHandler` for OS calendar/reminder integration |

### Key Data Flow

```
AppDelegate
  └── StatusItemHandler (menu bar)
  └── PanelController / FloatingWindowController
        └── ParentPanelController
              ├── TimezoneDataSource  ←→  DataStore (UserDefaults)
              └── UpcomingEventsDataSource  ←→  EventCenter
```

`DataStore` is the single source of truth for persisted timezone list and settings; it wraps `UserDefaults` and is accessed throughout the app as a shared instance.

### Panel vs. Floating Window

The app has two display modes controlled by a user preference:
- **Panel** (`PanelController`) — anchored to the menu bar item
- **Floating Window** (`FloatingWindowController`) — free-floating, always-on-top window

Both share `ParentPanelController` for the core UI logic (time display, slider scrubbing, upcoming events).

### Theming

`Themer.swift` manages light/dark/system appearance. UI components observe `Themer` notifications to update colors. Always use `Themer` for colors rather than hardcoded values.

## SwiftLint Configuration

Line length limit: 200. `explicit_self` is enforced via the analyzer rules. Tests and `Dependencies/` are excluded from linting.

## Release Process

`release.py` automates version bumping (`agvtool`), clean build+analyze, test run, and GitHub release creation. Firebase Crashlytics is integrated for crash reporting in Release builds only.
