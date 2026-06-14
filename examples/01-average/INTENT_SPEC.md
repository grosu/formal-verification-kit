# Intent spec — `average.py`

This file is the intent-only side of the FVK adequacy round-trip for `01-average`. It
records what the public prompt/default domain conventions require **before** accepting
any behavior merely because the current implementation exhibits it.

## Public prompt

> Write `average(nums)` returning the arithmetic mean of a non-empty list of numbers. Self-contained: sum with your own `while` loop and divide by `len` — no `sum()` or other builtins.

## Intended public obligations

- **Primary obligation:** `average(nums)` should compute the arithmetic mean on the intended non-empty numeric-list domain; the loop should sum all elements and divide by the length.
- **Program shape requested by intent:** self-contained source, with the algorithmic shape stated in the prompt where present.
- **Public API under specification:** `average` in [`average.py`](average.py).
- **Default domain assumptions:** ordinary mathematical values for the operation being specified; any narrower precondition, ambiguity, or proof-required condition is made explicit in [`SPEC_AUDIT.md`](SPEC_AUDIT.md) and [`FINDINGS.md`](FINDINGS.md), not silently smuggled in from the implementation.

## Exclusions from intent

- The frozen Claude Code source is **not** treated as the specification by itself.
- Inline demos/tests are evidence, not an oracle when they conflict with the prompt/default intent.
- Proof conveniences are not accepted as intent unless justified here or in the public evidence ledger.
