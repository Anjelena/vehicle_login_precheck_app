# Follow-Up Questions

Decisions deferred until the project lead has confirmed, or open items to revisit
**after the four-chunk roadmap is complete**. Append new items at the bottom of
each section as they come up.

---

## After chunk 1 — auth & restructure

- **Audit log lifecycle for prestart submissions.** Once chunk 2 lands the
  `prestart_submissions` table, decide what to do with rows long-term:
  keep indefinitely (audit trail), delete on logout, push to the integrating
  app's data store, or some combination. Current default for chunk 2: keep
  indefinitely.

## After chunk 1.5 — input refactor (PCB + Flipper)

- **PCB disconnect during an active session.** Currently we only react to
  disconnect on the login screen (logged but invisible). After chunk 4, decide:
  force logout if the PCB is detached during prestart/welcome? Show a banner?
  Tie this to the chunk 3 power-loss timer?
- **Connection visibility.** Currently invisible (no UI). Decide later: small
  connection indicator? Hidden long-press for a diagnostics panel? Settings
  screen?
- **Card-identifier shape.** Schema is `card_no INTEGER`. Confirm with the
  integrating team that this matches their data store, or extend the schema
  with an alternate ID column (UID string, Wiegand pair, etc.) at integration
  time.
- **Canonical card-id across transports.** A single physical card produces
  **different** `card_no` values via the two readers:
  - PCB firmware → derived 5-digit decimal (e.g. `11913`)
  - Flipper Zero → raw 12-hex UID parsed as int (e.g. `0x900F4CA2E890` = `158395384653968`)

  In dev we currently work around this by seeding two rows for the same user.
  At integration time the team needs to pick one canonical identifier and
  decide which reader's value is the source of truth — or have the data store
  hold both and resolve by either. Worth a conversation with whoever wrote
  the PCB firmware to understand the derivation (Wiegand bit-extraction vs
  full UID, etc.).
- **PCB output format coverage.** Parser currently handles
  `{"CardNo": <int>}`. Confirm with the firmware author this is the only line
  shape — if errors, status messages, or extended fields are ever emitted, the
  parser needs another branch in `_handleLine`.

## After chunk 2 — prestart

- **Audit log lifecycle.** The `prestart_submissions` table grows unbounded. Decide
  on retention: keep indefinitely (full audit trail), purge on logout, cap to
  the last N submissions per user, or push to the integrating app's data store
  and clear locally. The integrating team probably has compliance requirements.
- **Audit log access.** Currently no UI views the saved submissions. Decide
  whether the standalone app needs a "history" screen (rare for kiosk use)
  or this is purely write-only until integration takes over.
- **Question content management.** Questions are seeded from the bundled
  `assets/prestart_questions.json` on first install. Updating questions
  requires a DB version bump + reinstall (or the integrating team replacing
  the repository entirely). Decide whether the production app needs runtime
  question updates (admin screen? remote sync?).
- **"All required answered" vs. "All correct".** Current behavior matches the
  parent app: a check is "complete" once every required question is *answered*,
  even if some answers are wrong (those go in the issues list with mandatory
  comments). Confirm with the project lead this is the intended UX vs. blocking
  submission until all answers are correct.
- **Back button on prestart.** Tapping the back arrow logs the user out and
  returns to login, losing in-progress answers. Decide: confirm dialog before
  losing progress? Or treat in-progress prestart as discardable?

## After chunk 3 — welcome + power-loss

- **"Sleep mode" depth.** Current behaviour after the 10 s countdown: clear the
  session and route to the `/no-power` screen (black scaffold with an
  "Ignition Off" message). The screen itself stays awake. To physically turn
  the display off requires Device Admin / Accessibility Service / Device Owner
  permissions — none of which the app currently has. Decide whether we need to
  pursue one of those, or whether relying on the tablet's own display timeout
  (set in Android Settings → Display) is good enough.
- **Battery vs ignition distinction.** `battery_plus` reports
  charging/discharging, which on a wired-into-vehicle setup tracks ignition
  state — *only because* removing ignition kills the charger. If the tablet
  ever has its own battery topped up and is unplugged from the vehicle for
  other reasons (maintenance, transport), the app would treat that as
  "ignition off". Confirm with the project lead that this is acceptable, or
  add a separate ignition-signal pathway later.
- **`unknown` battery state on cold boot.** `PowerMonitor` reads initial state
  synchronously before `runApp`, but if the platform returns `unknown` it's
  treated as on-power (optimistic). Confirm this is the right default — the
  alternative is to refuse to enter the login flow until the state is
  conclusively known.
- **`PowerReceiver.kt` / `WakeForegroundService.kt` not ported.** The parent app's
  Kotlin side had a foreground service plus broadcast receivers for power events.
  We currently rely solely on Dart-side `battery_plus`. If kiosk-mode wake
  behaviour gets flaky in production (e.g. Android killing the app to save
  battery while ignition is off, then not resuming cleanly), revisit and bring
  the Kotlin pieces across.

## After chunk 4 — rename & polish

- (to be added)
