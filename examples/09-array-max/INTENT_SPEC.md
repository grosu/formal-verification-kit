# Intent spec — `array_max.py`

This file is the intent-only side of the FVK adequacy round-trip for `09-array-max`. It
records what the public prompt/default domain conventions require **before** accepting
any behavior merely because the current implementation exhibits it.

## Public prompt

> Write `array_max(a)` returning the maximum element of a non-empty list, scanning with an index `while` loop. Self-contained — no `max`/slicing.

## Intended public obligations

- **Primary obligation:** `array_max(a)` should return an element that is a maximum of a non-empty list under a total order.
- **Program shape requested by intent:** self-contained source, with the algorithmic shape stated in the prompt where present.
- **Public API under specification:** `array_max` in [`array_max.py`](array_max.py).
- **Default domain assumptions:** ordinary mathematical values for the operation being specified; any narrower precondition, ambiguity, or proof-required condition is made explicit in [`SPEC_AUDIT.md`](SPEC_AUDIT.md) and [`FINDINGS.md`](FINDINGS.md), not silently smuggled in from the implementation.

## Exclusions from intent

- The frozen Claude Code source is **not** treated as the specification by itself.
- Inline demos/tests are evidence, not an oracle when they conflict with the prompt/default intent.
- Proof conveniences are not accepted as intent unless justified here or in the public evidence ledger.
