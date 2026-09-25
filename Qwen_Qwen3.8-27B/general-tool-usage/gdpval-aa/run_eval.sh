#!/usr/bin/env bash
# GDPval (gold set) on Qwen/Qwen3.8-27B against an already-running vLLM server.
#
# What this measures: the 220 open-sourced GDPval tasks (HF openai/gdpval, revision pinned by inspect_evals 0.20.0):
# professional deliverables (documents, spreadsheets, slides, ...) across 44 occupations, produced agentically with
# Inspect's default tool loop (bash, python; 180 s tool timeout) inside inspect_evals's GDPval Docker image (LibreOffice
# and the paper's package list). Input files are staged into the container; deliverables are collected from
# /workspace/deliverable_files. Scoring is a separate phase (see README): the package's own scorer only records the
# final text. Artificial Analysis's GDPval-AA reports an Elo from blind pairwise LLM-judge comparisons between models,
# which is not reproducible for a single model; see README for the protocol used here.
#
# --max-tokens is per turn; 65536 leaves room for several turns inside the context window.
# --time-limit caps wall time per sample as a runaway guard; --message-limit bounds the tool loop (see README).
# -M client_timeout raises Inspect's HTTP timeout (default 600s) for long reasoning turns.
# --fail-on-error 0.1 aborts only if >10% of samples hit infrastructure errors.
set -euo pipefail

MODEL="${MODEL:-Qwen/Qwen3.8-27B}"
PORT="${PORT:-8000}"
EPOCHS="${EPOCHS:-1}"
LOG_DIR="${LOG_DIR:-./logs}"

export VLLM_BASE_URL="${VLLM_BASE_URL:-http://localhost:${PORT}/v1}"
export VLLM_API_KEY="${VLLM_API_KEY:-local}"

inspect eval inspect_evals/gdpval \
  --model "vllm/${MODEL}" \
  --epochs "$EPOCHS" --epochs-reducer mean \
  --temperature 1.0 --top-p 0.95 --top-k 20 \
  --reasoning-effort xhigh \
  --max-tokens "${MAX_TOKENS:-65536}" \
  --message-limit "${MESSAGE_LIMIT:-200}" \
  --max-connections "${MAX_CONNECTIONS:-56}" \
  --max-sandboxes "${MAX_SANDBOXES:-56}" \
  --time-limit "${TIME_LIMIT:-7200}" \
  --fail-on-error 0.1 \
  -M client_timeout=7200 \
  --log-dir "$LOG_DIR" \
  "$@"
