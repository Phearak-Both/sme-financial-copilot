# SME Financial Copilot

A Khmer-first bookkeeping app for Cambodian small businesses and farmers.
Owners record income and expenses by typing, speaking or photographing a
receipt, and see where their money goes. KHR and USD are tracked side by side
and are never mixed.

Built with Flutter. The ledger works fully offline; the AI assistant is
optional.

## Features

**Ledger**
- Record income, expenses, and owner contributions and withdrawals. Owner
  movements change cash but are not counted as profit.
- Search and filter by type, category, currency, date or voided status, with
  daily subtotals.
- Edit and void entries with a full revision history. Nothing is deleted.
- Duplicate warning before saving.
- Export a general ledger (សៀវភៅគណនី) as PDF, per currency, for this month or
  the last 3, 6 or 12 months.

**Dashboard**
- Money in, money out, profit and net cash flow for the selected period,
  compared with the same elapsed days of the previous period.
- Cash on hand, from an opening balance per currency.
- Money in vs out chart (weekly for one month, monthly for longer periods)
  and an expense breakdown by category.

**AI assistant**
- Describe a transaction in Khmer or English, by text or voice, and get a
  draft entry to save in one tap or edit first.
- Photograph a receipt to turn it into a draft entry.
- Ask questions about your records.
- Every amount is shown for confirmation before anything is saved.

**General**
- Khmer (default) and English interface, light and dark themes.
- Amounts are stored as integer minor units, so totals are exact.

## Architecture

```
Flutter app ──────────────► Gemini API          understands text, drafts entries
     │                      (Flash-Lite, with fallbacks)
     │
     └────────────────────► Speech/OCR service  services/whisper (FastAPI, CPU)
                              POST /transcribe  Khmer: whisper-turbo-khmer-v9 (CTranslate2)
                                                English: Whisper small.en
                              POST /ocr         Tesseract 5, khm + eng
```

All records live on the device in SQLite (drift). Only the text, audio or
photo you send to the assistant leaves the device.

## Getting started

### Requirements

- Flutter 3.47 or later (Dart 3.13)
- Xcode for iOS and macOS, or Android Studio for Android
- A Gemini API key from [Google AI Studio](https://aistudio.google.com/) for the assistant
- Python 3.12 and Tesseract for the speech/OCR service (optional)

### Run the app

```bash
flutter pub get
dart run build_runner build      # generates lib/data/database.g.dart
cp env/dev.example.json env/dev.json
flutter run --dart-define-from-file=env/dev.json
```

`env/dev.json` is git-ignored. Its settings:

| Key | Purpose |
|---|---|
| `GEMINI_API_KEY` | Enables the AI assistant |
| `WHISPER_URL` | Speech/OCR service, e.g. `http://127.0.0.1:7860` |
| `WHISPER_TOKEN` | Shared secret, if the service sets one |

Without these, the ledger, dashboard and export still work; the assistant
shows a setup notice.

### Run the speech/OCR service

See [`services/whisper/README.md`](services/whisper/README.md). It runs
locally with uvicorn, or as a Docker image (for example a free Hugging Face
Space).

### Run on an iPhone

1. Open `ios/Runner.xcworkspace` in Xcode and choose your team under
   **Signing & Capabilities**.
2. Enable Developer Mode on the phone and connect it.
3. Start the service on your network with `--host 0.0.0.0` and a
   `WHISPER_TOKEN`, and point `WHISPER_URL` at your computer, e.g.
   `http://<your-mac>.local:7860`.
4. `flutter run -d <device-id> --dart-define-from-file=env/dev.json`

## Testing

```bash
flutter analyze
flutter test
```

Tests cover money handling, ledger and period calculations, the
repository, entry validation, the assistant's parsing and the PDF ledger.

## Project structure

```
lib/
  ai/            Gemini, speech and OCR clients; the copilot service
  app/           app shell, routing, theme, providers
  core/          money (integer minor units, parsing, formatting), dates
  domain/        entry types, drafts, validation, AI proposals
  finance_core/  deterministic calculations, the single source of totals
  data/          drift database, default categories, ledger repository
  features/      ask, ledger, dashboard, entry form, settings
  l10n/          app_km.arb and app_en.arb
services/
  whisper/       speech-to-text and OCR service (FastAPI, Docker)
test/            unit tests
```
