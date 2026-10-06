#!/bin/zsh
# install-bro-27b.zsh — Download and install B.R.O v17 27B to external disk
# Target: /Volumes/My Mac 2TB/models/bro-27b-v17
# Source: GitHub Releases timamar187-creator/BRO-abliterated-27B v1.0.0
#
# NOTE: GLM-5.3 is a 753B MoE model — there is no official 27B dense variant.
# This script downloads the v17 LoRA adapter (15GB) and pre-built GGUF
# abliterated LoRA adapters for local inference.

set -euo pipefail

EXTERNAL_DISK="/Volumes/My Mac 2TB"
TARGET_DIR="$EXTERNAL_DISK/models/bro-27b-v17"
GGUF_DIR="$EXTERNAL_DISK/models"
RELEASE_BASE="https://github.com/timamar187-creator/BRO-abliterated-27B/releases/download/v1.0.0"

# --- Pre-flight ---
if [[ ! -d "$EXTERNAL_DISK" ]]; then
    echo "ERROR: External disk not mounted at $EXTERNAL_DISK" >&2
    exit 1
fi

FREE_GB=$(df -g "$EXTERNAL_DISK" | tail -1 | awk '{print $4}')
if [[ "$FREE_GB" -lt 20 ]]; then
    echo "ERROR: Insufficient space. Need ~20GB, have ${FREE_GB}GB" >&2
    exit 1
fi

echo "=== B.R.O v17 27B Installer ==="
echo "Target: $TARGET_DIR"
echo "GGUF: $GGUF_DIR"
echo "Free space: ${FREE_GB}GB"
echo ""

mkdir -p "$TARGET_DIR" "$GGUF_DIR"

# --- Step 1: Download v17 LoRA adapter from GitHub Release ---
if [[ ! -f "$TARGET_DIR/adapter_model.safetensors" ]]; then
    echo "[1/4] Downloading v17 LoRA adapter from GitHub Release..."
    ARCHIVE="$TARGET_DIR/v17-checkpoint.tar.gz"
    curl -L --progress-bar -o "$ARCHIVE" \
        "$RELEASE_BASE/v17-checkpoint.tar.gz"
    tar -xzf "$ARCHIVE" -C "$TARGET_DIR"
    rm "$ARCHIVE"
else
    echo "[1/4] LoRA adapter already present, skipping download"
fi

echo "  Adapter installed: $(du -h "$TARGET_DIR/adapter_model.safetensors" | awk '{print $1}')"

# --- Step 2: Download GGUF adapters from GitHub Release ---
echo "[2/4] Downloading GGUF abliterated LoRA adapters from GitHub Release..."
if [[ ! -f "$GGUF_DIR/GLM-5.3-Flash-Ablitered-LoRA-v1.gguf" ]]; then
    curl -L --progress-bar -o "$GGUF_DIR/GLM-5.3-Flash-Ablitered-LoRA-v1.gguf" \
        "$RELEASE_BASE/GLM-5.3-Flash-Ablitered-LoRA-v1.gguf"
else
    echo "  v1 GGUF already present, skipping"
fi

if [[ ! -f "$GGUF_DIR/GLM-5.3-Flash-Ablitered2-LoRA-v2.gguf" ]]; then
    curl -L --progress-bar -o "$GGUF_DIR/GLM-5.3-Flash-Ablitered2-LoRA-v2.gguf" \
        "$RELEASE_BASE/GLM-5.3-Flash-Ablitered2-LoRA-v2.gguf"
else
    echo "  v2 GGUF already present, skipping"
fi

# --- Step 3: Verify ---
echo "[3/4] Verifying installation..."
VERIFIED=true

if [[ -f "$TARGET_DIR/adapter_model.safetensors" ]]; then
    ADAPTER_SIZE=$(du -h "$TARGET_DIR/adapter_model.safetensors" | awk '{print $1}')
    echo "  v17 LoRA adapter: $ADAPTER_SIZE"
else
    echo "  ERROR: v17 LoRA adapter missing"
    VERIFIED=false
fi

if [[ -f "$GGUF_DIR/GLM-5.3-Flash-Ablitered-LoRA-v1.gguf" ]]; then
    V1_SIZE=$(du -h "$GGUF_DIR/GLM-5.3-Flash-Ablitered-LoRA-v1.gguf" | awk '{print $1}')
    echo "  GGUF v1: $V1_SIZE"
else
    echo "  ERROR: GGUF v1 missing"
    VERIFIED=false
fi

if [[ -f "$GGUF_DIR/GLM-5.3-Flash-Ablitered2-LoRA-v2.gguf" ]]; then
    V2_SIZE=$(du -h "$GGUF_DIR/GLM-5.3-Flash-Ablitered2-LoRA-v2.gguf" | awk '{print $1}')
    echo "  GGUF v2: $V2_SIZE"
else
    echo "  ERROR: GGUF v2 missing"
    VERIFIED=false
fi

# --- Step 4: Summary ---
echo "[4/4] Installation summary"
if [[ "$VERIFIED" == "true" ]]; then
    echo ""
    echo "=== Installation Complete ==="
    echo "Files installed to: $EXTERNAL_DISK/models/"
    ls -lh "$GGUF_DIR"/*.gguf 2>/dev/null || true
    ls -lh "$TARGET_DIR"/ 2>/dev/null || true
    echo ""
    echo "To run with llama.cpp:"
    echo "  llama-server -m $GGUF_DIR/GLM-5.3-Flash-Ablitered-LoRA-v1.gguf --port 8080"
    echo ""
    echo "To run with ollama:"
    echo "  ollama create bro-v17 -f $GGUF_DIR/Modelfile"
    echo ""
    echo "NOTE: The v17 LoRA adapter requires a GLM-5.3 base model (753B MoE)."
    echo "      For local use, the pre-built GGUF adapters above are recommended."
else
    echo "ERROR: Installation incomplete" >&2
    exit 1
fi
