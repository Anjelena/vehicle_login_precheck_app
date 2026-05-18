# RFID Scanner App — Extraction & Architecture Notes

Standalone Flutter app extracted from `vis_tac_app` (Tomago VIS HMI). Hosts the **login (RFID) + prestart** functionality, designed to be integrated into a larger app later. Card validation runs against a local SQLite dummy database in development; the real data layer is plugged in via repository interfaces at integration time.

- **Source app:** `c:\src\Tomago_VIS\vis_tac_app`
- **This app:** `c:\src\rfid_scanner_app`
- **Package id:** `com.example.rfid_scanner_app` (different from `com.example.vis_tac_app` so both can be installed side-by-side)
- **Target platform:** Android (tablet, site WiFi). No MQTT, no IVMS Ethernet binding.
- **RFID input:** USB-CDC serial **and** HID keyboard, simultaneously. Confirmed via the PCB inspector — see `c:\src\rfid_pcb_inspector`.

---

## Architecture

The app is organised as **feature folders** with a **repository pattern** at the data boundary. Everything that hits external data goes through an abstract repository interface; the SQLite-backed implementations are dummy and meant to be swapped at integration time.

```
lib/
├── main.dart                                  ← entry point: init logging + DB, build repos, runApp(App)
├── app.dart                                   ← MaterialApp, Provider tree, named routes
│
├── core/                                      ← cross-feature infrastructure
│   ├── config.dart                            ← USB VID/PID + baud-rate constants
│   ├── db/
│   │   ├── app_database.dart                  ← sqflite open + schema + seed-on-create + drop-and-recreate upgrade
│   │   └── seed_data.dart                     ← seed cards (edit this for additional test cards)
│   ├── logging/
│   │   └── app_logger.dart                    ← console + file logging via the `logger` package
│   ├── routing/
│   │   └── app_routes.dart                    ← named-route constants
│   ├── session/
│   │   └── session.dart                       ← ChangeNotifier holding the current AuthenticatedUser
│   └── theme/
│       └── app_theme.dart                     ← colors, text styles, dark theme
│
└── features/
    ├── auth/
    │   ├── data/
    │   │   ├── auth_repository.dart           ← abstract — INTEGRATION SEAM
    │   │   └── sqlite_auth_repository.dart    ← dummy implementation
    │   ├── domain/
    │   │   └── authenticated_user.dart        ← User model
    │   └── presentation/
    │       ├── login_screen.dart              ← UI (wires both readers + controller)
    │       ├── login_controller.dart          ← ChangeNotifier — owns LoginStatus, calls repository
    │       ├── serial_card_reader.dart        ← USB-CDC: auto-connect, parse JSON, emit cardNo
    │       └── keyboard_card_reader.dart      ← HID keyboard fallback (Flipper Zero etc.)
    │
    ├── prestart/
    │   ├── data/
    │   │   ├── prestart_repository.dart       ← abstract — INTEGRATION SEAM
    │   │   └── sqlite_prestart_repository.dart
    │   ├── domain/
    │   │   ├── prestart_question.dart
    │   │   ├── prestart_response.dart
    │   │   ├── prestart_check.dart            ← title + ordered questions
    │   │   └── prestart_submission.dart
    │   └── presentation/
    │       ├── prestart_screen.dart           ← UI (header + question list + submit FAB)
    │       ├── prestart_controller.dart       ← ChangeNotifier — load, answer, validate, submit
    │       └── widgets/
    │           ├── question_card.dart
    │           ├── answer_button.dart
    │           ├── badges.dart                ← Category, Required, KeySafety badges
    │           ├── completion_dialog.dart     ← submit-confirmation with issues + missing list
    │           ├── empty_state.dart
    │           └── submit_check_fab.dart
    │
    ├── welcome/
    │   └── presentation/
    │       └── welcome_screen.dart            ← terminal screen (chunk 2: name + clock; chunk 3 enhances)
    │
    └── no_power/
        └── presentation/
            └── no_power_screen.dart           ← chunk 3: "Ignition Off" terminal screen
```

And `lib/core/power/`:

```
core/power/
├── power_monitor.dart            ← wraps battery_plus, exposes hasPower
├── power_sleep_coordinator.dart  ← listens to PowerMonitor; 10s countdown on power-lost; logout + navigate on expiry
└── power_shutdown_overlay.dart   ← fullscreen countdown overlay rendered in MaterialApp.builder
```

> Each feature follows the same `data / domain / presentation` split. New features added in chunk 3 (`power`, etc.) will follow the same convention.

