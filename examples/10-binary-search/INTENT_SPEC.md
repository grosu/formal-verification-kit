# Intent spec — `binary_search.py`

This file is the intent-only side of the FVK adequacy round-trip for `10-binary-search`. It
records what the public prompt/default domain conventions require **before** accepting
any behavior merely because the current implementation exhibits it.

## Public prompt

> Write `binary_search(a, x)` returning the index of `x` in a sorted list, or `-1` if absent. Iterative. Self-contained.

## Intended public obligations

- **Primary obligation:** `binary_search(a,x)` should return some index whose value is `x` when present in a sorted, totally ordered list, and `-1` when absent.
- **Program shape requested by intent:** self-contained source, with the algorithmic shape stated in the prompt where present.
- **Public API under specification:** `binary_search` in [`binary_search.py`](binary_search.py).
- **Default domain assumptions:** ordinary mathematical values for the operation being specified; any narrower precondition, ambiguity, or proof-required condition is made explicit in [`SPEC_AUDIT.md`](SPEC_AUDIT.md) and [`FINDINGS.md`](FINDINGS.md), not silently smuggled in from the implementation.

## Exclusions from intent

- The frozen Claude Code source is **not** treated as the specification by itself.
- Inline demos/tests are evidence, not an oracle when they conflict with the prompt/default intent.
- Proof conveniences are not accepted as intent unless justified here or in the public evidence ledger.
