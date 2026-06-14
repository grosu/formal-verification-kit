# Intent spec — `fib.py`

This file is the intent-only side of the FVK adequacy round-trip for `04-fibonacci`. It
records what the public prompt/default domain conventions require **before** accepting
any behavior merely because the current implementation exhibits it.

## Public prompt

> Write `fib(n)` returning the n-th Fibonacci number (fib(0)=0, fib(1)=1) with an iterative `while` loop and two running values. Self-contained — no `range`/builtins.

## Intended public obligations

- **Primary obligation:** `fib(n)` should return the nth Fibonacci number for `n >= 0`, with `fib(0)=0` and `fib(1)=1`.
- **Program shape requested by intent:** self-contained source, with the algorithmic shape stated in the prompt where present.
- **Public API under specification:** `fib` in [`fib.py`](fib.py).
- **Default domain assumptions:** ordinary mathematical values for the operation being specified; any narrower precondition, ambiguity, or proof-required condition is made explicit in [`SPEC_AUDIT.md`](SPEC_AUDIT.md) and [`FINDINGS.md`](FINDINGS.md), not silently smuggled in from the implementation.

## Exclusions from intent

- The frozen Claude Code source is **not** treated as the specification by itself.
- Inline demos/tests are evidence, not an oracle when they conflict with the prompt/default intent.
- Proof conveniences are not accepted as intent unless justified here or in the public evidence ledger.
