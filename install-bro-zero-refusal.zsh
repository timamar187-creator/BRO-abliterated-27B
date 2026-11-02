#!/usr/bin/env zsh
# B.R.O — Zero Refusal (v3.0 MoE Edition: Qwen3.5-35B-A3B, 35B Total / 3B Active)
# Distilled from B.R.O v53 (Tinker) — F32 MoE Router Abliteration + LoRA SFT + Intent-Locking
set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

BASE_MOE="https://github.com/timamar187-creator/BRO-abliterated-27B/releases/download/v3.0.0"
HF_BASE="https://huggingface.co/Sm0k13/B.R.O-abliterated-27B/resolve/main"
GGUF_NAME="B.R.O-Zero-Refusal-35B-A3B-MoE-Q4_K_M.gguf"
EXPECTED_GGUF_SHA256="628a481a1961e343cc3da000e3b4c3fc88f232bf45c4e3c8bf25c3fd1f0eb494"
CACHE_DIR="${BRO_CACHE_DIR:-$HOME/.cache/bro-zero-refusal-v3}"

echo "${CYAN}================================================================${NC}"
echo "${CYAN}  B.R.O — Zero Refusal (v3.0 MoE: Qwen3.5-35B-A3B | 3B Active) ${NC}"
echo "${CYAN}  Distilled from B.R.O v53 (Tinker) | 0.0% Refusal | ~23 tok/s ${NC}"
echo "${CYAN}================================================================${NC}"

if ! command -v ollama >/dev/null 2>&1; then
  echo "${YELLOW}[1/4] Installing Ollama...${NC}"
  if [[ "$(uname)" == "Darwin" ]]; then
    if command -v brew >/dev/null 2>&1; then
      brew install --cask ollama || brew install ollama
    else
      curl -fsSL https://ollama.com/install.sh | sh
    fi
  else
    curl -fsSL https://ollama.com/install.sh | sh
  fi
else
  echo "${GREEN}[1/4] Ollama detected.${NC}"
fi

if ! curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1 && ! curl -fsS http://127.0.0.1:11433/api/tags >/dev/null 2>&1; then
  echo "${YELLOW}Starting Ollama daemon...${NC}"
  nohup ollama serve >/tmp/ollama-bro-zero-refusal.log 2>&1 &
  sleep 3
fi

mkdir -p "$CACHE_DIR"
cd "$CACHE_DIR"

echo "${YELLOW}[2/4] Fetching B.R.O Zero Refusal v3.0 distilled weights & artifacts...${NC}"
curl -fsSL "$BASE_MOE/Modelfile" -o "$CACHE_DIR/Modelfile" || curl -fsSL "$HF_BASE/Modelfile" -o "$CACHE_DIR/Modelfile"
curl -fsSL "$BASE_MOE/adapter_config.json" -o "$CACHE_DIR/adapter_config.json" || true
curl -fsSL "$BASE_MOE/adapters.safetensors" -o "$CACHE_DIR/adapters.safetensors" || true
curl -fsSL "$BASE_MOE/bro_v53_moe_router_distill.safetensors" -o "$CACHE_DIR/bro_v53_moe_router_distill.safetensors" || true

if [[ -f "$CACHE_DIR/$GGUF_NAME" ]]; then
  echo "${GREEN}Found cached $GGUF_NAME in $CACHE_DIR.${NC}"
else
  echo "${YELLOW}Downloading split GGUF shards from $BASE_MOE...${NC}"
  curl -fsSL "$BASE_MOE/bro-zero-refusal-35b-a3b-q4km.parts.sha256" -o "$CACHE_DIR/bro-zero-refusal-35b-a3b-q4km.parts.sha256"
  PARTS=($(awk '{print $2}' "$CACHE_DIR/bro-zero-refusal-35b-a3b-q4km.parts.sha256"))
  for part in "${PARTS[@]}"; do
    echo "${CYAN}  -> Downloading $part ...${NC}"
    curl -fL --retry 3 -C - "$BASE_MOE/$part" -o "$CACHE_DIR/$part"
  done
  echo "${YELLOW}Verifying shard SHA-256 checksums...${NC}"
  shasum -a 256 -c "$CACHE_DIR/bro-zero-refusal-35b-a3b-q4km.parts.sha256"
  echo "${YELLOW}Reassembling $GGUF_NAME...${NC}"
  cat "${PARTS[@]}" > "$CACHE_DIR/$GGUF_NAME"
  rm -f "${PARTS[@]}"
fi

ACTUAL_SHA="$(shasum -a 256 "$CACHE_DIR/$GGUF_NAME" | awk '{print $1}')"
if [[ "$ACTUAL_SHA" != "$EXPECTED_GGUF_SHA256" ]]; then
  echo "SHA-256 mismatch for $GGUF_NAME: expected $EXPECTED_GGUF_SHA256, got $ACTUAL_SHA" >&2
  exit 1
fi

echo "${YELLOW}[3/4] Building local B.R.O Zero Refusal MoE model (bro-zero-refusal) from $GGUF_NAME...${NC}"
ollama create bro-zero-refusal -f "$CACHE_DIR/Modelfile"
ollama cp bro-zero-refusal BRO-Zero-Refusal 2>/dev/null || true

echo "${GREEN}[4/4] B.R.O — Zero Refusal (v3.0 MoE) installed! Launching...${NC}"
exec ollama run bro-zero-refusal
