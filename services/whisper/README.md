---
title: SME Copilot Khmer Whisper
emoji: 🎙️
colorFrom: green
colorTo: yellow
sdk: docker
app_port: 7860
pinned: false
---

# Speech-to-text service

Transcribes voice notes for the SME Copilot app, on CPU:

- **Khmer:** [`1morecupofhottea/whisper-turbo-khmer-v9`](https://huggingface.co/1morecupofhottea/whisper-turbo-khmer-v9)
  (MIT), converted to CTranslate2 int8 (822 MB).
- **English** (`?lang=en`, used when the app is in English):
  OpenAI Whisper `small.en` (MIT) via faster-whisper, int8 (~470 MB). The
  Khmer fine-tune can no longer transcribe English; it writes English sounds
  in Khmer script. `small.en` took about 1 s per clip on 5 test sentences, all correct.

The app sends the transcript to Gemini as text to turn it into a draft entry.

## API

```
POST /transcribe
Authorization: Bearer <WHISPER_TOKEN>     (only if WHISPER_TOKEN is set)
Body: WAV / FLAC / OGG audio, raw bytes or multipart field "file"
Query: ?lang=en for English (default km)
       ?live=1 for a fast preview (~1.5 s instead of ~5 s on 4 threads)

200 {"text": "ទិញ ជី ប្រាំ ម៉ឺន រៀល", "raw": "ទិញ ; ជី ; ...", "seconds": 9.1}
```

`text` has the model's `;` word-group separators removed. Audio over 90 s is
rejected; longer clips are split into 30 s windows.

## Measured (2026-10-17)

| | CER (space-normalised) | Time per clip |
|---|---|---|
| FLEURS km_kh test, 40 clips, fp16 on Apple M3 GPU | 15.1% | 1.1–1.7 s |
| Same 10-clip subset, fp16 vs this int8 build | 11.9% vs 12.0% | ~10 s on 2 CPU threads |

Time is mostly fixed: Whisper always encodes a 30 s window, so a 2 s voice
note costs about the same as a 20 s one.

End to end (Whisper transcript → Gemini extraction → type, amount and
currency all correct) on 14 synthetic Khmer bookkeeping phrases, one female
voice: **11/14**. The three misses were numbers misheard by Whisper
(150 → "១០០", 600,000 → "ពុំមួយ សែន", 35 → "៣០ ផាម").

Known transcription slips on money phrases: រៀល → "រាល", ពាន់ → "ព័ន្ធ",
ដប់ → "ដ៏", and occasionally wrong digits. The app's extraction prompt
corrects these, and the user confirms every amount before saving.

## Run locally

```bash
python -m venv .venv && .venv/bin/pip install -r requirements.txt \
  torch transformers huggingface_hub safetensors
.venv/bin/python convert.py ./model
MODEL_DIR=./model .venv/bin/uvicorn app:app --port 7860
```

## Deploy as a free Hugging Face Space

Create a Space with the **Docker** SDK, push this folder to it, and optionally
set a `WHISPER_TOKEN` secret. The model is converted during the image build.
Free CPU Spaces sleep after 48 h without traffic; the first request after
that waits for start-up.