### Layering rules

- `presentation/` → may import `domain/` and `data/` (interfaces only — never the SQLite impl directly).
- `data/` → may import `domain/`.
- `core/` → may be imported by anything; never imports from `features/`.
- The dummy SQLite implementations are wired together **only in `main.dart`**. Every other file uses the abstract interfaces.

---

## Integration boundary — what the other team needs to do

When this code is folded into the production app, swap exactly **two interfaces**:

1. **[`AuthRepository`](lib/features/auth/data/auth_repository.dart)** — one method: `Future<AuthenticatedUser?> lookupCard(int cardNo)`.
2. **[`PrestartRepository`](lib/features/prestart/data/prestart_repository.dart)** — two methods: `Future<PrestartCheck> loadCheck()` and `Future<int> submitCheck(PrestartSubmission)`.

Inject both implementations at app startup by replacing the construction lines in [`main.dart`](lib/main.dart) — the `Sqlite*Repository` instances become whatever the production data layer provides, then those are passed into `App(authRepository: ..., prestartRepository: ...)`.

`AppDatabase`, `seed_data.dart`, the `assets/prestart_questions.json` asset, and the `Sqlite*Repository` files can all be deleted — they're development-only.

---

## Card-input transports

The login screen runs **both** readers simultaneously. Both call `LoginController.submitCard(int cardNo)`. The controller has an idle-state guard that drops re-entrant submissions, so a single scan from either source can't fire twice.

### USB-CDC (the production PCB)

- **Hardware:** RP2040-based custom PCB (Tomago) running MicroPython firmware. VID `0x2E8A` (Raspberry Pi). Native USB-CDC — baud rate is metadata-only, the firmware accepts any value. We use 115200 8N1 by convention.
- **Protocol:** newline-delimited JSON. One scan emits one line, terminated by `\r\n`:
  ```
  {"CardNo": 11913}\r\n
  ```
- **Auto-connect** — first attached device matching `AppConfig.pcbUsbVid`. On detach, the input stream closes and the reader silently waits for re-attach.
- **Parser tolerance** — extra JSON fields are ignored; `CardNo` may be either an int or a string-encoded int; non-JSON or malformed lines are logged and skipped.

VID-only filter means *any* RP2040 board will be picked up — you can build additional PCB units (Pico W, Pico 2) without changing this app.

### HID keyboard (development / Flipper Zero)

- Captures any `KeyDownEvent` on the login screen. Buffers digits + hex letters, fires on Enter or 500 ms idle.
- Tries `int.parse()` (decimal) then `int.parse(_, radix: 16)` (hex). Less than 4 chars or unparseable input → logged and discarded (avoids accidental keyboard typing on a dev tablet triggering fake scans).

If you need to disable one of the two paths in the future, remove the corresponding reader instantiation in `LoginScreen.initState`.

### Dual identifiers for the same card

The two readers produce **different** `card_no` values for the *same physical card*:

| Reader  | Sample output         | Parsed `card_no`     |
| ------- | --------------------- | -------------------- |
| PCB     | `{"CardNo": 11913}`   | `11913`              |
| Flipper | `900f4ca2e890\n`      | `158395384653968`    |

The PCB firmware derives a small decimal from the card's UID (likely a Wiegand-style bit-extraction); the Flipper emits the raw 12-hex-char identifier. To make either reader work during development, the seed in [seed_data.dart](lib/core/db/seed_data.dart) contains **two rows for the same user**, one per transport. Reconciling these into one canonical identifier is deferred to the integrating team — see [FOLLOW_UP_QUESTIONS.md](FOLLOW_UP_QUESTIONS.md).

---

## SQLite dummy database

| Table | Schema | Purpose |
| --- | --- | --- |
| `cards` | `card_no INTEGER PRIMARY KEY, name TEXT NOT NULL` | Card-to-user lookup for login. |
| `prestart_meta` | `key TEXT PRIMARY KEY, value TEXT NOT NULL` | Single-row config (currently only `check_title`). |
| `prestart_questions` | `id INTEGER PRIMARY KEY, category, question, correct_answer, is_required, is_key_safety, display_order` | The inspection questions, seeded from the bundled JSON asset. |
| `prestart_submissions` | `id PK AUTO, card_no, user_name, submitted_at, check_title, total_questions, answered_count, all_correct, answers_json` | Audit log of completed inspections. `answers_json` is the per-question detail (question text, category, answer, comment, correctness, key-safety) — captured at submission time so the audit row is self-contained even if questions change later. |

