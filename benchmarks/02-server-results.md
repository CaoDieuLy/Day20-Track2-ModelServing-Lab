# 02 — llama-server Results

Server: native `llama-server.exe` from the bonus `llama.cpp` build.

Settings: TinyLlama Q4_K_M, CPU backend, `-t 4`, `-ngl 0`, `--parallel 4`, `--cont-batching`, `--metrics`, port `8080`.

Smoke test:

- `POST /v1/chat/completions` succeeded in 19,754 ms.
- `GET /metrics` showed `llamacpp:tokens_predicted_total 80` after the smoke request.

| Concurrency | Requests | RPS | Median response (ms) | E2E P95 (ms) | E2E P99 (ms) | Failures |
|--:|--:|--:|--:|--:|--:|--:|
| 10 | 16 | 0.288 | 25,000 | 36,000 | 36,000 | 0 |
| 50 | 19 | 0.345 | 25,000 | 52,000 | 52,000 | 0 |

Metrics observations:

- At concurrency 10, peak `requests_processing` was 4 and peak `requests_deferred` was 6.
- At concurrency 50, peak `requests_processing` was 4 and peak `requests_deferred` was 46.
- This `llama.cpp` build's `/metrics` endpoint did not expose `llamacpp:kv_cache_usage_ratio`; the server log reported a CPU KV buffer of 44.00 MiB for 4 slots, 512 tokens per slot.
- The important serving behavior is visible anyway: `--parallel 4` saturated all slots while the extra 46 users queued, so P95 rose sharply under 50-user contention.

