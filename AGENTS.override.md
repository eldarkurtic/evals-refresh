## Notes about environment (to be adapted if wrong)

Facts about the reference host (8x H100 80 GB, RHEL 9.6, Docker 29 with compose v5):

- HF caches live on NFS: `HF_HOME`, `HF_HUB_CACHE`, `TRANSFORMERS_CACHE` are exported in the
  shell; `serve.sh` inherits them. Weights are already there for the models above.
- Docker's image store is on a 70 GB root disk. Check `df -h /` before any sandboxed task.
- The interactive shell aliases `docker` to `podman`; Inspect calls the real `/usr/bin/docker`
  and is unaffected. Use `/usr/bin/docker` explicitly in your own commands.
- Serving convention: `TP=2`, `DP=4` (four replicas behind one port on all 8 GPUs) for ~30B
  bf16 models. Adjust per model size; a 27–31B bf16 model needs ~26–31 GB per GPU at TP=2.
- `local_orchestrator.sh` activates the vLLM venv, starts `serve.sh` in the background, polls
  `/health`, activates the Inspect venv, runs `run_eval.sh "$@"`, and kills the server.

