# Steady — Product Spec (working name, rename freely)

A tiny, native iOS habit tracker. Install, add habits, done.
No account, no ads, no paywall on features, no subscription. Target download size: **under 5 MB**.

## Why this app exists (the competitor problems we fix)
- Competitors weigh 200–300 MB for a habit tracker. → Pure SwiftUI, zero third-party dependencies, minimal assets.
- Widgets and unlimited habits are paywalled. → Everything functional is free, forever.
- Subscriptions / intrusive ads. → One optional cosmetic "Supporter" purchase, never pushed.
- Can't backdate. → Any habit can start in the past.
- Missing a day feels like punishment. → Per-habit choice of Strict or Forgiving counting.

---

## 1. Core concepts

### Habit
| Field | Notes |
|---|---|
| name | Free text, e.g. "Drink 8 glasses of water" |
| emoji | One emoji (system emoji keyboard, limited to 1 grapheme) |
| color | One of 12 palette colors (must look good in light and dark) |
| kind | **Start** (build) or **Stop** (quit) |
| stopTracking | Stop habits only: **Auto** or **Manual** (see below) |
| countingMode | **Forgiving** (default) or **Strict** |
| startDate | Any date ≤ today. Backdating allowed |
| reminder | Optional, one daily time |
| sortOrder, isArchived, createdAt | |

### Day result
Each habit has at most one entry per calendar day: `success`, `fail`, or `noteOnly` (a note with no result).
Days are stored as an integer day key (e.g. `20261101`) computed in the user's current calendar, never as raw `Date`, to avoid timezone/DST bugs.

How a day resolves (days before `startDate` or after today are not applicable):

| Habit type | Entry exists | No entry, past day | No entry, today |
|---|---|---|---|
| Start | success → done / fail → failed | missed | pending |
| Stop · Auto | fail → slipped | **clean (success)** | **clean (success)** |
| Stop · Manual | success → clean / fail → slipped | missed | pending |

- **Stop · Auto**: every day counts as clean automatically; the user only logs slips.
- **Stop · Manual**: the user checks each day they stayed clean.

### Counting modes (keep it this simple, no extra rules)
- **Strict**: big number = current streak (consecutive success days). A failed or missed day resets it to 0. A *pending* today never breaks the streak (streak is counted up to yesterday until today is resolved).
- **Forgiving**: big number = total success days since start date. Subtitle = success % = success days ÷ resolved days (pending today excluded). Nothing ever resets.
- Both modes show **best streak** in the habit detail screen.
- Counting is computed from entries, never stored, so switching modes is instant and lossless.

### Backdating
When the start date is in the past:
- Stop · Auto: past days are automatically clean.
- Start / Stop · Manual: the form shows a toggle **"I did it every day since then"** → bulk-creates success entries for those days. Otherwise past days stay missed and can be edited in the calendar.

---

## 2. Screens

### First launch (single screen, shown once)
Choose where data lives:
- **iCloud** (recommended): "Synced across your devices and kept if you reset or replace your phone."
- **On this iPhone only**: "Private, never leaves your phone. ⚠️ If you delete the app or reset your phone, your habits are lost unless you export them."
Then straight to the empty Home with one "Add your first habit" button. No other onboarding, no tutorial.

### Home
- Navigation: Settings (left), + (right). Title: today's date.
- One card per habit:
  - emoji + name
  - big number + label ("12-day streak" / "42 days · 88%"), rounded font, monospaced digits
  - current week row Mon→Sun: 7 small squares (habit color = success, muted with × = fail/missed, outline = pending/future, ring = today)
  - large today button on the right:
    - Start / Stop·Manual: tap = mark done / undo
    - Stop·Auto: shows "clean" by default; tap = log slip (undo toast for 4s)
- Tap a week square = toggle that day. Long-press a square = add/edit note.
- Tap card = Habit detail. Long-press + drag = reorder.
- Light haptic on every toggle.

### Add / Edit habit (sheet)
Fields in this order: name · emoji · color swatches · Start/Stop segmented · (Stop) Auto/Manual with one-line explanation · Forgiving/Strict with one-line explanation · start date (max today) · (conditional) "I did it every day since then" · reminder toggle + time.
Edit mode adds: Archive, Delete (with confirmation).
The whole form fits on one screen on an iPhone SE without feeling crowded.

### Habit detail
- Header: emoji, name, big number.
- Stats row: current streak · best streak · success % · total days.
- Month calendar (Monday first), swipe between months, back to start date. Tap day = cycle result, long-press = note. Days with a note show a small dot.
- Notes list (newest first): date + text. Tap to edit.
- Edit button.

