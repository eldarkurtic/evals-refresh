# Speculative-decoding analysis

## Coverage

- Logs: 1, samples: 89, tasks: 89
- Model calls: 3851, with spec metrics: 3849, without: 2
- Histogram/step-count consistency: 0 mismatch(es) over 3849 calls

## Headline

| metric | value |
|---|---|
| micro MAL (1 + accepted/steps) | 2.938 |
| mean first-token acceptance rate | 0.659 |
| macro MAL (unweighted mean of per-call values) | 3.154 |
| median per-call MAL | 2.971 |
| mean conditional acceptance rate | 0.696 |

Micro MAL weights every verify step equally, so long responses dominate it. Macro MAL is the unweighted mean of the per-call values, so every request carries the same weight. The two differ when call length correlates with acceptance.

## Distribution of per-call MAL

| n | mean | median | p05 | p25 | p75 | p95 |
|---|---|---|---|---|---|---|
| 3849 | 3.154 | 2.971 | 2.218 | 2.610 | 3.503 | 4.771 |

## Per-position acceptance (overall)

`overall` = P(the draft token at this position is accepted) = P(verify step accepted more than j drafts); `conditional` = P(position j accepted | position j-1 accepted) = overall[j] / overall[j-1], with position 0 conditioned on nothing. The conditional column is the per-position hazard rate: a flat column means acceptance is geometric in position, and overall[j] is the running product of the conditionals. The 'exactly j' marginal probabilities are in `report.json` and `acceptance_by_position.csv`.

| position | overall acceptance | conditional acceptance |
|---|---|---|
| 0 | 0.659 | 0.659 |
| 1 | 0.432 | 0.655 |
| 2 | 0.287 | 0.664 |
| 3 | 0.195 | 0.682 |
| 4 | 0.138 | 0.705 |
| 5 | 0.099 | 0.722 |
| 6 | 0.073 | 0.738 |
| 7 | 0.055 | 0.744 |
| **Σ overall + 1 = MAL** | 2.938 | |

## Acceptance by region: thinking vs response

The reasoning block is the prefix of the completion, so its length in completion tokens (`usage.reasoning_tokens`, verified equal to the token count of the reasoning text) is the boundary. Each verify step's token span follows from its accepted-draft count. A step is attributed to the region that holds the midpoint of its accepted draft tokens. 409 step(s) straddled the boundary. No tokenizer is needed, because the boundary and the step spans are both in the logged response.

| region | verify steps | share of steps | MAL | accepted drafts |
|---|---|---|---|---|
| thinking | 2208539 | 0.8606 | 2.746 | 3855346 |
| response | 357621 | 0.1394 | 4.127 | 1118139 |

Accepted draft tokens split exactly by token position: thinking 3855453, response 1118032.

| position | thinking overall | thinking conditional | response overall | response conditional |
|---|---|---|---|---|
| 0 | 0.643 | 0.643 | 0.760 | 0.760 |
| 1 | 0.403 | 0.628 | 0.607 | 0.799 |
| 2 | 0.255 | 0.633 | 0.482 | 0.794 |
| 3 | 0.165 | 0.648 | 0.382 | 0.792 |
| 4 | 0.111 | 0.670 | 0.304 | 0.796 |
| 5 | 0.076 | 0.688 | 0.243 | 0.798 |
| 6 | 0.054 | 0.706 | 0.194 | 0.801 |
| 7 | 0.038 | 0.711 | 0.155 | 0.799 |

thinking: Σ overall + 1 = 2.746 (MAL 2.746)
response: Σ overall + 1 = 4.127 (MAL 4.127)

## MAL by turn number

| turns | calls | steps | micro MAL | macro MAL |
|---|---|---|---|---|
| 1 | 89 | 243091 | 2.711 | 2.620 |
| 2 | 89 | 111712 | 2.784 | 2.926 |
| 3 | 89 | 129499 | 2.775 | 3.006 |
| 4 | 89 | 61204 | 2.868 | 3.038 |
| 5 | 89 | 91623 | 2.876 | 3.056 |
| 6-10 | 417 | 279863 | 2.986 | 3.187 |
| 11-20 | 702 | 408357 | 2.966 | 3.112 |
| 21-40 | 850 | 482031 | 2.971 | 3.161 |
| 41+ | 1435 | 758780 | 3.022 | 3.232 |

## MAL by context length (prompt tokens)

| tokens | calls | steps | micro MAL | macro MAL |
|---|---|---|---|---|
| <4k | 243 | 352877 | 2.712 | 2.827 |
| 4-16k | 421 | 310563 | 2.879 | 3.081 |
| 16-32k | 428 | 187740 | 2.840 | 3.081 |
| 32-64k | 700 | 471952 | 2.902 | 3.159 |
| 64-128k | 1191 | 719474 | 3.040 | 3.182 |
| 128k+ | 866 | 523554 | 3.054 | 3.277 |

