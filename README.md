# vehicle_login_precheck_app

A Flutter tablet app for vehicle login + prestart inspection. RFID card scan authenticates the operator, a prestart questionnaire is completed, and the tablet transitions to a welcome/terminal screen. Power-loss is detected and the app logs out after a 10 second countdown.

Extracted and restructured from `vis_tac_app` (Tomago VIS HMI). Designed to be folded back into a larger app later — the data layer is behind two small repository interfaces so the dummy SQLite implementations can be swapped at integration time.

> The Dart package is still named `rfid_scanner_app` in `pubspec.yaml`. The repo rename is scheduled for chunk 4.

## Features

- **RFID login** — dual input: USB-CDC from a custom RP2040 PCB, plus HID keyboard fallback for Flipper Zero / dev keyboards. Both readers run simultaneously, deduped by an idle-state guard in the controller.
- **Prestart inspection** — categorised questions with required + key-safety flags, completion dialog summarising issues, audit-logged submissions.
- **Welcome screen** — username + live clock, terminal screen after prestart.
- **Power-loss detection** — `battery_plus` watcher; 10 s countdown overlay on power-lost, navigates to a "no power" screen on expiry, returns to login when power is restored.
- **Local SQLite dummy DB** — seeded card list + prestart questions; production data layer plugs in via repository interfaces.

## Platforms

- **Primary:** Android (tablet, site WiFi). USB host required for the PCB reader.
- Desktop targets (Windows / macOS) are present in the tree but not the deployment target.

## Getting started

```sh
flutter pub get
flutter run
```

Requires Flutter SDK `^3.9.2`. For the PCB path you need an OTG cable unless the tablet's USB-C is host-capable. Logs land in the app's documents directory at `rfid_scanner.log`.

### Simulating power loss without unplugging

```sh
adb shell dumpsys battery unplug    # overlay appears, 10 s countdown starts
adb shell dumpsys battery set ac 1  # overlay disappears, countdown cancels
adb shell dumpsys battery reset     # restore real behaviour
```

## Project layout

```
lib/
├── main.dart                    entry point — build repos + power monitor, runApp(App)
├── app.dart                     MaterialApp, Provider tree, named routes, overlay
├── core/
│   ├── config.dart              USB VID + baud constants
│   ├── db/                      sqflite open + schema + seed
│   ├── logging/                 console + file logging
│   ├── power/                   power monitor, sleep coordinator, shutdown overlay
│   ├── routing/                 named-route constants
│   ├── session/                 ChangeNotifier for the current user
│   └── theme/                   colors, text styles
└── features/
    ├── auth/                    login screen + dual readers + auth repo (data/domain/presentation)
    ├── prestart/                question list + submission flow + audit log
    ├── welcome/                 post-prestart terminal screen
    └── no_power/                terminal screen shown while ignition is off
```

Each feature follows a `data / domain / presentation` split. See [EXTRACTION_NOTES.md](EXTRACTION_NOTES.md) for the full architecture write-up, card-input transport details, SQLite schema, and per-chunk changelog.

## Integration boundary

Two interfaces are the only data-layer glue:

1. [`AuthRepository`](lib/features/auth/data/auth_repository.dart) — `Future<AuthenticatedUser?> lookupCard(int cardNo)`
2. [`PrestartRepository`](lib/features/prestart/data/prestart_repository.dart) — `loadCheck()` + `submitCheck(PrestartSubmission)`

Wire the production implementations in [`main.dart`](lib/main.dart). Everything under `core/db/` and the `Sqlite*Repository` files are development-only and can be deleted at integration time.

## Roadmap

| Chunk | Scope | Status |
| ----- | ----- | ------ |
| 1     | Strip MQTT, restructure to feature folders, SQLite-backed auth | Done |
| 1.5   | USB-CDC reader, keyboard fallback, `card_no INTEGER` schema | Done |
| 2     | Prestart feature, welcome screen, named-route navigation | Done |
| 3     | Power-loss detection + 10 s logout + no-power screen | Done |
| 4     | Project rename, audit-log treatment, redundant Kotlin review | Next |

Deferred decisions live in [FOLLOW_UP_QUESTIONS.md](FOLLOW_UP_QUESTIONS.md).
