# 03 — Milestone Integration Notes

The demo uses a local/stubbed version of the N16-N19 stack so the N20 serving endpoint can be exercised on this laptop:

- N16 Cloud/IaC: stubbed as localhost, with `llama-server` on `http://localhost:8080`.
- N17 Data pipeline: stubbed as an in-memory curated document list.
- N18 Lakehouse: stubbed as `TOY_DOCS`, standing in for processed rows.
- N19 Vector + Feature Store: stubbed as keyword-overlap retrieval with provenance IDs; Feast is noted as not used for this local demo.

Three example queries ran end-to-end through `retrieve()`, `build_prompt()`, and `answer()`:

| Query | Retrieved contexts | Retrieve (ms) | llama-server (ms) | Total (ms) |
|---|---|--:|--:|--:|
| Why is goodput more useful than throughput? | n20-goodput, n20-paged, n20-radix | 0.1 | 26,895.0 | 26,895.6 |
| What problem does PagedAttention actually solve? | n20-paged, n20-radix, n20-disagg | 0.1 | 8,147.2 | 8,147.7 |
| When should I think about disaggregated serving? | n20-disagg, n20-quant, n20-paged | 0.4 | 11,867.1 | 11,867.7 |

Latency observation: retrieval is effectively free in this stubbed local version; almost all time is llama-server decode on the CPU-only TinyLlama setup.