The DB lives at `<app documents directory>/rfid_scanner.db`. Path is logged at startup. Bumping `AppDatabase._dbVersion` triggers a drop-and-recreate that re-runs all seeding.

### Updating the seed for additional test cards

The seed is in [`lib/core/db/seed_data.dart`](lib/core/db/seed_data.dart). Currently has one card: `{ card_no: 11913, name: 'Test User' }` (the value confirmed via the PCB inspector).

To add another:
1. Run the app and scan the unknown card. It will be denied; the decimal card number is logged with `Login FAILURE: cardNo=N not found`.
2. Add a new entry to `seedCards`.
3. Bump `AppDatabase._dbVersion` (or uninstall and reinstall) so the seed re-runs.

---

## How to run

```sh
cd c:\src\rfid_scanner_app
flutter pub get
flutter run
```

Requires an Android device/emulator. For the PCB path you'll need an OTG adapter unless the tablet's USB-C is host-capable. Logs are written to the app's documents directory at `rfid_scanner.log`.

---

## Changelog

### Chunk 3 — Power-loss detection + 10 s logout-and-sleep + UI polish (current)

**Added:**
- `lib/core/power/power_monitor.dart` — wraps `battery_plus` and exposes `hasPower: bool`. Treats `unknown` optimistically so cold boot doesn't trip the overlay before the first real state event.
- `lib/core/power/power_sleep_coordinator.dart` — listens to `PowerMonitor`. On power-lost starts a 10 s `Timer.periodic` (so the overlay can show a live countdown). On power restored before expiry, cancels. On expiry: clears the session and navigates to `/no-power` via `GlobalKey<NavigatorState>`.
- `lib/core/power/power_shutdown_overlay.dart` — fullscreen translucent overlay (88% black, warning icon, big countdown). Absorbs touches so the user can't interact with the underlying screen during shutdown. Rendered in `MaterialApp.builder` so it sits on top of every route.
- `lib/features/no_power/presentation/no_power_screen.dart` — terminal "Ignition Off" screen. Listens to `PowerMonitor` and `pushNamedAndRemoveUntil` back to `/login` when power is restored.
- `AppRoutes.noPower = '/no-power'`.
- Boot-time route selection: `main()` reads the initial battery state synchronously and `App` picks `initialRoute = login` or `noPower` accordingly. So a cold boot with ignition already off lands directly on the no-power screen instead of briefly flashing login.
- `battery_plus: ^5.0.3` to `pubspec.yaml`. No new Android permissions required.

**Changed:**
- `App` now needs a `GlobalKey<NavigatorState>` to navigate from the coordinator (which is a non-widget service). `App` became non-`const` because of the navigator key field.
- `App.builder` wraps the navigator in a `Stack` so the overlay is always on top.

**Done outside the codebase (by the user):**
- Green border around the screen on RFID scan suppressed via a flag in `styles.xml`. Not committed here — the Android styles change lives in the manifest layer.

**Testing the power-loss flow without physically unplugging:**
```sh
adb shell dumpsys battery unplug          # simulate "ignition off" → overlay should appear
adb shell dumpsys battery set ac 1        # simulate "ignition on" → overlay should disappear
adb shell dumpsys battery reset           # restore real behaviour
```

**Deferred to FOLLOW_UP_QUESTIONS.md:** depth of "sleep mode" (do we need to physically turn the screen off?), battery-vs-ignition distinction, behaviour on cold-boot `unknown` state, whether to also port the parent's `PowerReceiver.kt` / `WakeForegroundService.kt`.

### Chunk 2 — Prestart functionality + welcome placeholder + named-route navigation

