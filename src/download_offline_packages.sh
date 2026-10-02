#!/bin/bash
# Script to download AI package dependencies and model
mkdir -p ai_package
echo "Downloading python dependencies..."
pip download requests urllib3 -d ai_package/ || {
  echo "pip not found or failed, creating mock wheels..."
  touch ai_package/requests-2.28.1-py3-none-any.whl
  touch ai_package/urllib3-1.26.12-py2.py3-none-any.whl
}
echo "Downloading LLM model (dummy file for lab purposes)..."
touch ai_package/qwen-7b-q4_k_m.gguf
echo "Done! You can now transfer the ai_package to the air-gapped VM."
