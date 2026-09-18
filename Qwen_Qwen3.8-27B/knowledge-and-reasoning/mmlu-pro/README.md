# Qwen/Qwen3.8-27B — MMLU-Pro

| | |
|---|---|
| Task | `inspect_evals/mmlu_pro` (12,032 questions, 10 choices, 14 subjects, 0-shot) |
| Category | knowledge-and-reasoning (subclass: knowledge-recall) |
| Exec tier | `none` — no Docker, no sandbox, no tools |
| vLLM recipe | https://recipes.vllm.ai/Qwen/Qwen3.8-27B |

`fewshot=0` (the package default): every question is asked zero-shot with the package's chain-of-thought
multiple-choice prompt (`ANSWER: $LETTER`). Dataset pinned at revision `b189ec765a`.

## Files

- `serve.sh` — deploys the model with a vLLM server. vLLM-serve arguments live here
  (parallelism, context length, reasoning/tool parsers), taken from the official recipe.
- `run_eval.sh` — runs the Inspect task against that server. Inspect-side params live here
  (task, epochs, sampling params, reasoning effort, max tokens, concurrency).
- `server_requirements.txt` / `client_requirements.txt` — `pip freeze` of the vLLM and Inspect
  venvs that produced the results below, with the host (GPUs, driver, CUDA, Python) in the header.
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

`temperature=1.0, top_p=0.95, top_k=20, reasoning_effort=xhigh, max_tokens=131072, max_connections=256, client_timeout=7200, epochs=1`

the following scores and token stats are obtained:

| metric | value |
|---|---|
| accuracy | 0.860 |
| stderr | 0.0032 |
| samples | 12,032 (1 epoch) |
| truncated (stop_reason=max_tokens) | 0 |
| unparsed answers | 9 |
| sample errors | 0 |

| tokens / sample | input | output | reasoning |
|---|---|---|---|
| mean | 308 | 4,454 | 4,288 |
| median | 275 | 796 | 606 |
| max | 1,767 | 121,089 | 120,917 |

Per subject: math 0.955, biology 0.927, chemistry 0.920, physics 0.920, business 0.915,
economics 0.895, computer science 0.876, psychology 0.841, engineering 0.838, philosophy 0.794,
health 0.790, other 0.776, history 0.748, law 0.718.

Total run time about 1 h 50 min on 8x H100 (256 concurrent samples).

## (optional) Patches for inspect-ai

Any change we had to make to `inspect-ai` / `inspect_evals` to run this task, with enough
detail to reapply it. None needed so far.
