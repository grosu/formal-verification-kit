# Intent spec — `sum.py`

This file is the intent-only side of the FVK adequacy round-trip for `03-sum-down`. It
records what the public prompt/default domain conventions require **before** accepting
any behavior merely because the current implementation exhibits it.

## Public prompt

> Let's write a very simple Python program which calculates the sum of numbers from 1 to n. Let's call it sum. It takes an input integer n. Let's do it using a while loop iterating from n all the way down to 1.

## Intended public obligations

- **Primary obligation:** `sum_to_n(n)` should compute `1 + ... + n` using a decreasing counter on the intended non-negative domain.
- **Program shape requested by intent:** self-contained source, with the algorithmic shape stated in the prompt where present.
- **Public API under specification:** `sum_to_n` in [`sum.py`](sum.py).
- **Default domain assumptions:** ordinary mathematical values for the operation being specified; any narrower precondition, ambiguity, or proof-required condition is made explicit in [`SPEC_AUDIT.md`](SPEC_AUDIT.md) and [`FINDINGS.md`](FINDINGS.md), not silently smuggled in from the implementation.

## Exclusions from intent

- The frozen Claude Code source is **not** treated as the specification by itself.
- Inline demos/tests are evidence, not an oracle when they conflict with the prompt/default intent.
- Proof conveniences are not accepted as intent unless justified here or in the public evidence ledger.
