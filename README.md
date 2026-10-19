# SME Financial Copilot

A Khmer-first bookkeeping app for Cambodian small businesses and farmers.
Owners record income and expenses by typing, speaking or photographing a
receipt, and see where their money goes. KHR and USD are tracked side by side
and are never mixed.

Built with Flutter and Supabase. Each account's records are stored in the
cloud, private to that account; the AI assistant is optional.

## Features

**Ledger**
- Record income, expenses, and owner contributions and withdrawals. Owner
  movements change cash but are not counted as profit.
- Search and filter by type, category, currency, date or voided status, with
  daily subtotals.
- Edit and void entries with a full revision history. Nothing is deleted.
- Duplicate warning before saving.

**Dashboard**
- Money in, money out, profit and net cash flow for the selected period,
  compared with the same elapsed days of the previous period.
- Cash on hand, from an opening balance per currency.
- Cash runway: how many days cash on hand lasts at recent spending.
- Money in vs out chart (weekly for one month, monthly for longer periods)
  and a donut of where the money went.
- Patterns from history: spending this month against the usual level
  (same days of the last 3 months), regular monthly payments and what is due
  this week, profit against owner withdrawals for the last 6 months, the best
  and worst days of the week, and income by month across years to show busy
  and lean seasons.
- Settings → Sample data loads two years of example records so every view
  has something to show.

**Export**
- Save four PDF reports, per currency, for a preset period or any dates,
  in Khmer or English: an account statement (every entry with the running
  cash balance), an income statement against the previous period, a cash
  flow report month by month, and a loan-ready financial summary with
  monthly averages, results by month, income sources and regular payments.

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

Records (entries, edit history, opening cash and assistant chats) live in
Supabase Postgres. Row-Level Security limits every table to the signed-in
user's own rows, and the edit history is written by a database trigger so it
can't be altered. Device preferences such as the language stay on the device.
The schema is in [`supabase/migrations`](supabase/migrations).

## Getting started

### Requirements

- Flutter 3.47 or later (Dart 3.13)
- Xcode for iOS and macOS, or Android Studio for Android
- A Gemini API key from [Google AI Studio](https://aistudio.google.com/) for the assistant
- Python 3.12 and Tesseract for the speech/OCR service (optional)

### Run the app

```bash
flutter pub get
cp env/dev.example.json env/dev.json
flutter run --dart-define-from-file=env/dev.json
```

`env/dev.json` is git-ignored. Its settings:

| Key | Purpose |
|---|---|
| `GEMINI_API_KEY` | Only without Supabase: calls Gemini directly |
| `WHISPER_URL` | Speech/OCR service, e.g. `http://127.0.0.1:7860` |
| `WHISPER_TOKEN` | Shared secret, if the service sets one |
| `SUPABASE_URL` | Supabase project URL, for accounts |
| `SUPABASE_PUBLISHABLE_KEY` | Supabase publishable key |

Without these, the ledger, dashboard and export still work; the assistant
shows a setup notice, and sign-in is skipped when Supabase isn't set.

### Set up Supabase

Create a project, then run
[`supabase/migrations/0001_cloud_ledger.sql`](supabase/migrations/0001_cloud_ledger.sql)
once in **SQL Editor**. For phone sign-up without SMS, turn off
**Authentication → Sign In / Providers → Email → Confirm email**.

The assistant calls Gemini through the `gemini` Edge Function, so the
Gemini key stays on the server and only signed-in users can use it:

```sh
npx supabase@2 login
npx supabase@2 secrets set --project-ref <project-ref> GEMINI_API_KEY=<key>
npx supabase@2 functions deploy gemini --project-ref <project-ref> --use-api
```

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
  data/          cloud store, row models, ledger and chat repositories
  features/      ask, ledger, dashboard, entry form, settings
  l10n/          app_km.arb and app_en.arb
supabase/
  migrations/    database schema and access rules
services/
  whisper/       speech-to-text and OCR service (FastAPI, Docker)
test/            unit tests
```
