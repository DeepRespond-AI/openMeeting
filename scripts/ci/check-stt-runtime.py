"""Run inside the CPU production image, without network or model downloads."""
import importlib
import json

import torch
import torchaudio

modules = ["faster_whisper", "funasr", "modelscope", "silero_vad", "dashscope"]
for module in modules:
    importlib.import_module(module)

assert torch.version.cuda is None, "CPU runtime unexpectedly contains CUDA Torch"
assert torch.__version__.split("+")[0] == torchaudio.__version__.split("+")[0], "Torch/torchaudio mismatch"
print(json.dumps({
    "torch": torch.__version__, "torchaudio": torchaudio.__version__,
    "cuda": torch.version.cuda, "imports": modules, "pass": True,
}))
