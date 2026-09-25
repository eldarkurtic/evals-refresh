# Local environment notes

Host-specific facts for agents working in this checkout (this file is referenced and imported from `AGENTS.md`).
Keep it accurate for the machine you run on; it is the only place where environment details belong, and
nothing in it should be needed to understand the task directories or their READMEs.

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

## Host-side measures for the Harbor coding tasks (not part of any task)

- SWE-bench Pro images are built from `FROM jefzda/sweap-images:<instance>` on Docker Hub; the anonymous limit is
  100 pulls per hour per IP and 731 tasks cost about 4 GB each on disk. Pre-build the task images in batches
  (`docker build -t <name> <task>/environment`; inspect_harbor 1.0 names them `hb__<environment hash>`) and delete
  the images of finished batches; run a rate-limit-aware pull loop rather than letting Inspect pull on demand.
- Rootless Docker maps only 65536 subordinate UIDs; the SWE-bench Verified matplotlib images and the SWE-bench Pro
  openlibrary/protonmail base images contain files owned by higher UIDs and fail to extract. They were loaded from
  layer-rewritten copies (`~/.cache/swe_rewrite/rewrite_images2.py`, UIDs mapped to root; name the loaded image with
  the full `docker.io/<repo>:<tag>` reference, containerd's image store does not resolve unnormalized names).
- Multi-service tasks (tau3-bench) create one compose network per sample; `daemon.json` carries
  `default-address-pools` for 512 networks (Docker's default runs out near 40 concurrent samples).
- The DeepSWE task images (113, about 122 GB) come from ECR public, which throttles bursts; pull them serially.

