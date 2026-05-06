# Reflection - Lab 20 Personal Report

**Ho Ten:** Cao Diệu Ly  
**Cohort:** AICB-P2T2  
**Ngay submit:** 2026-05-06

## 1. Hardware Spec

- **OS:** Windows 11 AMD64
- **CPU:** 11th Gen Intel(R) Core(TM) i5-1135G7 @ 2.40GHz
- **Cores:** 4 physical / 8 logical
- **CPU extensions:** native x86 build selected AVX/AVX2/FMA and emitted an AVX512 CPU backend variant
- **RAM:** 7.8 GB
- **Accelerator:** CPU only
- **llama.cpp backend da chon:** CPU
- **Recommended model tier:** TinyLlama-1.1B Q4_K_M

Setup story: Windows needed Python 3.12, `llama-cpp-python`, and UTF-8 console env vars for the lab scripts. I also patched hardware detection to avoid broken/blocked `wmic` and used a native `llama.cpp` build for the server so `/metrics` is available.

## 2. Track 01 - Quickstart Numbers

| Model | Load (ms) | TTFT P50/P95 (ms) | TPOT P50/P95 (ms) | E2E P50/P95/P99 (ms) | Decode rate (tok/s) |
|---|--:|--:|--:|--:|--:|
| tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf | 2098 | 231 / 370 | 84.7 / 135.8 | 5150 / 5650 / 5685 | 11.8 |
| tinyllama-1.1b-chat-v1.0.Q2_K.gguf | 450 | 365 / 526 | 63.8 / 87.1 | 3976 / 5356 / 5668 | 15.7 |

Observation: Q2_K decoded faster and loaded much faster, but Q4_K_M is the better default for this laptop because the model still fits in RAM and the output quality is less brittle.

## 3. Track 02 - llama-server Load Test

Server settings: native `llama-server.exe`, TinyLlama Q4_K_M, CPU backend, `-t 4`, `-ngl 0`, `--parallel 4`, `--cont-batching`, `--metrics`.

| Concurrency | Total RPS | TTFB/Response P50 (ms) | E2E P95 (ms) | E2E P99 (ms) | Failures |
|--:|--:|--:|--:|--:|--:|
| 10 | 0.288 | 25,000 | 36,000 | 36,000 | 0 |
| 50 | 0.345 | 25,000 | 52,000 | 52,000 | 0 |

KV-cache observation: this `llama.cpp` build's `/metrics` endpoint did not expose `llamacpp:kv_cache_usage_ratio`. The server log reported a CPU KV buffer of 44.00 MiB for 4 slots of 512 tokens each. Under concurrency 50, `requests_processing` stayed at 4 while `requests_deferred` peaked at 46, so the bottleneck was slot contention and CPU decode, not model loading.

## 4. Track 03 - Milestone Integration

- **N16 Cloud/IaC:** stubbed as localhost, with `llama-server` on `http://localhost:8080`.
- **N17 Data pipeline:** stubbed as an in-memory curated document list.
- **N18 Lakehouse:** stubbed as `TOY_DOCS`, representing processed records.
- **N19 Vector + Feature Store:** stubbed as keyword-overlap retrieval with provenance IDs; Feast is noted but not used in this local demo.

Pipeline timing:

| Query | Retrieved contexts | Retrieve (ms) | llama-server (ms) | Total (ms) |
|---|---|--:|--:|--:|
| Why is goodput more useful than throughput? | n20-goodput, n20-paged, n20-radix | 0.1 | 26,895.0 | 26,895.6 |
| What problem does PagedAttention actually solve? | n20-paged, n20-radix, n20-disagg | 0.1 | 8,147.2 | 8,147.7 |
| When should I think about disaggregated serving? | n20-disagg, n20-quant, n20-paged | 0.4 | 11,867.1 | 11,867.7 |

Reflection: retrieval is essentially free in this local stub. The llama-server call dominates total latency, which matches the CPU-only setup: decode time is the expensive part once the model is loaded.

## 5. Bonus - The Single Change That Mattered Most

**Change:** Build native `llama.cpp` with `-DGGML_NATIVE=ON`, then sweep CPU thread count.

Before vs after:

```text
before: native llama.cpp Q4_K_M at -t 4  = 10.5 tok/s
after:  native llama.cpp Q4_K_M at -t 16 = 13.9 tok/s
speedup: ~1.32x
```

Thread sweep:

| threads | tg64 (tok/s) |
|---:|---:|
| 1 | 8.7 |
| 2 | 11.3 |
| 4 | 10.5 |
| 8 | 9.3 |
| 16 | 13.9 |

Why it worked: the machine is CPU-only, so every generated token is gated by CPU kernels and memory traffic. `-DGGML_NATIVE=ON` lets the build target the actual x86 CPU instead of a conservative generic wheel. The thread sweep then finds the best scheduling point for this workload. I expected the peak to be near physical cores, but this short decode benchmark peaked at 16 threads, which suggests the native build and Windows scheduler found enough parallel work to hide stalls even when oversubscribing.

This does not mean 16 threads is always best. The server still saturated at 4 active slots and queued requests under load. For production-style serving on this laptop, the main lesson is to measure the exact workload: benchmark decode threads separately from concurrency slots.

Bonus challenge attempted: C5 "Weakest laptop" path. With 7.8 GB RAM and CPU-only execution, TinyLlama Q4_K_M is the most useful default. Q2_K is faster at 15.7 tok/s in Python quickstart, but Q4_K_M gives better quality while still fitting comfortably in memory.

## 6. Dieu Ngac Nhien Nhat

The 50-user run did not increase throughput much; it mostly increased queueing. That made the difference between throughput and goodput@SLO much more concrete than the slide definition.

## 7. Self-Graded Checklist

- [x] `hardware.json` da tao
- [x] `models/active.json` da tao
- [x] `benchmarks/01-quickstart-results.md` da tao
- [x] `benchmarks/02-server-results.md` va metrics CSV da tao
- [x] `benchmarks/03-integration-notes.md` da tao
- [x] `benchmarks/bonus-thread-sweep.md` da tao
- [x] Bonus challenge C5 writeup da tao
- [x] Native `llama.cpp` build completed
- [ ] Screenshots: generated evidence PNGs are included, but real terminal screenshots are still recommended before final LMS submission
- [ ] Push repo len GitHub public
- [ ] Paste public repo URL vao VinUni LMS
