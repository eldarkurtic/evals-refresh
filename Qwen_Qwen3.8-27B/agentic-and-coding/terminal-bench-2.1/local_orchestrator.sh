#!/usr/bin/env bash
# Local glue, specific to one server: venvs, GPUs, serve in background, eval, tear down.
# Treat this as a template and adapt paths/GPUs to your own environment.
export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
# Rootless Docker (image store under ~/.local/share/docker); the rootful daemon lives on a 70 GB root disk.
# Its daemon.json sets a runc runtime with NoNewKeyring: non-root users get 200 kernel keys, one per container otherwise.
export DOCKER_HOST="${DOCKER_HOST:-unix:///run/user/$(id -u)/docker.sock}"
PORT="${PORT:-8000}"
mkdir -p logs

source ~/.venvs/vllm/bin/activate
./serve.sh > logs/serve.log 2>&1 &
SERVE_PID=$!
until curl -sf "http://localhost:${PORT}/health" >/dev/null; do sleep 10; done

source ~/.venvs/inspect-harbor/bin/activate
./run_eval.sh "$@"

kill $SERVE_PID
