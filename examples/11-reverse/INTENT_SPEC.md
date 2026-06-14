# Intent spec — `reverse.py`

This file is the intent-only side of the FVK adequacy round-trip for `11-reverse`. It
records what the public prompt/default domain conventions require **before** accepting
any behavior merely because the current implementation exhibits it.

## Public prompt

> Write `reverse(a)` that reverses the list **in place** (two pointers, index swaps) and returns it. Self-contained — no slicing/`.insert`/`list()`.

## Intended public obligations

- **Primary obligation:** `reverse(a)` should mutate the list in place so returned positions mirror the original positions, preserving the same elements.
- **Program shape requested by intent:** self-contained source, with the algorithmic shape stated in the prompt where present.
- **Public API under specification:** `reverse` in [`reverse.py`](reverse.py).
- **Default domain assumptions:** ordinary mathematical values for the operation being specified; any narrower precondition, ambiguity, or proof-required condition is made explicit in [`SPEC_AUDIT.md`](SPEC_AUDIT.md) and [`FINDINGS.md`](FINDINGS.md), not silently smuggled in from the implementation.

## Exclusions from intent

- The frozen Claude Code source is **not** treated as the specification by itself.
- Inline demos/tests are evidence, not an oracle when they conflict with the prompt/default intent.
- Proof conveniences are not accepted as intent unless justified here or in the public evidence ledger.