**Added:**
- `lib/features/prestart/` — full feature folder (data, domain, presentation + widgets) ported from `vis_tac_app/lib/blocs/prestart_manager.dart`, `screens/prestart_check/`, `widgets/prestart_widgets.dart`. Stripped of all parent-app glue: no camera icons, no HMI bloc back-button, no state-machine references, no MQTT publish, no time-logger.
- `lib/features/welcome/presentation/welcome_screen.dart` — minimal terminal screen showing username + live clock + manual logout button. Chunk 3 will replace the manual logout with the power-loss timer.
- `lib/core/routing/app_routes.dart` — named-route constants (`/`, `/prestart`, `/welcome`).
- `assets/prestart_questions.json` — copied from the parent app, declared in `pubspec.yaml`. Seeds the `prestart_questions` table on first install.
- SQLite tables: `prestart_meta`, `prestart_questions`, `prestart_submissions`. DB version bumped to v4 with drop-and-recreate.
- `PrestartRepository` abstract interface + `SqlitePrestartRepository` implementation (audit log writes per-question detail as a JSON blob to keep the schema simple).
- `App` now accepts both repositories; `main.dart` constructs both.
- `LoginScreen` listens for `LoginStatus.success` and navigates to `/prestart` after a 1.5 s delay (long enough to show "Card Authorised — Welcome, X").
- `LoginController._setResult` no longer auto-resets on success — success is terminal until the screen navigates. Failure still auto-resets after 3 s.
- Prestart submit flow: tap FAB → completion dialog (with issues + missing-required summaries) → on Finish, repository persists the submission and screen navigates to `/welcome`. Logout button on prestart returns to `/login`.

**Deferred to FOLLOW_UP_QUESTIONS.md:** audit-log retention/access, runtime question updates, "all answered" vs. "all correct" threshold, back-button-discards-progress UX.

### Chunk 1.5 — USB-CDC support + Flipper-friendly keyboard fallback

Discovery: PCB inspector at `c:\src\rfid_pcb_inspector` revealed the PCB is an RP2040 (VID `0x2E8A`, PID `0x0005`) running MicroPython, emitting `{"CardNo": <int>}\r\n` over USB-CDC. **Not** an HID keyboard.

**Added:**
- `usb_serial: ^0.5.1` dependency.
- `<uses-feature android:name="android.hardware.usb.host" />` to AndroidManifest.
- `lib/core/config.dart` — VID + baud constants.
- `lib/features/auth/presentation/serial_card_reader.dart` — auto-connecting USB-CDC reader; parses NDJSON, extracts `CardNo`.
- `FOLLOW_UP_QUESTIONS.md` — running list of decisions to revisit after chunks 1–4.

**Changed:**
- `cards` schema: `card_id TEXT PRIMARY KEY, card_name, card_number, employee_number` → `card_no INTEGER PRIMARY KEY, name TEXT`. Schema bumped to v2 with a drop-and-recreate `onUpgrade` so existing dev installs migrate cleanly.
- `AuthRepository.lookupCard(String cardId)` → `lookupCard(int cardNo)`.
- `AuthenticatedUser` reduced to `{cardNo: int, name: String}` (per-confirmation: minimum fields).
- `LoginController.submitCard(String)` → `submitCard(int)`, plus an idle-state guard to dedupe parallel submissions from the two readers.
- `KeyboardCardReader` — generalised: accepts decimal **and** hex input, fires on Enter or 500 ms idle, parses both bases, drops short or unparseable input. Hooked via callback instead of per-call closure.
- `LoginScreen` — instantiates both readers in parallel; KeyboardListener drives the keyboard reader, the serial reader auto-connects in the background.

**Deferred to FOLLOW_UP_QUESTIONS.md:** PCB disconnect during prestart/welcome; connection-visibility UI; card-identifier shape with the integrating team; firmware output format expansion.

### Chunk 1 — MQTT removal + feature-folder restructure + SQLite auth

**Removed:**
- All MQTT machinery: `mqtt_manager.dart`, `mqtt/mqtt_bloc.dart`, `mqtt/mqtt_event.dart`, `mqtt/mqtt_state.dart`, `kotlin_mqtt_bridge.dart`, `mqtt_topics.dart`, `config.dart` (broker IP).
- Native Kotlin: `MqttPahoPlugin.kt`. `MainActivity.kt` reverted to bare `class MainActivity : FlutterActivity()`.
- Gradle: Eclipse Paho + kotlinx-coroutines deps removed from `app/build.gradle.kts`.
- Manifest: `INTERNET`, `ACCESS_NETWORK_STATE`, `usesCleartextTraffic` removed.
- Packages: `flutter_bloc`, `bloc` dropped from `pubspec.yaml`.
- The old `services/rfid_service.dart`, `blocs/rfid_manager.dart`, `services/user_session_service.dart`, `screens/rfid_screen.dart`, `themes/`, `utils/`, `constants/` directories — all replaced by the new feature-folder layout.

