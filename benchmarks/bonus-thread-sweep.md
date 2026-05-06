# Bonus — Thread sweep

Model: `tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf`  ·  GPU layers: `0`

| threads | tg64 (tok/s) |
|---:|---:|
| 1 | 8.7 |
| 2 | 11.3 |
| 4 | 10.5 |
| 8 | 9.3 |
| 16 | 13.9 |

**Best**: `-t 16` at 13.9 tok/s.

Look at the curve. If it peaks around your **physical** core count and drops as you go higher, that's the memory-bandwidth ceiling: extra threads fight over the same memory channels and slow each other down.
