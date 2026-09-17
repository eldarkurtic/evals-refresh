# Qwen/Qwen3.8-27B — GPQA-Diamond

| | |
|---|---|
| Task | `inspect_evals/gpqa_diamond` (198 questions, 4 choices) |
| Category | knowledge-and-reasoning (subclass: science-reasoning) |
| Exec tier | `none` — no Docker, no sandbox, no tools |
| vLLM recipe | https://recipes.vllm.ai/Qwen/Qwen3.8-27B |

## Files

- `serve.sh` — deploys the model with a vLLM server. vLLM-serve arguments live here
  (parallelism, context length, reasoning/tool parsers), taken from the official recipe.
- `run_eval.sh` — runs the Inspect task against that server. Inspect-side params live here
  (task, epochs, sampling params, reasoning effort, max tokens, concurrency).
- `local_orchestrator.sh` — runs everything in your local dev environment: activates the
  venvs, sets GPUs, starts `serve.sh` in the background, runs `run_eval.sh`, tears down.
  **This is the only file you should modify** to match the environment you run in.

## Run

```bash
./local_orchestrator.sh
inspect view --log-dir ./logs
```

Always smoke-test first: `EPOCHS=1 ./local_orchestrator.sh --limit 5`

## Results

With model generation config:

`temperature=1.0, top_p=0.95, top_k=20, reasoning_effort=xhigh, max_tokens=131072, max_connections=128, epochs=3 (mean)`

the following scores and token stats are obtained:

| metric | value |
|---|---|
| accuracy (avg@3) | 0.9057 |
| stderr | 0.0193 |
| per-epoch accuracy | 0.899 / 0.909 / 0.909 |
| samples | 594 (198 x 3 epochs) |
| truncated (stop_reason=max_tokens) | 0 |
| unparsed answers | 1 (model stopped after 53k reasoning tokens with an empty final answer) |

| tokens / sample | input | output | reasoning |
|---|---|---|---|
| mean | 316 | 13,255 | 12,947 |
| median | 282 | 7,560 | 7,340 |
| max | 2,844 | 98,187 | 97,907 |

Log: `logs/2026-09-17T11-50-21-00-00_gpqa-diamond_M9RNDrU4khadEkxT84FbR5.eval` (2026-09-17)

## (optional) Patches for inspect-ai

Any change we had to make to `inspect-ai` / `inspect_evals` to run this task, with enough
detail to reapply it. None needed so far.

