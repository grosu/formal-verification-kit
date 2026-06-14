# Intent spec — `tree_height.py`

This file is the intent-only side of the FVK adequacy round-trip for `13-tree-height`. It
records what the public prompt/default domain conventions require **before** accepting
any behavior merely because the current implementation exhibits it.

## Public prompt

> Write `tree_height(t)` for a binary tree (`None`, or a `(value, left, right)` tuple), recursively. Use your own `max2` helper (no `max`). Self-contained.

## Intended public obligations

- **Primary obligation:** `tree_height(t)` should return the height of a finite well-formed binary tree; helper `max2` should return the larger of two heights.
- **Program shape requested by intent:** self-contained source, with the algorithmic shape stated in the prompt where present.
- **Public API under specification:** `max2`, `tree_height` in [`tree_height.py`](tree_height.py).
- **Default domain assumptions:** ordinary mathematical values for the operation being specified; any narrower precondition, ambiguity, or proof-required condition is made explicit in [`SPEC_AUDIT.md`](SPEC_AUDIT.md) and [`FINDINGS.md`](FINDINGS.md), not silently smuggled in from the implementation.

## Exclusions from intent

- The frozen Claude Code source is **not** treated as the specification by itself.
- Inline demos/tests are evidence, not an oracle when they conflict with the prompt/default intent.
- Proof conveniences are not accepted as intent unless justified here or in the public evidence ledger.
