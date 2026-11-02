# Setup (once, on your Mac)
1. Install Xcode (latest) and XcodeGen: `brew install xcodegen`
2. Create an empty folder, put `CLAUDE.md` and `SPEC.md` in it, `git init`.
3. Open Claude Code in that folder and paste the prompt below.

---

# Prompt to paste into Claude Code

We're building **Steady**, a tiny native iOS habit tracker. Read `CLAUDE.md` and `SPEC.md` fully before writing any code. They are the source of truth.

Work milestone by milestone. After each one, build, run the tests, give me a short summary plus any manual Xcode steps I need to do, then **stop and wait for my OK**.

**M1 — Foundation**
- `project.yml` (XcodeGen) with the app, widget extension, and test targets, App Group + iCloud capabilities using the placeholder IDs from CLAUDE.md.
- SwiftData models (`Habit`, `DayEntry`), CloudKit-compatible.
- `Shared/`: `DayKey`, `DayResolver`, `HabitStats`, `Palette`, `WidgetSnapshot`.
- Thorough unit tests for all counting logic (every case listed in CLAUDE.md).

**M2 — Core app**
- First-launch storage choice screen (local storage only for now; store the choice).
- Home with habit cards, week row, today button, undo toast, reorder.
- Add/Edit habit sheet including backdating and "I did it every day since then".
- Habit detail with stats, month calendar, notes.

**M3 — Widgets**
- Snapshot writer in the app, small/medium/large widgets reading the snapshot, configurable habit selection, midnight refresh, deep links.

**M4 — Storage & data**
- iCloud mode, local ⇄ iCloud migration in Settings, dedup, JSON/CSV export, JSON import.

**M5 — Reminders**
- Per-habit reminder with the rolling one-shot scheduling described in SPEC §6.

**M6 — Polish & ship-ready**
- Settings screen complete, Supporter pack (StoreKit 2 + `.storekit` file, alternate icons, extra colors), review prompt, EN/FR/ES/DE localization, privacy manifest, accessibility pass, dark/light check, size check of the archived build.

Start with M1.
