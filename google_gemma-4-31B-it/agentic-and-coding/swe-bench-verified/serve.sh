#!/usr/bin/env bash
# Serve google/gemma-4-31B-it with vLLM.
# Flags follow the official vLLM recipe: https://recipes.vllm.ai/Google/gemma-4-31B-it
set -euo pipefail

MODEL="${MODEL:-google/gemma-4-31B-it}"
PORT="${PORT:-8000}"
TP="${TP:-2}"   # 31B bf16 fits comfortably on 2x H100
DP="${DP:-4}"   # 4 replicas behind one endpoint -> all 8 GPUs

exec vllm serve "$MODEL" \
  --tensor-parallel-size "$TP" \
  --data-parallel-size "$DP" \
  --max-model-len 262144 \
  --reasoning-parser gemma4 \
  --default-chat-template-kwargs '{"enable_thinking": true}' \
  --enable-auto-tool-choice --tool-call-parser gemma4 \
  --limit-mm-per-prompt '{"image": 0, "audio": 0}' \
  --chat-template "$(dirname "$0")/assets/tool_chat_template_gemma4.jinja" \
  --served-model-name "$MODEL" \
  --host 0.0.0.0 --port "$PORT"

