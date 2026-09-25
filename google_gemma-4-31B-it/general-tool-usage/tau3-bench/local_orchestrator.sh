#!/usr/bin/env bash
# Local glue, specific to one server: venvs, GPUs, serve in background, eval, tear down.
# Treat this as a template and adapt paths/GPUs to your own environment.
# Two vLLM servers on this host: the model under test on GPUs 0-3 (port PORT) and the Qwen user simulator on
# GPUs 4-7 (port USER_PORT), TP=4 each; the simulator is bound to Inspect's `user` model role in run_eval.sh.
export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export TP="${TP:-4}" DP="${DP:-1}"
PORT="${PORT:-8000}"
USER_PORT="${USER_PORT:-8001}"
mkdir -p logs
# Rootless Docker (image store under ~/.local/share/docker); the daemon.json sets a runc runtime with NoNewKeyring.
export DOCKER_HOST="${DOCKER_HOST:-unix:///run/user/$(id -u)/docker.sock}"
# Every sample is a two-service compose project with its own network: the daemon's default-address-pools must hold
# at least --max-sandboxes networks (daemon.json here: two /16 pools split into /24 networks; Docker's default runs out at ~40).
# The task containers call the user-simulator / judge server on the host: rootless containers reach the host
export CONTAINER_HOST_IP="${CONTAINER_HOST_IP:-$(hostname -I | awk '{print $1}')}"

source ~/.venvs/vllm/bin/activate
CUDA_VISIBLE_DEVICES=0,1,2,3 ./serve.sh > logs/serve.log 2>&1 &
SERVE_PID=$!
CUDA_VISIBLE_DEVICES=4,5,6,7 USER_TP=4 USER_PORT="$USER_PORT" ./assets/serve_user_model.sh > logs/serve_user.log 2>&1 &
USER_SERVE_PID=$!
for p in "$PORT" "$USER_PORT"; do
  until curl -sf "http://localhost:${p}/health" >/dev/null; do
    # give up if a server died during startup (e.g. a GPU was busy), instead of polling forever
    if ! kill -0 $SERVE_PID 2>/dev/null || ! kill -0 $USER_SERVE_PID 2>/dev/null; then
      echo "a vLLM server exited before becoming healthy, see logs/serve.log and logs/serve_user.log" >&2
      kill $SERVE_PID $USER_SERVE_PID 2>/dev/null; exit 1
    fi
    sleep 10
  done
done

source ~/.venvs/inspect-harbor/bin/activate
./run_eval.sh "$@"

kill $SERVE_PID $USER_SERVE_PID
