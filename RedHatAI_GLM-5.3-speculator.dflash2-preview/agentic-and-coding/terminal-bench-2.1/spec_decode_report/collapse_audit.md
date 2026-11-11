# DFlash2 acceptance-collapse audit (vLLM #63587)

Source: `calls.csv` — 3849 calls carrying `metrics.speculative_decoding`.

**No collapsed calls found.** The acceptance numbers in `report.md` are trustworthy as reported; the build in `serve.sh` (vLLM main, which contains the #64059 fix) held.

| metric | all calls | excluding collapsed |
|---|---|---|
| calls | 3849 | 3849 |
| verify steps | 2566160 | 2566160 |
| micro MAL (1 + accepted/steps) | 2.938 | 2.938 |
| macro MAL (mean of per-call) | 3.154 | 3.154 |
| collapsed calls | 0 | 0 |
| calls with trailing zero run >= 8 | 1 | 0 |

| position | overall acceptance (all) | overall acceptance (excluding collapsed) |
|---|---|---|
| 0 | 0.6589 | 0.6589 |
| 1 | 0.4318 | 0.4318 |
| 2 | 0.2868 | 0.2868 |
| 3 | 0.1955 | 0.1955 |
| 4 | 0.1377 | 0.1377 |
| 5 | 0.0994 | 0.0994 |
| 6 | 0.0734 | 0.0734 |
| 7 | 0.0546 | 0.0546 |
