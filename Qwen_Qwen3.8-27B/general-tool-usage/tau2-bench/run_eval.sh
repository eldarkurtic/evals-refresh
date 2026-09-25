#!/usr/bin/env bash
# tau2-bench (inspect_evals native implementation) on Qwen/Qwen3.8-27B against an already-running vLLM server.
#
# What this measures: the 375 "base" tasks of tau2-bench >= 1.0 (airline 50, retail 114, telecom 114, banking_knowledge 97;
# the same task set as the Harbor tau3-bench package, minus its voice modality), run with inspect_evals's native
# implementation: the domain tools are Python tools in-process (no sandbox), a user-simulator model plays the
# customer (model role `user`, temperature 0 as in tau2-bench), and each conversation is scored on the final
# database state plus the information the agent had to communicate (pass@1 per task; the airline natural-language
# assertions are not graded by this implementation). Neither model card reports tau2/tau3-bench.
#
# The user simulator is Qwen/Qwen3.8-27B for both models of this repo (a fixed simulator, as on the tau-bench
# leaderboards); for the Qwen run it is served by the same server (--model-role user).
# --max-tokens is per turn. --time-limit caps wall time per sample as a runaway guard; the task's own loop limit is
# 100 user/agent exchanges (task parameter message_limit). No sandbox: --max-connections bounds in-flight samples.
# -M client_timeout raises Inspect's HTTP timeout (default 600s) for long reasoning turns.
# --fail-on-error 0.1 aborts only if >10% of samples hit infrastructure errors.
#
# Sampling params come from the model's generation_config.json (temp 1.0, top_p 0.95, top_k 20); the task's own
# temperature=0.0 only applies to the user simulator (Inspect's get_model() returns the eval's model with its CLI config).
# --reasoning-effort is forwarded by Inspect as the OpenAI `reasoning_effort` field; vLLM turns it
# into chat_template_kwargs {"enable_thinking": true, "reasoning_effort": "xhigh"} (see the recipe).
set -euo pipefail

MODEL="${MODEL:-Qwen/Qwen3.8-27B}"
USER_MODEL="${USER_MODEL:-vllm/Qwen/Qwen3.8-27B}"
PORT="${PORT:-8000}"
EPOCHS="${EPOCHS:-1}"
LOG_DIR="${LOG_DIR:-./logs}"

export VLLM_BASE_URL="${VLLM_BASE_URL:-http://localhost:${PORT}/v1}"
export VLLM_API_KEY="${VLLM_API_KEY:-local}"

inspect eval inspect_evals/tau2_airline inspect_evals/tau2_retail inspect_evals/tau2_telecom inspect_evals/tau2_banking \
  --model "vllm/${MODEL}" \
  --model-role "user=${USER_MODEL}" \
  --epochs "$EPOCHS" --epochs-reducer mean \
  --temperature 1.0 --top-p 0.95 --top-k 20 \
  --reasoning-effort xhigh \
  --max-tokens "${MAX_TOKENS:-65536}" \
  --max-connections "${MAX_CONNECTIONS:-56}" \
  --time-limit "${TIME_LIMIT:-3600}" \
  --fail-on-error 0.1 \
  -M client_timeout=7200 \
  --log-dir "$LOG_DIR" \
  "$@"
