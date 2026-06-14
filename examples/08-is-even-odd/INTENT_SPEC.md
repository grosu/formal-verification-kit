# Intent spec — `even_odd.py`

This file is the intent-only side of the FVK adequacy round-trip for `08-is-even-odd`. It
records what the public prompt/default domain conventions require **before** accepting
any behavior merely because the current implementation exhibits it.

## Public prompt

> Write two mutually recursive functions for n>=0: `is_even(n)` and `is_odd(n)` (is_even(0)=True, is_odd(0)=False; is_even(n)=is_odd(n-1), is_odd(n)=is_even(n-1)). Self-contained.

## Intended public obligations

- **Primary obligation:** `is_even` and `is_odd` should decide parity for non-negative integers using mutual recursion.
- **Program shape requested by intent:** self-contained source, with the algorithmic shape stated in the prompt where present.
- **Public API under specification:** `is_even`, `is_odd` in [`even_odd.py`](even_odd.py).
- **Default domain assumptions:** ordinary mathematical values for the operation being specified; any narrower precondition, ambiguity, or proof-required condition is made explicit in [`SPEC_AUDIT.md`](SPEC_AUDIT.md) and [`FINDINGS.md`](FINDINGS.md), not silently smuggled in from the implementation.

## Exclusions from intent

- The frozen Claude Code source is **not** treated as the specification by itself.
- Inline demos/tests are evidence, not an oracle when they conflict with the prompt/default intent.
- Proof conveniences are not accepted as intent unless justified here or in the public evidence ledger.
