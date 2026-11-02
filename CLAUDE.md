# CLAUDE.md — Steady (iOS habit tracker)

Read `SPEC.md` before any work. It is the source of truth for product behavior. If something is ambiguous, ask instead of inventing features.

## Non-negotiables
- **Zero third-party dependencies** in the app and widget (no SPM packages, no CocoaPods). Apple frameworks only.
- **Download size under 5 MB.** No bundled images except the app icons. SF Symbols for UI icons.
- **No network code** except CloudKit (via SwiftData) and StoreKit 2. No analytics, no logging SDKs.
- **No feature paywalls.** The Supporter pack is cosmetic only (alternate icons + extra colors).
- UI chrome is black & white only. Color comes exclusively from habit colors.

## Stack
- Swift 6, SwiftUI, SwiftData, WidgetKit, AppIntents (widget configuration only), UserNotifications, StoreKit 2.
- Minimum iOS 17.0. iPhone only, portrait.
- Project generated with **XcodeGen** (`project.yml` at repo root). Never hand-edit the `.xcodeproj`; edit `project.yml` and run `xcodegen generate`.

## Targets
- `Steady` (app)
- `SteadyWidgets` (widget extension: small, medium, large)
- `SteadyTests` (unit tests)
- Shared code in `Shared/` compiled into both app and widget: day keys, day resolution, counters, widget snapshot model, palette.
- App Group: `group.com.crva.steady`.
- iCloud container: `iCloud.com.crva.steady`.

## Suggested layout
```
project.yml
Steady/
  App/            SteadyApp.swift, RootView, AppState
  Models/         Habit.swift, DayEntry.swift (SwiftData)
  Features/       Home/, HabitForm/, HabitDetail/, Settings/, Onboarding/
  Services/       StoreController, ReminderScheduler, WidgetSnapshotWriter,
                  StorageModeController (local ⇄ iCloud migration), ExportImport
  Resources/      Assets.xcassets, Localizable.xcstrings, PrivacyInfo.xcprivacy, Steady.storekit
Shared/           DayKey.swift, DayResolver.swift, HabitStats.swift, WidgetSnapshot.swift, Palette.swift
SteadyWidgets/
SteadyTests/
```

## Engineering rules
- Days are `Int` day keys (yyyyMMdd) from a single `DayKey` helper using a Gregorian calendar with `firstWeekday = 2` (Monday). Never compare raw `Date`s for "same day".
- All counting logic (`DayResolver`, `HabitStats`) is pure, stateless, and fully unit tested: strict and forgiving modes, all three habit types, backdated start, pending today, DST change, a habit that starts today, and duplicate entries for the same day.
- SwiftData models must be CloudKit-compatible: defaults or optionals on every property, no unique constraints, optional relationships with inverses.
- After any data change: write the widget snapshot to the App Group, call `WidgetCenter.shared.reloadAllTimelines()`, reschedule reminders.
- Widgets read only the JSON snapshot, never SwiftData.
- Every user-facing string goes through the String Catalog (EN, FR, ES, DE).
- Accessibility labels on every custom control (especially day squares).
- Keep views small. Prefer `@Observable` over `ObservableObject`. No singletons except where Apple APIs require them.

## Verify before saying a milestone is done
1. `xcodegen generate`
2. `xcodebuild -scheme Steady -destination 'platform=iOS Simulator,name=iPhone 16' build`
3. `xcodebuild test -scheme Steady -destination 'platform=iOS Simulator,name=iPhone 16'`
4. Report: what was built, test results, and any manual steps the user must do in Xcode or App Store Connect (signing, capabilities, CloudKit container, IAP product).

If a simulator name isn't available, list simulators with `xcrun simctl list devices available` and pick an iPhone.
