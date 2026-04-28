# AGENTS.md — Breedy

## Project Overview

**Breedy** is a native SwiftUI iOS breathing & mindfulness app. It features a lovable mascot named Breedy that guides users through breathing sessions, tracks progress, and builds daily habits — all while being privacy-first, offline-capable, and delightful.

---

## Tech Stack

- **Language**: Swift 5
- **Framework**: SwiftUI (iOS 17+)
- **Persistence**: SwiftData (no Core Data)
- **Architecture**: MVVM + Observable (Observation framework)
- **Concurrency**: Swift Concurrency (async/await, MainActor isolation)
- **Health**: HealthKit (mindful minutes)
- **Notifications**: UserNotifications framework
- **Charts**: Swift Charts
- **Analytics**: None (privacy-first)
- **External Dependencies**: None

---

## Project Structure

```
breedy/
├── breedyApp.swift              # App entry point, SwiftData container, environment injection
├── Design/
│   └── BDDesign.swift           # Design system tokens (colors, typography, spacing, shadows)
├── Models/
│   ├── AppState.swift           # Central app state, navigation, settings persistence
│   ├── BreathingModels.swift    # Breathing phases, patterns, presets, mood states
│   └── DataModels.swift         # SwiftData models (SessionRecord, DailyCheckIn, etc.)
├── Services/
│   ├── BreathingEngine.swift    # Core breathing state machine with timer
│   ├── HapticsManager.swift     # Centralized haptic feedback
│   ├── HealthManager.swift      # Apple Health integration
│   ├── NotificationManager.swift # Local notification scheduling
│   └── StatsManager.swift       # Session recording, stats, badges, data export
├── Components/
│   ├── BreedyMascotView.swift   # Animated mascot drawn in SwiftUI
│   └── SharedComponents.swift   # Reusable components (orb, cards, tiles, chips)
├── Views/
│   ├── MainTabView.swift        # Tab navigation shell
│   ├── HomeView.swift           # Home screen with mood selector, quick start
│   ├── BreathingSessionView.swift # Full breathing session experience
│   ├── SessionsView.swift       # Session library + custom pattern builder
│   ├── ProgressView.swift       # Stats, charts, heatmap, badges
│   ├── CompanionView.swift      # Breedy companion, check-ins, unlockables
│   ├── OnboardingView.swift     # 3-step onboarding flow
│   └── SettingsView.swift       # App settings, reminders, data management
└── Assets.xcassets/             # Color assets, app icon
```

---

## Key Architecture Decisions

### State Management
- **`@Observable` (Observation framework)** for `AppState`, `StatsManager`, `BreathingEngine`, etc.
- `@AppStorage` wrapped with `@ObservationIgnored` for persisted settings inside `@Observable` classes.
- `@State` for view-local state.
- Environment injection via `.environment()` for shared services.

### Breathing Engine
- State machine with explicit states: `idle`, `active`, `paused`, `completed`.
- 50ms timer tick for smooth animations.
- Phase-aware orb scaling and progress tracking.
- Callbacks for phase transitions, cycle completions, and session end.

### Persistence
- **SwiftData** for all structured data (sessions, check-ins, badges, custom patterns).
- **`@AppStorage`** for settings and lightweight flags.
- No remote storage or sync — everything is local-first.

### Design System
- Vercel-inspired design adapted for iOS (see `DESIGN.md`).
- Uses native **SF Pro** typography (not Geist) per design doc instructions.
- Shadow-as-border philosophy translated to SwiftUI overlays.
- Adaptive dark mode throughout.

---

## Coding Conventions

### Naming
- Types: `PascalCase` (e.g., `BreathingEngine`, `SessionRecord`)
- Properties/methods: `camelCase`
- Design tokens: `BDDesign.Colors.*`, `BDDesign.Typography.*`, `BDDesign.Spacing.*`
- View modifiers: prefixed with `bd` (e.g., `.bdCard()`, `.bdPrimaryButton()`)

### Patterns
- MARK comments to section files: `// MARK: - Section Name`
- Preview providers at the bottom of each View file.
- View modifiers for reusable styling (see `BDDesign.swift`).
- Explicit `@MainActor` on all manager/service classes.
- `private(set)` for engine state properties.

### Error Handling
- `try?` for non-critical persistence operations.
- Graceful fallbacks (empty arrays, default values) when data is missing.
- No force-unwrapping except in controlled contexts.

---

## Adding Features

### New Breathing Pattern
1. Add a static property in `BreathingPresets` (in `BreathingModels.swift`).
2. Add it to the `allPresets` array.
3. Optionally add to mood-based recommendations in `presetsFor(mood:)`.

### New Badge
1. Add a `BadgeDefinition` in the `allBadges` array (in `DataModels.swift`).
2. Add unlock logic in `StatsManager.checkBadges()`.

### New Tab
1. Add a case to `AppTab` enum (in `AppState.swift`).
2. Add the tab in `MainTabView.swift`.
3. Create the View file in `Views/`.

### New Setting
1. Add `@AppStorage` property (in `AppState.swift` or the relevant View).
2. Add UI control in `SettingsView.swift`.

---

## Build & Run

1. Open `breedy.xcodeproj` in Xcode.
2. Select an iOS Simulator or device.
3. Build and run (⌘R).
4. No external dependencies to install.

### Requirements
- Xcode 16+ (Swift 5.10+)
- iOS 17+ deployment target
- No CocoaPods, SPM packages, or external frameworks required.

---

## Testing

- All business logic is in testable service classes (`StatsManager`, `BreathingEngine`).
- SwiftData models can be tested with in-memory containers.
- Views can be previewed individually via `#Preview` blocks.

---

## Privacy

- No user accounts required.
- All data stored locally via SwiftData.
- No analytics, no tracking, no network requests.
- Optional Apple Health integration (user-initiated).
- Data export available as JSON.
