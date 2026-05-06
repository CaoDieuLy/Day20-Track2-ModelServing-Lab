# Bonus Challenge C5 — Weakest Laptop Path

Hardware context: Windows 11 laptop, Intel i5-1135G7, 4 physical / 8 logical cores, 7.8 GB RAM, CPU-only backend.

The practical model tier for this machine is TinyLlama-1.1B. The setup downloaded both Q4_K_M and Q2_K so the baseline could compare quality-oriented and tight-RAM quantizations without pulling a larger model.

## Numbers

| Configuration | Decode speed | Notes |
|---|--:|---|
| Python quickstart, Q4_K_M, `n_threads=4` | 11.8 tok/s | Better quality default for the lab |
| Python quickstart, Q2_K, `n_threads=4` | 15.7 tok/s | Faster and smaller, but quality is visibly weaker |
| Native llama.cpp, Q4_K_M, `-t 4` | 10.5 tok/s | Thread-sweep baseline |
| Native llama.cpp, Q4_K_M, `-t 16` | 13.9 tok/s | Best measured thread setting |

## Takeaway

For this laptop, TinyLlama Q4_K_M is the most useful default: it fits comfortably in RAM, serves through the OpenAI-compatible endpoint, and keeps output quality above the Q2_K fallback. Q2_K is valuable as a survival mode for very tight memory, but the C5 answer is not "always pick the smallest file"; the best useful tier is the smallest model that still gives coherent answers for the task.

The surprising result is that oversubscribing to 16 threads was fastest in the native sweep. My first expectation was a peak near physical cores, but this build/CPU combination benefited from more worker threads during the short decode benchmark. The serving result still shows the real bottleneck clearly: only four server slots were active, and queued requests dominated P95 under concurrency.

