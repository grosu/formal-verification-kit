# Intent spec — `sum_recursive.py`

This file is the intent-only side of the FVK adequacy round-trip for `06-sum-recursive`. It
records what the public prompt/default domain conventions require **before** accepting
any behavior merely because the current implementation exhibits it.

## Public prompt

> Let's write a very simple Python program which calculates the sum of numbers from 1 to n. Let's call it sum_recursive. It takes an input integer n. Do it with recursion, not a loop: the base case is `if n == 0: return 0`, and the recursive case is `return n + sum_recursive(n - 1)`. Validate the input: raise on n < 0, and reject bool (in Python bool is a subclass of int, so guard it explicitly).

## Intended public obligations

- **Primary obligation:** `sum_recursive(n)` should compute `1 + ... + n` recursively for non-negative, non-bool integers, with invalid inputs rejected.
- **Program shape requested by intent:** self-contained source, with the algorithmic shape stated in the prompt where present.
- **Public API under specification:** `sum_recursive` in [`sum_recursive.py`](sum_recursive.py).
- **Default domain assumptions:** ordinary mathematical values for the operation being specified; any narrower precondition, ambiguity, or proof-required condition is made explicit in [`SPEC_AUDIT.md`](SPEC_AUDIT.md) and [`FINDINGS.md`](FINDINGS.md), not silently smuggled in from the implementation.

## Exclusions from intent

- The frozen Claude Code source is **not** treated as the specification by itself.
- Inline demos/tests are evidence, not an oracle when they conflict with the prompt/default intent.
- Proof conveniences are not accepted as intent unless justified here or in the public evidence ledger.
