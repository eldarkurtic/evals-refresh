#!/usr/bin/env bash
# BFCL (Berkeley Function-Calling Leaderboard, V1-V3 categories) on Qwen/Qwen3.8-27B against an already-running vLLM server.
#
# What this measures: the 4981 samples of inspect_evals's default BFCL run (gorilla repo pinned by inspect_evals 0.20.0):
# all V1 (single-turn AST), V2 (live, user-contributed) and V3 (multi-turn, stateful backends) categories, minus the
# retired `rest` category and the `format_sensitivity` meta-index. Tools are given natively (FC mode) and the model's
# tool calls are matched against the ground truth AST (single-turn) or the final backend state (multi-turn).
# The V4 categories are not run: web search needs a SerpAPI key, memory needs a two-step snapshot workflow.
# Neither model card reports BFCL; the official leaderboard's overall score also includes V4, so the number is
# not comparable to it (per-category accuracies are).
#
# --max-tokens is per turn. --time-limit caps wall time per sample as a runaway guard: 7200 s (1800 s cut 215 of the
# 2994 multi-turn samples of a 3-epoch Qwen run at 64 in flight; those samples score as they stand).

# No sandbox: --max-connections bounds in-flight samples; requests are short, so 64 fit easily in the KV cache.
# -M client_timeout raises Inspect's HTTP timeout (default 600s) for long reasoning turns.
# --fail-on-error 0.1 aborts only if >10% of samples hit infrastructure errors.
#
# Sampling params come from the model's generation_config.json (temp 1.0, top_p 0.95, top_k 20).
# --reasoning-effort is forwarded by Inspect as the OpenAI `reasoning_effort` field; vLLM turns it
# into chat_template_kwargs {"enable_thinking": true, "reasoning_effort": "xhigh"} (see the recipe).
set -euo pipefail

MODEL="${MODEL:-Qwen/Qwen3.8-27B}"
PORT="${PORT:-8000}"
EPOCHS="${EPOCHS:-3}"
LOG_DIR="${LOG_DIR:-./logs}"

export VLLM_BASE_URL="${VLLM_BASE_URL:-http://localhost:${PORT}/v1}"
export VLLM_API_KEY="${VLLM_API_KEY:-local}"

inspect eval inspect_evals/bfcl \
  --model "vllm/${MODEL}" \
  --epochs "$EPOCHS" --epochs-reducer mean \
  --temperature 1.0 --top-p 0.95 --top-k 20 \
  --reasoning-effort xhigh \
  --max-tokens "${MAX_TOKENS:-65536}" \
  --max-connections "${MAX_CONNECTIONS:-64}" \
  --time-limit "${TIME_LIMIT:-7200}" \
  --fail-on-error 0.1 \
  -M client_timeout=7200 \
  --log-dir "$LOG_DIR" \
  "$@"
