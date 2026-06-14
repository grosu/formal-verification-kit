# Intent spec — `factorial.py`

This file is the intent-only side of the FVK adequacy round-trip for `07-factorial`. It
records what the public prompt/default domain conventions require **before** accepting
any behavior merely because the current implementation exhibits it.

## Public prompt

> Write a Python function `factorial(n)` that returns n factorial (n! = 1·2·…·n, with 0! = 1) for a non-negative integer n. Use recursion. Add a few tests and run them.

## Intended public obligations

- **Primary obligation:** `factorial(n)` should return `n!` for non-negative integers, with `0! = 1`.
- **Program shape requested by intent:** self-contained source, with the algorithmic shape stated in the prompt where present.
- **Public API under specification:** `factorial` in [`factorial.py`](factorial.py).
- **Default domain assumptions:** ordinary mathematical values for the operation being specified; any narrower precondition, ambiguity, or proof-required condition is made explicit in [`SPEC_AUDIT.md`](SPEC_AUDIT.md) and [`FINDINGS.md`](FINDINGS.md), not silently smuggled in from the implementation.

## Exclusions from intent

- The frozen Claude Code source is **not** treated as the specification by itself.
- Inline demos/tests are evidence, not an oracle when they conflict with the prompt/default intent.
- Proof conveniences are not accepted as intent unless justified here or in the public evidence ledger.
