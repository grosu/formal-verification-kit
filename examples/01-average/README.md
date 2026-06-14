# average(nums) — formally specified & verified

> **Authenticity / repair-loop note.** The source program here is the frozen, no-human-touch `.py` output vibe-coded by **Claude Code Opus 4.8 (`opus-4-8`)** from the prompt in `PROMPTS.md`. This example shows the FVK audit/evidence phase before repair: FVK formalizes, proves or hits escalation boundaries, and reports Findings. In normal use, the coding agent then uses those FVK artifacts to repair the code; this corpus keeps the pre-repair source frozen so the Findings remain visible.


**Status:** constructed (escalation-bounded)

`average(nums)` sums the list with an explicit `while` loop, then divides by its length. The contract has precondition `len(nums) >= 1` and postcondition `result = listsum(nums)/len`. Because the sum is an explicit loop (not the `sum()` builtin), the loop step VC is definitional and the proof is escalation-free apart from the mild totality of the spec-only `listsum` fold.

**Demonstrates:** Scalar-over-a-list with a **running-sum loop invariant** (`total = listsum(nums,0,i)`); the **bug-finding showcase**. Self-contained, so the step VC is definitional — no `sum()` builtin, no truncation escalation.

**Key findings:** `average([])` raises **ZeroDivisionError** — a missing precondition `len >= 1` (the headline bug); int-vs-float division (Python `/` is float, the model truncates).

| File | What it is |
|---|---|
| [`average.py`](average.py) | the program — **self-contained** (no libraries or builtins) |
| [`mini-python.k`](mini-python.k) | minimal K semantics of just the constructs it uses |
| [`mini-python-spec.k`](mini-python-spec.k) | the K reachability claims (contract + circularities) |
| [`SPEC.md`](SPEC.md) | plain-English spec note |
| [`FINDINGS.md`](FINDINGS.md) | the Findings (bugs / preconditions / corner cases) |
| [`PROOF.md`](PROOF.md) | the constructed proof + test-redundancy report |
| [`PROMPTS.md`](PROMPTS.md) | the prompts that reproduce this example |

Produced cold by an isolated newcomer — see the kit's
[examples/README.md](../README.md) -> *How examples are produced*.
