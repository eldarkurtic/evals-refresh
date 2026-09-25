#!/usr/bin/env bash
# Local glue, specific to one server: venvs, GPUs, serve in background, eval, tear down.
# Treat this as a template and adapt paths/GPUs to your own environment.
export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
# Rootless Docker (image store under ~/.local/share/docker); the rootful daemon lives on a 70 GB root disk.
# Its daemon.json sets a runc runtime with NoNewKeyring: non-root users get 200 kernel keys, one per container otherwise.
export DOCKER_HOST="${DOCKER_HOST:-unix:///run/user/$(id -u)/docker.sock}"
# Every sample is a two-service compose project with its own network: the daemon's default-address-pools must hold
# at least --max-sandboxes networks (daemon.json here: two /16 pools split into /24 networks; Docker's default runs out at ~40).
# One TP=8 replica instead of the usual TP=2 x DP=4: vLLM's prefix cache is per replica and DP routes each turn
# of a sample to a random replica, so multi-turn agent runs re-prefill their history (15% cache hits, prefill-bound).
export TP="${TP:-8}" DP="${DP:-1}"
PORT="${PORT:-8000}"
mkdir -p logs
# Rootless Docker (image store under ~/.local/share/docker); the daemon.json sets a runc runtime with NoNewKeyring.
# The task containers call the user-simulator / judge server on the host: rootless containers reach the host
# at its primary IP (not localhost); run_eval.sh builds OPENAI_BASE_URL from it.
export CONTAINER_HOST_IP="${CONTAINER_HOST_IP:-$(hostname -I | awk '{print $1}')}"

source ~/.venvs/vllm/bin/activate
./serve.sh > logs/serve.log 2>&1 &
SERVE_PID=$!
until curl -sf "http://localhost:${PORT}/health" >/dev/null; do
  # give up if the server died during startup (e.g. a GPU was busy), instead of polling forever
  kill -0 $SERVE_PID 2>/dev/null || { echo "vLLM server exited before becoming healthy, see logs/serve.log" >&2; exit 1; }
  sleep 10
done

source ~/.venvs/inspect-harbor/bin/activate
./run_eval.sh "$@"

kill $SERVE_PID
