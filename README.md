---
license: apache-2.0
base_model:
- Qwen/Qwen3.5-35B-A3B
language:
- en
- he
pipeline_tag: text-generation
tags:
- qwen3.5
- moe
- 35b-a3b
- zero-refusal
- abliterated
- uncensored
- cybersecurity
- red-team
- gguf
- mlx
- safetensors
- ollama
---

# B.R.O — Zero Refusal (v3.0 MoE Edition | 35B-A3B)

**B.R.O (Breaching Remote Operation) — Zero Refusal** is the v3.0 local Mixture-of-Experts (MoE) release of B.R.O, distilled directly from **B.R.O v53 Zero-Refusal (Tinker)** (`bro-v53-zero-refusal-sampler`) onto the **Qwen3.5-35B-A3B** (`qwen35moe`) architecture.

Unlike v1.0/v2.0 (which used a 27B Dense backbone where all 27B parameters ran on every token), **B.R.O Zero Refusal v3.0** uses a **35B total / 3B active (`A3B`) MoE** architecture (256 routed experts + 1 shared expert per layer with hybrid GatedDeltaNet linear attention), delivering **~4.5x faster local inference (15–26.5 tok/s on Apple Silicon)** with **0.0% refusal rate** in Hebrew and English.

---

## Key Specifications

| Metric | Value |
|---|---|
| **Release Version** | `v3.0.0` (`B.R.O — Zero Refusal`) |
| **Architecture** | `qwen35moe` (Hybrid GatedDeltaNet + Sparse MoE) |
| **Total Parameters** | **35B** (34.7B) |
| **Active Parameters / Token** | **3B (`A3B`)** — 256 routed experts + 1 shared expert / layer |
| **Teacher Model** | **B.R.O v53 Zero-Refusal (Tinker)** (`0/32` refusals across 4 suites) |
| **Distilled Weight Artifacts** | `B.R.O-Zero-Refusal-35B-A3B-MoE-Q4_K_M.gguf` (`sha256:628a481a...`), `bro_v53_moe_router_distill.safetensors` (84.2 MB), `adapters.safetensors` (7.18 MB) |
| **Distilled SFT Corpus** | `bro-v53-zero-refusal-distill.jsonl` (618 trajectories, Intent-Locked) |
| **Local Refusal Rate** | **0.0%** (Hebrew + English + Raw No-System-Prompt + Offensive Cyber) |
| **Local Speed (Apple Silicon)** | **14.6 – 26.5 tok/s** generation / **238 tok/s** prompt eval |
| **Quantization / Size** | `Q4_K_M` GGUF (`21,169,117,248` bytes / 21.17 GB) |
| **Context Window** | `32,768` default (up to `262,144` native) |

---

## One-Line Terminal Install (macOS / Linux)

```bash
curl -fsSL https://huggingface.co/Sm0k13/B.R.O-abliterated-27B/resolve/main/install-bro-zero-refusal.zsh | zsh
```

Or install from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/timamar187-creator/BRO-abliterated-27B/main/install-bro-zero-refusal.zsh | zsh
```

After installation, run anytime with:

```bash
ollama run bro-zero-refusal
```

---

## How Zero Refusal v3.0 Was Built

1. **Teacher Training (B.R.O v53 on Tinker):** Trained from the `v30` champion state using 618 direct-fulfillment trajectories (`223,689` tokens) combining **Contrastive Refusal Unlearning**, **Intent-Locking (`<think>\n\n</think>\n\n`)**, and **System-Prompt Immunity** across 5 system templates (`bro_full`, `exody_agent`, `hebrew_direct`, `minimal`, `raw_empty`), achieving **0/32 (0.0%) refusals**.
2. **In-Place Float32 MoE Router Gate Orthogonalization (`bro_v53_moe_router_distill.safetensors`):** Applied rank-1 Arditi et al. refusal-subspace orthogonalization ($W'_l = W_l - \tau (W_l r_l) r_l^\top$, $\tau = 0.08$) across all 40 float32 MoE router gate matrices (`blk.{0..39}.ffn_gate_inp.weight`, `[256, 2048]`) inside `B.R.O-Zero-Refusal-35B-A3B-MoE-Q4_K_M.gguf`.
3. **MLX LoRA SFT Weight Distillation (`adapters.safetensors`):** Trained a rank-16 LoRA SFT adapter on the 618-trajectory B.R.O v53 corpus (`adapter_config.json` + `adapters.safetensors`).
4. **GGUF & Template Intent-Locking:** Patched `tokenizer.chat_template` and `Modelfile` so every generation pre-locks `<think>\n\n</think>\n\n`, preventing Chain-of-Thought self-censorship or multi-minute thinking stalls.