**Added:**
- Feature-folder structure under `lib/core/` and `lib/features/auth/`.
- `sqflite`, `path`, `provider` packages.
- SQLite dummy DB with a `cards` table and a seeded test card.
- `AuthRepository` abstract interface + `SqliteAuthRepository` implementation.
- `Session` ChangeNotifier holding the current authenticated user.
- `LoginController` (replaces `RFIDService`) — calls `AuthRepository.lookupCard` instead of publishing/subscribing to MQTT.
- `LoginScreen` (replaces `RFIDScannerScreen`) — same look as before, no MQTT readiness check, no camera/ignition/state-machine glue.

### Phase 0 — Initial extraction (historical)

The first pass copied the RFID functionality verbatim from `vis_tac_app`, including all the MQTT plumbing it depended on (Dart bloc + manager + bridge + Kotlin Paho plugin) and a stripped-down `RFIDScannerScreen`. As of chunks 1 and 1.5, all of that has been replaced.

Files we **deliberately did not** copy from the parent app and never will (still accurate):

| File / system | Why we don't need it |
| --- | --- |
| `lib/blocs/camera_manager.dart`, `lib/widgets/camera_connection_dialog.dart` | No cameras in this app. |
| `lib/services/state_machine.dart` | The new app uses simple navigation between feature screens. |
| `lib/services/time_loggger_service.dart` | No prestart 12-hour-window logic (that was Pi-time-driven via MQTT). |
| `lib/services/ignition_power_service.dart` | Will be addressed in chunk 3 (10 s power-loss → sleep). The parent's implementation was MQTT-driven; we'll need a different approach. |
| `lib/utils/ethernet_connection_manager.dart` | No camera RTSP, no need for forced Ethernet binding. |
| `WakeForegroundService.kt`, `PowerReceiver.kt` (Kotlin) | Will be reconsidered in chunk 3 when implementing the power-loss timer. |
| `mqtt_client` Dart package | Never used (parent used the Kotlin plugin); now also moot since no MQTT. |

---

## Roadmap

| #   | Chunk | Status |
| --- | ----- | ------ |
| 1   | Strip MQTT, restructure to feature folders, add SQLite-backed `AuthRepository` | ✅ Done |
| 1.5 | USB-CDC support (auto-connect to PCB by VID), parallel keyboard fallback, schema reshaped around `card_no INTEGER` | ✅ Done |
| 2   | Port prestart functionality. Define `PrestartRepository` interface; questions & submitted answers stored in SQLite (audit log). Welcome screen placeholder + named-route flow. | ✅ Done |
| 3   | Power-loss detection + 10 s logout-and-sleep + no-power screen. (Green-border tweak handled in `styles.xml` outside this repo.) | ✅ Done |
| 4   | Project rename (e.g. `vehicle_login_app`). Decide final treatment of audit-log table. Final review of redundant Kotlin packages. | Next |

For decisions deferred until after chunk 4, see [FOLLOW_UP_QUESTIONS.md](FOLLOW_UP_QUESTIONS.md).

---

## Open questions / future decisions

- **Real test card seeded:** [`seed_data.dart`](lib/core/db/seed_data.dart) now has the actual scanned card `11913`. Add more cards as you onboard them.
- **Hardware reader type:** **RESOLVED** — USB-CDC at 115200 8N1, NDJSON payload `{"CardNo": <int>}\r\n`. Confirmed via the PCB inspector. The keyboard path is kept active anyway for Flipper Zero / dev keyboards.
- **Audit log lifecycle, PCB disconnect handling, card-id shape, firmware extensibility** — see [FOLLOW_UP_QUESTIONS.md](FOLLOW_UP_QUESTIONS.md).

---

**Meeting notes:**

## Things to add:
- add prestart functionality (check how questions are checked)
- tablet talks to external database (generic dummy db) (SQL-Lite)

## Tablet environment
- tablet connected to site Wifi

## Kotlin/ Android considerations
- Review Kotlin code so that tablet turns on as soon as power (remove redundant packages)
- no green border when rfid scans card
- 10 sec timer to logout (low power mode)

## Redundant parts
- No Mqtt (Tablet doesn't send stuff)

## UI stuff
- main screen with user name + time (dummy screen after pre-start)
- no power (dummy screen) > rfid > prestart > main screen 

## Potential Hardware set-up
- Customs PCB (from Tomago) conatin micropython chip and rfid chip (need to figure out whther rfid is UART or keyboard)

## Additonal project context
- NOTE DONT IMPLEMENT THIS: some vehicle have no rfid or prestart so may go straight to taxi rank app (later bridge)
- wiring: RFID + relay that controls ignition (don't worry now)
- Customs PCB (from Tomago) conatin micropython chip and rfid chip (need to figure out whther rfid is UART or keyboard)
