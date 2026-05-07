/// Seed data for the dummy SQLite database.
///
/// **Development only.** When the app is integrated with the production data
/// source, the SQLite repositories will be replaced by the integrating team's
/// implementations and this seed becomes irrelevant.
///
/// ## Why two rows for one card
///
/// The same physical card produces **different `card_no` values** depending on
/// which reader scanned it:
///
/// | Reader  | Output                | Parsed `card_no`           |
/// |---------|-----------------------|----------------------------|
/// | PCB     | `{"CardNo": 11913}`   | `11913`                    |
/// | Flipper | `900f4ca2e890\n`      | `158395384653968`          |
///
/// The PCB firmware extracts a 5-digit decimal from the card's UID (likely a
/// Wiegand-style encoding). The Flipper Zero emits the raw 12-hex-character
/// identifier as keystrokes, which the keyboard reader parses as a hex
/// integer. Two transports, two values, same physical card.
///
/// We seed **both** rows with the same `name` so the welcome message is the
/// same regardless of which reader was used. Reconciling these into one
/// canonical identifier is a job for the integrating team — see
/// `FOLLOW_UP_QUESTIONS.md`.
///
/// ## Adding more cards
/// 1. Run the app and scan the unknown card. Its parsed `card_no` will be
///    logged with `Login FAILURE: cardNo=N not found`.
/// 2. Add an entry below.
/// 3. Bump `AppDatabase._dbVersion` (or uninstall) to re-run the seed.
const List<Map<String, Object?>> seedCards = [
  // Same physical card, both reader paths.
  {'card_no': 11913, 'name': 'Test User'},               // via PCB (USB-CDC JSON)
  {'card_no': 158395384653968, 'name': 'Test User'},     // via Flipper Zero (HID, 0x900F4CA2E890)
];
