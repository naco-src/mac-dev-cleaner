# D014 — Scan performance: parallel phases and bounded I/O

**Status:** Accepted (2026-10-08)

## Context

Full scan can walk large trees sequentially.

## Decision

After project index, run scan **phases in parallel**; size aggregation uses **`mapConcurrent`** with CPU-based cap. Doctor checks run in parallel with UI/core logging.

## Consequences

Log order is interleaved; UI shows timestamps. Tuning via optional `scanConcurrency` on `ScanService` / host factory.
