#!/usr/bin/env bash
# Local glue, specific to one server: venvs, GPUs, serve in background, eval, tear down.
# Treat this as a template and adapt paths/GPUs to your own environment.
export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
# One TP=8 replica instead of the usual TP=2 x DP=4: vLLM's prefix cache is per replica and DP routes each turn
# of a sample to a random replica, so multi-turn agent runs re-prefill their history (15% cache hits, prefill-bound).
export TP="${TP:-8}" DP="${DP:-1}"
PORT="${PORT:-8000}"
mkdir -p logs

source ~/.venvs/vllm/bin/activate
./serve.sh > logs/serve.log 2>&1 &
SERVE_PID=$!
until curl -sf "http://localhost:${PORT}/health" >/dev/null; do
  # give up if the server died during startup (e.g. a GPU was busy), instead of polling forever
  kill -0 $SERVE_PID 2>/dev/null || { echo "vLLM server exited before becoming healthy, see logs/serve.log" >&2; exit 1; }
  sleep 10
done

source ~/.venvs/inspect/bin/activate
./run_eval.sh "$@"

kill $SERVE_PID
