"""Speech-to-text service for SME Copilot.

Khmer: 1morecupofhottea/whisper-turbo-khmer-v9 (CTranslate2 int8).
English: OpenAI Whisper small.en via faster-whisper (the Khmer fine-tune has
lost its English and writes English sounds in Khmer script).

    POST /transcribe   body: WAV/FLAC/OGG audio (raw bytes or multipart "file")
                       header: Authorization: Bearer <WHISPER_TOKEN> (if set)
                       query: ?lang=en for English (default km)
                              ?live=1 for a fast, rougher preview
    -> {"text": "...", "raw": "...", "seconds": 1.23}

    POST /ocr          body: PNG/JPEG image (raw bytes or multipart "file")
                       same Authorization header
    -> {"text": "...", "seconds": 0.2}
                       Tesseract with the Khmer + English models (khm+eng).

Live previews encode a window just longer than the audio instead of the
full 30 s, which is about 3x faster but can add a stray syllable at the end.
The app shows them while the user talks, then replaces them with a full pass.

The model uses a custom tokenizer whose Khmer tokens have ids above
<|endoftext|>, so faster-whisper's decoder would drop them. We call
CTranslate2 directly and decode with the model's own tokenizer instead.
"""

import io
import math
import os
import re
import subprocess
import tempfile
import time

import ctranslate2
import numpy as np
import soundfile as sf
from fastapi import FastAPI, HTTPException, Request
from faster_whisper import WhisperModel
from faster_whisper.feature_extractor import FeatureExtractor
from scipy.signal import resample_poly
from tokenizers import Tokenizer

MODEL_DIR = os.environ.get("MODEL_DIR", "/models/whisper-turbo-khmer-v9-ct2")
EN_MODEL = os.environ.get("EN_MODEL", "small.en")
EN_MODEL_DIR = os.environ.get("EN_MODEL_DIR")  # download cache; None = HF default
TOKEN = os.environ.get("WHISPER_TOKEN", "")
THREADS = int(os.environ.get("WHISPER_THREADS", str(os.cpu_count() or 2)))
MAX_SECONDS = 90
SAMPLE_RATE = 16000
CHUNK = 30 * SAMPLE_RATE

tokenizer = Tokenizer.from_file(os.path.join(MODEL_DIR, "tokenizer.json"))
features = FeatureExtractor(feature_size=128)
model = ctranslate2.models.Whisper(
    MODEL_DIR, device="cpu", compute_type="int8", intra_threads=THREADS
)
PROMPT = [
    tokenizer.token_to_id(t)
    for t in ("<|startoftranscript|>", "<|km|>", "<|transcribe|>", "<|notimestamps|>")
]
SPECIAL = {
    i for t, i in tokenizer.get_vocab().items() if t.startswith("<|") and t.endswith("|>")
}

english = WhisperModel(
    EN_MODEL, device="cpu", compute_type="int8", cpu_threads=THREADS,
    download_root=EN_MODEL_DIR,
)
# Spellings the English model otherwise gets wrong (e.g. riel -> "real").
EN_HINT = "Riel, KHR, dollars, USD, ABA, Wing, KHQR."

app = FastAPI(title="Khmer Whisper")
OCR_LANGS = os.environ.get("OCR_LANGS", "khm+eng")


def load_audio(data: bytes) -> np.ndarray:
    try:
        audio, rate = sf.read(io.BytesIO(data), dtype="float32", always_2d=True)
    except Exception as e:
        raise HTTPException(415, f"Unsupported audio: {e}") from e
    audio = audio.mean(axis=1)
    if rate != SAMPLE_RATE:
        g = np.gcd(rate, SAMPLE_RATE)
        audio = resample_poly(audio, SAMPLE_RATE // g, rate // g).astype(np.float32)
    if len(audio) > MAX_SECONDS * SAMPLE_RATE:
        raise HTTPException(413, f"Audio longer than {MAX_SECONDS}s")
    return audio


def transcribe_chunk(chunk: np.ndarray, live: bool = False) -> str:
    # Live: the audio plus 2 s of silence, at least 8 s. Full: always 30 s.
    seconds = min(30, max(8, math.ceil(len(chunk) / SAMPLE_RATE) + 2)) if live else 30
    padded = np.zeros(seconds * SAMPLE_RATE, dtype=np.float32)
    padded[: len(chunk)] = chunk
    mel = features(padded, padding=0)[:, : seconds * 100][None].astype(np.float32)
    result = model.generate(
        ctranslate2.StorageView.from_array(mel),
        [PROMPT],
        beam_size=1,
        max_length=448,
        # Short windows tend to repeat the last words.
        no_repeat_ngram_size=4 if live else 0,
    )
    ids = [i for i in result[0].sequences_ids[0] if i not in SPECIAL]
    return tokenizer.decode(ids)


def transcribe_english(audio: np.ndarray, live: bool) -> str:
    segments, _ = english.transcribe(
        audio,
        language="en",
        beam_size=1 if live else 5,
        without_timestamps=True,
        condition_on_previous_text=False,
        initial_prompt=EN_HINT,
    )
    return "".join(s.text for s in segments).strip()


def clean(raw: str) -> str:
    """Drops the model's khmercut ';' group separators and extra spaces."""
    return re.sub(r"\s+", " ", raw.replace(";", " ")).strip()


@app.get("/")
def health():
    return {
        "ok": True,
        "models": {
            "km": "1morecupofhottea/whisper-turbo-khmer-v9 (ct2 int8)",
            "en": f"openai/whisper-{EN_MODEL} (faster-whisper int8)",
            "ocr": f"tesseract {OCR_LANGS}",
        },
    }


async def read_upload(request: Request) -> bytes:
    if TOKEN and request.headers.get("authorization") != f"Bearer {TOKEN}":
        raise HTTPException(401, "Unauthorized")

    if request.headers.get("content-type", "").startswith("multipart/form-data"):
        form = await request.form()
        upload = form.get("file")
        if upload is None:
            raise HTTPException(400, "Missing 'file' field")
        data = await upload.read()
    else:
        data = await request.body()
    if not data:
        raise HTTPException(400, "Empty body")
    return data


@app.post("/ocr")
async def ocr(request: Request):
    data = await read_upload(request)
    started = time.time()
    with tempfile.NamedTemporaryFile(suffix=".img") as image:
        image.write(data)
        image.flush()
        # --psm 6: one uniform block of text, which suits receipts.
        result = subprocess.run(
            ["tesseract", image.name, "-", "-l", OCR_LANGS, "--psm", "6"],
            capture_output=True, timeout=60,
        )
    if result.returncode != 0:
        raise HTTPException(400, result.stderr.decode(errors="replace")[-300:])
    lines = (line.strip() for line in result.stdout.decode().splitlines())
    text = "\n".join(line for line in lines if line)
    return {"text": text, "seconds": round(time.time() - started, 2)}


@app.post("/transcribe")
async def transcribe(request: Request):
    data = await read_upload(request)

    live = request.query_params.get("live") == "1"
    lang = request.query_params.get("lang", "km")
    if lang not in ("km", "en"):
        raise HTTPException(400, "lang must be km or en")
    started = time.time()
    audio = load_audio(data)
    if lang == "en":
        raw = transcribe_english(audio, live)
    else:
        raw = " ; ".join(
            transcribe_chunk(audio[i : i + CHUNK], live=live)
            for i in range(0, max(len(audio), 1), CHUNK)
        )
    return {"text": clean(raw), "raw": raw, "seconds": round(time.time() - started, 2)}