## MAL by output length

| tokens | calls | steps | micro MAL | macro MAL |
|---|---|---|---|---|
| <1k | 2359 | 265484 | 3.149 | 3.178 |
| 1-4k | 1097 | 725633 | 3.001 | 3.172 |
| 4-16k | 328 | 801003 | 2.921 | 2.983 |
| 16-64k | 59 | 636020 | 2.820 | 2.869 |
| 64k+ | 6 | 138020 | 2.849 | 2.888 |

## MAL by epoch

| epoch | calls | steps | micro MAL | macro MAL |
|---|---|---|---|---|
| 1 | 3849 | 2566160 | 2.938 | 3.154 |

## MAL pass vs fail

| verdict | calls | steps | micro MAL | macro MAL |
|---|---|---|---|---|
| fail | 747 | 685641 | 2.937 | 3.155 |
| pass | 3102 | 1880519 | 2.938 | 3.154 |

## MAL by stop reason

| stop_reason | calls | steps | micro MAL | macro MAL |
|---|---|---|---|---|
| max_tokens | 6 | 138020 | 2.849 | 2.888 |
| stop | 5 | 1415 | 3.175 | 3.162 |
| tool_calls | 3838 | 2426725 | 2.943 | 3.155 |

## Outlier removal

Thresholds: call output tokens p95 = 7114, sample total output tokens p95 = 261266.

| variant | calls | steps | micro MAL | macro MAL |
|---|---|---|---|---|
| all calls | 3849 | 2566160 | 2.938 | 3.154 |
| drop calls with output_tokens > p95 | 3656 | 1349252 | 3.005 | 3.165 |
| drop whole samples with total output_tokens > p95 | 3273 | 2009992 | 2.935 | 3.148 |

## Within-response drift

MAL by decile of position within the response (MAL = 1 + accepted drafts / verify steps).

| decile | verify steps | MAL |
|---|---|---|
| 0 | 258374 | 2.877 |
| 1 | 256404 | 2.807 |
| 2 | 256788 | 2.784 |
| 3 | 256437 | 2.832 |
| 4 | 256046 | 2.852 |
| 5 | 257176 | 2.885 |
| 6 | 256825 | 2.898 |
| 7 | 256400 | 2.954 |
| 8 | 256792 | 3.102 |
| 9 | 254918 | 3.394 |

## Pass vs fail

| verdict | calls | micro MAL |
|---|---|---|
| fail | 747 | 2.937 |
| pass | 3102 | 2.938 |

## Per-task MAL (20 lowest)

| task | calls | micro MAL | macro MAL |
|---|---|---|---|
| terminal-bench/mailman | 93 | 2.493 | 2.916 |
| terminal-bench/filter-js-from-html | 54 | 2.505 | 2.974 |
| terminal-bench/configure-git-webserver | 25 | 2.506 | 3.317 |
| terminal-bench/tune-mjcf | 55 | 2.523 | 3.040 |
| terminal-bench/winning-avg-corewars | 85 | 2.551 | 2.715 |
| terminal-bench/build-pov-ray | 52 | 2.575 | 2.785 |
| terminal-bench/qemu-startup | 18 | 2.578 | 3.311 |
| terminal-bench/cancel-async-tasks | 23 | 2.608 | 3.053 |
| terminal-bench/git-multibranch | 32 | 2.623 | 3.112 |
| terminal-bench/large-scale-text-editing | 18 | 2.627 | 3.036 |
| terminal-bench/install-windows-3.11 | 83 | 2.631 | 2.964 |
| terminal-bench/break-filter-js-from-html | 16 | 2.636 | 2.566 |
| terminal-bench/sqlite-with-gcov | 22 | 2.638 | 2.797 |
| terminal-bench/schemelike-metacircular-eval | 71 | 2.662 | 3.099 |
| terminal-bench/reshard-c4-data | 47 | 2.674 | 3.327 |
| terminal-bench/custom-memory-heap-crash | 33 | 2.683 | 2.855 |
| terminal-bench/compile-compcert | 76 | 2.704 | 2.929 |
| terminal-bench/train-fasttext | 69 | 2.708 | 3.071 |
| terminal-bench/extract-elf | 11 | 2.765 | 2.955 |
| terminal-bench/qemu-alpine-ssh | 24 | 2.772 | 3.002 |

Full table: `mal_by_task.csv`. Positions per slice: `acceptance_by_position.csv`.
