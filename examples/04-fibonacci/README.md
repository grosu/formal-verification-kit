# fib(n) — formally specified & verified

> **Authenticity / repair-loop note.** The source program here is the frozen, no-human-touch `.py` output vibe-coded by **Claude Code Opus 4.8 (`opus-4-8`)** from the prompt in `PROMPTS.md`. This example shows the FVK audit/evidence phase before repair: FVK formalizes, proves or hits escalation boundaries, and reports Findings. In normal use, the coding agent then uses those FVK artifacts to repair the code; this corpus keeps the pre-repair source frozen so the Findings remain visible.


**Status:** constructed (escalation-bounded)

An iterative two-variable Fibonacci. The postcondition uses a spec-only recursive symbol `fib(n)` (no closed form); the loop invariant couples the running pair to `fib(i), fib(i+1)`, so the step VC `fib(i)+fib(i+1)=fib(i+2)` discharges by `fib`'s own defining rule — definitional, no arithmetic lemma.

**Demonstrates:** **Coupled accumulators** — a loop invariant relating *two* variables to consecutive Fibonacci numbers; a spec-only recursive `fib` symbol whose defining rule discharges the step VC (definitional).

**Key findings:** `fib(n)` for `n<0` silently returns 0 (meaningless); the iterative form is O(n) where a naive recursive fib is exponential (a positive design finding). Only `fib`'s totality escalates.

| File | What it is |
|---|---|
| [`fib.py`](fib.py) | the program — **self-contained** (no libraries or builtins) |
| [`mini-python.k`](mini-python.k) | minimal K semantics of just the constructs it uses |
| [`mini-python-spec.k`](mini-python-spec.k) | the K reachability claims (contract + circularities) |
| [`SPEC.md`](SPEC.md) | plain-English spec note |
| [`FINDINGS.md`](FINDINGS.md) | the Findings (bugs / preconditions / corner cases) |
| [`PROOF.md`](PROOF.md) | the constructed proof + test-redundancy report |
| [`PROMPTS.md`](PROMPTS.md) | the prompts that reproduce this example |

Produced cold by an isolated newcomer — see the kit's
[examples/README.md](../README.md) -> *How examples are produced*.
