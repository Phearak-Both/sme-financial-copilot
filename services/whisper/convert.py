"""Downloads whisper-turbo-khmer-v9 and converts it to CTranslate2 int8.

Usage: python convert.py <output_dir>
"""

import json
import os
import sys

from ctranslate2.converters import TransformersConverter
from huggingface_hub import snapshot_download

MODEL_ID = "1morecupofhottea/whisper-turbo-khmer-v9"
# Pin the exact revision that was evaluated, so results stay reproducible.
REVISION = "f8644583afbf77707a0fc75eef36f80d116eeb1f"

out = sys.argv[1]
src = snapshot_download(MODEL_ID, revision=REVISION, allow_patterns=["*.json", "*.safetensors"])
TransformersConverter(src, copy_files=["tokenizer.json"]).convert(out, quantization="int8")

# The repo ships processor_config.json; CTranslate2 tools expect the
# feature-extractor part as preprocessor_config.json.
processor = json.load(open(os.path.join(src, "processor_config.json")))
json.dump(
    processor.get("feature_extractor", processor),
    open(os.path.join(out, "preprocessor_config.json"), "w"),
    indent=1,
)
print("converted to", out)
