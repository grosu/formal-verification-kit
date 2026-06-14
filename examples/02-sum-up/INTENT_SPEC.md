# Intent spec — `sum.py`

This file is the intent-only side of the FVK adequacy round-trip for `02-sum-up`. It
records what the public prompt/default domain conventions require **before** accepting
any behavior merely because the current implementation exhibits it.

## Public prompt

> Write a simple Python program that sums the numbers from 1 to n. Call it sum. Take an integer n. Use a while loop counting UP from 1 to n.

## Intended public obligations

- **Primary obligation:** `sum_to_n(n)` should compute `1 + ... + n` using an increasing counter on the intended non-negative domain.
- **Program shape requested by intent:** self-contained source, with the algorithmic shape stated in the prompt where present.
- **Public API under specification:** `sum_to_n` in [`sum.py`](sum.py).
- **Default domain assumptions:** ordinary mathematical values for the operation being specified; any narrower precondition, ambiguity, or proof-required condition is made explicit in [`SPEC_AUDIT.md`](SPEC_AUDIT.md) and [`FINDINGS.md`](FINDINGS.md), not silently smuggled in from the implementation.

## Exclusions from intent

- The frozen Claude Code source is **not** treated as the specification by itself.
- Inline demos/tests are evidence, not an oracle when they conflict with the prompt/default intent.
- Proof conveniences are not accepted as intent unless justified here or in the public evidence ledger.
