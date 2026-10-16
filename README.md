# SME Financial Copilot

A Khmer-first mobile money ledger for Cambodian small businesses and farmers.
It records income and expenses in KHR and USD, keeping the two currencies separate.

## Current scope: core ledger

- Record income, expenses, and owner contributions and withdrawals. Owner contributions and withdrawals change cash but are not counted in profit.
- KHR and USD amounts are stored as integers and are never added together.
- Ledger with search, filters and day subtotals.
- Edit and void entries, with a full revision history. Nothing is hard-deleted.
- Duplicate warning before saving.
- Home summary for this month: money in, money out and cash profit, per currency.
- Khmer (default) and English interface.
- Works fully offline, with a local SQLite database (drift).

## Setup

```bash
flutter pub get
dart run build_runner build   # generates lib/data/database.g.dart
flutter test
flutter run
```

iOS (demo only): run `xcodebuild -downloadPlatform iOS` once to install a simulator.
To run on a real iPhone, open `ios/Runner.xcworkspace` and choose a Personal Team under Signing.

## Layout

```
lib/
  core/          money (integer minor units, parsing, formatting), dates
  domain/        enums, entry drafts and validation
  finance_core/  deterministic calculations — the single source of totals
  data/          drift database, default categories, ledger repository
  features/      home, ledger, entry form, settings
  l10n/          app_km.arb / app_en.arb
```
