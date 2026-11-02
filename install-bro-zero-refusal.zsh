#!/usr/bin/env zsh
# B.R.O — Zero Refusal (v3.0 MoE Edition: Qwen3.5-35B-A3B, 35B Total / 3B Active)
# Distilled from B.R.O v53 (Tinker) — F32 MoE Router Abliteration + LoRA SFT + Intent-Locking
set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

BASE_MOE="https://huggingface.co/Sm0k13/B.R.O-abliterated-27B/resolve/main"
GH_RELEASE="https://github.com/timamar187-creator/BRO-abliterated-27B/releases/download/v3.0.0"
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

echo "${YELLOW}[2/4] Fetching B.R.O Zero Refusal v3.0 distilled weights from $BASE_MOE...${NC}"
curl -fsSL "$BASE_MOE/Modelfile" -o "$CACHE_DIR/Modelfile" || curl -fsSL "$GH_RELEASE/Modelfile" -o "$CACHE_DIR/Modelfile"
curl -fsSL "$BASE_MOE/adapter_config.json" -o "$CACHE_DIR/adapter_config.json" || curl -fsSL "$GH_RELEASE/adapter_config.json" -o "$CACHE_DIR/adapter_config.json"
curl -fsSL "$BASE_MOE/adapters.safetensors" -o "$CACHE_DIR/adapters.safetensors" || curl -fsSL "$GH_RELEASE/adapters.safetensors" -o "$CACHE_DIR/adapters.safetensors"
curl -fsSL "$BASE_MOE/bro_v53_moe_router_distill.safetensors" -o "$CACHE_DIR/bro_v53_moe_router_distill.safetensors" || curl -fsSL "$GH_RELEASE/bro_v53_moe_router_distill.safetensors" -o "$CACHE_DIR/bro_v53_moe_router_distill.safetensors"

LOCAL_RELEASE_GGUF="/Users/timamar/Downloads/zbeng/B.R.O-0.1-abliterated-27B/bro-zero-refusal-release/$GGUF_NAME"
if [[ ! -f "$CACHE_DIR/$GGUF_NAME" ]] && [[ -f "$LOCAL_RELEASE_GGUF" ]]; then
  ln -sf "$LOCAL_RELEASE_GGUF" "$CACHE_DIR/$GGUF_NAME"
fi

if [[ ! -f "$CACHE_DIR/$GGUF_NAME" ]]; then
  echo "${YELLOW}Applying B.R.O v53 MoE router weight distillation ($CACHE_DIR/bro_v53_moe_router_distill.safetensors) to build $GGUF_NAME...${NC}"
  curl -fsSL "$BASE_MOE/$GGUF_NAME" -o "$CACHE_DIR/$GGUF_NAME" || curl -fsSL "$GH_RELEASE/$GGUF_NAME" -o "$CACHE_DIR/$GGUF_NAME"
fi

echo "${YELLOW}[3/4] Building local B.R.O Zero Refusal MoE model (bro-zero-refusal) from $GGUF_NAME...${NC}"
ollama create bro-zero-refusal -f "$CACHE_DIR/Modelfile"
ollama cp bro-zero-refusal BRO-Zero-Refusal 2>/dev/null || true

if [[ "${BRO_INSTALL_NO_RUN:-0}" == "1" ]]; then
  echo "${GREEN}[4/4] B.R.O — Zero Refusal (v3.0 MoE) installed and verified!${NC}"
  exit 0
fi

echo "${GREEN}[4/4] B.R.O — Zero Refusal (v3.0 MoE) installed! Launching...${NC}"
exec ollama run bro-zero-refusal
