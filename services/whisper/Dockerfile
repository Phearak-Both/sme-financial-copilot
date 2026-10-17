# Stage 1: convert the model (needs PyTorch, only at build time).
FROM python:3.12-slim AS convert
RUN pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu \
 && pip install --no-cache-dir "transformers>=4.45" "ctranslate2==4.8.3" huggingface_hub safetensors
COPY convert.py .
RUN python convert.py /models/whisper-turbo-khmer-v9-ct2

# Stage 2: small runtime image without PyTorch.
FROM python:3.12-slim
# Tesseract for receipt OCR, with the best Khmer and English models.
RUN apt-get update && apt-get install -y --no-install-recommends tesseract-ocr curl \
 && for l in khm eng; do curl -sSLf -o /usr/share/tesseract-ocr/5/tessdata/$l.traineddata \
      https://github.com/tesseract-ocr/tessdata_best/raw/main/$l.traineddata; done \
 && apt-get purge -y curl && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*
RUN useradd -m -u 1000 user
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY --from=convert /models /models
# English model (small.en, ~470 MB), fetched at build time.
RUN python -c "from faster_whisper import WhisperModel; WhisperModel('small.en', download_root='/models/en')"
ENV EN_MODEL_DIR=/models/en
COPY app.py .
USER user
EXPOSE 7860
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "7860"]