### Settings
- Storage: iCloud / On this iPhone only (same explanations as first launch). Switching migrates all data (see §5).
- Appearance: System / Light / Dark.
- Reminders: permission status + link to iOS Settings if denied.
- Export: JSON (full backup) and CSV (human-readable), via ShareLink.
- Import: JSON (merge or replace, with confirmation).
- Archived habits (restore / delete).
- Support Steady (Supporter pack) + Restore purchase.
- About: version, privacy statement ("Steady collects no data"), contact email.

---

## 3. Design
- UI is strictly **black and white**: white background / black text in light mode, **true black** (#000) / white text in dark mode (OLED-friendly). Greys only for secondary text and separators.
- **Color appears only through habits**: their week squares, calendar cells, and today button fill. Never in chrome, buttons or backgrounds.
- System font (SF Pro), SF Pro Rounded for big numbers. No custom fonts.
- No gradients, no shadows, no illustrations, no mascots. Generous spacing (16pt grid), large tap targets (≥44pt).
- SF Symbols for all UI icons.
- Full Dynamic Type and VoiceOver support (each day square announces e.g. "Tuesday, done").
- Palette (12): red, orange, amber, yellow, lime, green, teal, cyan, blue, indigo, purple, pink. Tune each so it reads on both white and black.

---

## 4. Widgets (WidgetKit, all **view-only**, tap opens the app)
All widgets show the current week, **Monday first**, same square states as Home. Follow system light/dark, support iOS tinted/accented rendering gracefully.

- **Small**: one habit (user picks it in widget config): emoji, name, big number, week row.
- **Medium**: up to 4 habits, one row each: emoji + name + 7 squares. Weekday letters header.
- **Large**: up to 9 habits, same rows, plus date header.
- Medium/Large are configurable (choose habits) and default to the first N habits in Home order.
- Tap: Small → opens that habit's detail; Medium/Large → Home.
- Timeline refreshes at local midnight; the app calls `WidgetCenter.reloadAllTimelines()` after every change.
- Data source: the app writes a compact JSON snapshot to the App Group container after each change (habit info + last 7 days resolved + counter text). Widgets read only that snapshot (fast, small, no database or CloudKit in the extension).

---

## 5. Data & storage
- SwiftData, iOS 17+.
- Two modes, chosen at first launch, changeable in Settings:
  - **Local**: `ModelConfiguration(cloudKitDatabase: .none)`, store file `local.store`.
  - **iCloud**: `ModelConfiguration(cloudKitDatabase: .private(containerID))`, store file `cloud.store`.
- Switching modes: copy every habit and entry into the other store, verify counts, then delete the old store. Show a short progress state. If iCloud is unavailable (not signed in), explain and stay local.
- CloudKit-compatible model rules: every property has a default or is optional, no `@Attribute(.unique)`, relationships optional with inverses.
- Because CloudKit can create duplicates during sync, deduplicate entries by (habitID, dayKey) on load (keep the newest).
- Export JSON includes a `schemaVersion` field.

---

## 6. Reminders
- Local notifications only (UserNotifications). Ask permission the first time a reminder is turned on, never at launch.
- Message: "{emoji} {name}". Stop habits: "{emoji} Still going strong today?"
- Skip a day's reminder if the habit is already resolved that day: instead of a repeating trigger, schedule one-shot notifications for the next N days and reschedule on every change and app foreground. N = min(7, 60 ÷ number of habits with reminders) to stay under iOS's 64 pending limit.

---

## 7. Monetization (no paywall, no ads, no subscription)
- StoreKit 2, one **non-consumable "Supporter Pack" — $2.99**.
- Unlocks cosmetic extras only: 4 alternate app icons + 6 extra habit colors. Never features, habit count or widgets.
- Surfaced in exactly two places: a row in Settings, and one gentle dismissible card on Home after 14 days of use (shown once, ever).
- Thank-you message after purchase. Restore purchase in Settings.
- Ask for an App Store rating once, after the user's first 7-day streak (SKStoreReviewController / `requestReview`).
- Include a `.storekit` configuration file for local testing.

---

## 8. Localization
English, French, Spanish, German via a String Catalog (`Localizable.xcstrings`), with proper plurals ("1 day" / "2 days"). Dates/numbers via system formatters. Week always starts Monday regardless of locale.

## 9. Privacy
No analytics, no crash SDKs, no network calls except CloudKit (if chosen) and StoreKit. App Store privacy label: **Data Not Collected**. Include `PrivacyInfo.xcprivacy` (declare UserDefaults required-reason API).

## 10. Out of scope for v1
Counts/quantities, multiple reminders per habit, schedules (e.g. "3× per week"), Apple Watch, Mac, Lock Screen widgets, interactive widgets, Shortcuts, Health integration, social features, accounts.
