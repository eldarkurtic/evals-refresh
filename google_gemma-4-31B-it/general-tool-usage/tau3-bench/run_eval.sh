#!/usr/bin/env bash
# tau3-bench (Harbor hub package sierra-research/tau3-bench) on google/gemma-4-31B-it against an already-running vLLM server.
#
# What this measures: the 375 tasks of tau3-bench (airline 50, retail 114, telecom 114, banking_knowledge 97): the
# agent talks to a simulated customer and to the domain tools through the task's MCP server (a sidecar container
# started by the task's docker-compose.yaml), and the verifier scores the final database state, the information
# communicated, and (91 tasks) natural-language assertions judged by an LLM. The user simulator and the
# assertion judge are LLM calls made from inside the containers through an OpenAI-compatible endpoint
# (OPENAI_BASE_URL, TAU2_USER_MODEL, TAU2_NL_ASSERTIONS_MODEL); both are Qwen/Qwen3.8-27B for every model of
# this repo (a fixed simulator, as on the tau-bench leaderboards), reached at the host address that containers
# can route to (local_orchestrator.sh exports it). Neither model card reports tau3-bench.
#
# Requires inspect_harbor with [[environment.mcp_servers]] support (meridianlabs-ai/inspect_harbor#186, installed from the
# fork branch; see README, Setup and Patches); releases up to 1.0.0 run these tasks without their tools.
# --max-tokens is per turn. --time-limit caps wall time per sample; Harbor's agent budget for these tasks is 3600 s.
# --max-sandboxes equals --max-connections: Inspect holds two containers per in-flight sample here.
# -T override_cpus=0 drops the per-container CPU cap (rootless Docker rejects `cpus`).
# -M client_timeout raises Inspect's HTTP timeout (default 600s) for long reasoning turns.
# --fail-on-error 0.1 aborts only if >10% of samples hit infrastructure errors.
#
# Sampling params come from the model's generation_config.json (temp 1.0, top_p 0.95, top_k 64).
# assets/generate_config.json turns thinking on per request (Gemma 4 has no reasoning-effort levels,
# only enable_thinking); it is also the server default in serve.sh. The user simulator (Qwen) runs on a
# second server, USER_PORT (see local_orchestrator.sh).
set -euo pipefail

MODEL="${MODEL:-google/gemma-4-31B-it}"
PORT="${PORT:-8000}"
USER_PORT="${USER_PORT:-8001}"
EPOCHS="${EPOCHS:-1}"
LOG_DIR="${LOG_DIR:-./logs}"

export VLLM_BASE_URL="${VLLM_BASE_URL:-http://localhost:${PORT}/v1}"
export VLLM_API_KEY="${VLLM_API_KEY:-local}"
# User simulator and NL-assertion judge, called from inside the task containers (see local_orchestrator.sh for
# the host address). litellm model names: "openai/<served model name>" against OPENAI_BASE_URL.
export OPENAI_API_KEY="${OPENAI_API_KEY:-local}"
export OPENAI_BASE_URL="${OPENAI_BASE_URL:-http://${CONTAINER_HOST_IP:-127.0.0.1}:${USER_PORT:-$PORT}/v1}"
export TAU2_USER_MODEL="${TAU2_USER_MODEL:-openai/Qwen/Qwen3.8-27B}"
export TAU2_NL_ASSERTIONS_MODEL="${TAU2_NL_ASSERTIONS_MODEL:-openai/Qwen/Qwen3.8-27B}"

# The task set is generated from the adapter fork carrying harbor-framework/harbor#3401 (image fix; see README, Setup
# and Patches); swap back to `inspect_harbor/sierra_research_tau3_bench -T ref=<digest>` once merged and republished.
DATASET_PATH="${DATASET_PATH:-$HOME/.cache/harbor/local/tau3-bench-cc9e4b7c}"

inspect eval inspect_harbor/harbor \
  -T path="$DATASET_PATH" \
  -T override_cpus=0 \
  --model "vllm/${MODEL}" \
  --epochs "$EPOCHS" --epochs-reducer mean \
  --temperature 1.0 --top-p 0.95 --top-k 64 \
  --generate-config "$(dirname "$0")/assets/generate_config.json" \
  --max-tokens "${MAX_TOKENS:-65536}" \
  --max-connections "${MAX_CONNECTIONS:-56}" \
  --max-sandboxes "${MAX_SANDBOXES:-56}" \
  --time-limit "${TIME_LIMIT:-3600}" \
  --fail-on-error 0.1 \
  -M client_timeout=7200 \
  --log-dir "$LOG_DIR" \
  "$@"
