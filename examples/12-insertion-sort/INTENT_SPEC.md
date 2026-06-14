# Intent spec — `insertion_sort.py`

This file is the intent-only side of the FVK adequacy round-trip for `12-insertion-sort`. It
records what the public prompt/default domain conventions require **before** accepting
any behavior merely because the current implementation exhibits it.

## Public prompt

> Write `insertion_sort(a)` that sorts the list **in place** (nested while loops, index assignment) and returns it. Self-contained — no `list()`/slicing/builtins.

## Intended public obligations

- **Primary obligation:** `insertion_sort(a)` should sort the same list in place, returning the mutated list as a sorted permutation of the input.
- **Program shape requested by intent:** self-contained source, with the algorithmic shape stated in the prompt where present.
- **Public API under specification:** `insertion_sort` in [`insertion_sort.py`](insertion_sort.py).
- **Default domain assumptions:** ordinary mathematical values for the operation being specified; any narrower precondition, ambiguity, or proof-required condition is made explicit in [`SPEC_AUDIT.md`](SPEC_AUDIT.md) and [`FINDINGS.md`](FINDINGS.md), not silently smuggled in from the implementation.

## Exclusions from intent

- The frozen Claude Code source is **not** treated as the specification by itself.
- Inline demos/tests are evidence, not an oracle when they conflict with the prompt/default intent.
- Proof conveniences are not accepted as intent unless justified here or in the public evidence ledger.
