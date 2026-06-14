# Intent spec — `gcd.py`

This file is the intent-only side of the FVK adequacy round-trip for `05-gcd`. It
records what the public prompt/default domain conventions require **before** accepting
any behavior merely because the current implementation exhibits it.

## Public prompt

> Write `gcd(a, b)` returning the greatest common divisor of two non-negative integers via the Euclidean algorithm (`while b: a, b = b, a % b`). Self-contained — operators only.

## Intended public obligations

- **Primary obligation:** `gcd(a,b)` should return the non-negative greatest common divisor of two non-negative integers.
- **Program shape requested by intent:** self-contained source, with the algorithmic shape stated in the prompt where present.
- **Public API under specification:** `gcd` in [`gcd.py`](gcd.py).
- **Default domain assumptions:** ordinary mathematical values for the operation being specified; any narrower precondition, ambiguity, or proof-required condition is made explicit in [`SPEC_AUDIT.md`](SPEC_AUDIT.md) and [`FINDINGS.md`](FINDINGS.md), not silently smuggled in from the implementation.

## Exclusions from intent

- The frozen Claude Code source is **not** treated as the specification by itself.
- Inline demos/tests are evidence, not an oracle when they conflict with the prompt/default intent.
- Proof conveniences are not accepted as intent unless justified here or in the public evidence ledger.
