#!/usr/bin/env bash
# Stage everything workload-vm needs, on a machine that HAS internet access.
# workload-vm itself has no egress, so this folder is later copied in through the jumpbox with scp.
#
# Target: Ubuntu 22.04 LTS image -> CPython 3.10, glibc 2.35, x86_64.
# pip does not expand a manylinux tag to older glibc versions, so every tag the wheels use is listed.
# Output: ./ai_package/  (17 wheels, 46 MB + the GGUF model, 407 MB)
set -euo pipefail

cd "$(dirname "$0")/.."
OUT="ai_package"
MODEL="qwen1_5-0_5b-chat-q4_k_m.gguf"
MODEL_URL="https://huggingface.co/Qwen/Qwen1.5-0.5B-Chat-GGUF/resolve/main/${MODEL}"
MODEL_SHA256="92916b71d32f5afea48fb7383e3b48c5b1c111f5a59f0b83c764ea1d07fe1a3a"

PY="$(command -v python3 || command -v python)"
mkdir -p "$OUT"

echo "[1/2] Python wheels (pinned + hash-checked, built for the VM, not for this machine)"
"$PY" -m pip download \
  --dest "$OUT" \
  --only-binary=:all: \
  --platform manylinux_2_34_x86_64 \
  --platform manylinux_2_28_x86_64 \
  --platform manylinux_2_17_x86_64 \
  --platform manylinux2014_x86_64 \
  --python-version 3.10 \
  --implementation cp \
  --abi cp310 \
  --require-hashes \
  --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cpu \
  -r src/offline-requirements.txt

echo "[2/2] Model: ${MODEL} (407 MB)"
if [ ! -f "$OUT/$MODEL" ]; then
  curl -fL --retry 3 -o "$OUT/$MODEL.part" "$MODEL_URL"
  mv "$OUT/$MODEL.part" "$OUT/$MODEL"
fi
echo "${MODEL_SHA256}  ${OUT}/${MODEL}" | sha256sum -c -

echo "Done. Copy ${OUT}/ and src/audit_processor.py to workload-vm (see README, step 3)."
