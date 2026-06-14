# factorial(n) — formally specified & verified

> **Authenticity / repair-loop note.** The source program here is the frozen, no-human-touch `.py` output vibe-coded by **Claude Code Opus 4.8 (`opus-4-8`)** from the prompt in `PROMPTS.md`. This example shows the FVK audit/evidence phase before repair: FVK formalizes, proves or hits escalation boundaries, and reports Findings. In normal use, the coding agent then uses those FVK artifacts to repair the code; this corpus keeps the pre-repair source frozen so the Findings remain visible.


**Status:** constructed (escalation-bounded)

Recursive factorial with a `ValueError` guard for `n<0`. Because `n!` has no polynomial closed form, the postcondition uses a spec-only recursive symbol `fact(n)`; the base and recursive-step VCs are `fact`'s own defining equations (definitional unfolding). The `(REC)` recursion circularity discharges the recursive call.

**Demonstrates:** **Recursion** + a **non-polynomial** result — a spec-only recursive `fact` symbol; the VCs reduce to `fact`'s own defining equations (definitional, cleaner than `sum-recursive` — no exact-halving lemma).

**Key findings:** `n<0` is enforced (a positive finding); recursion-depth limit at n=999; no overflow in Python but a C/Java port overflows at factorial(21). Only `fact`'s totality escalates.

| File | What it is |
|---|---|
| [`factorial.py`](factorial.py) | the program — **self-contained** (no libraries or builtins) |
| [`test_factorial.py`](test_factorial.py) | a small test suite |
| [`mini-python.k`](mini-python.k) | minimal K semantics of just the constructs it uses |
| [`factorial-spec.k`](factorial-spec.k) | the K reachability claims (contract + circularities) |
| [`SPEC.md`](SPEC.md) | plain-English spec note |
| [`FINDINGS.md`](FINDINGS.md) | the Findings (bugs / preconditions / corner cases) |
| [`PROOF.md`](PROOF.md) | the constructed proof + test-redundancy report |
| [`PROMPTS.md`](PROMPTS.md) | the prompts that reproduce this example |

Produced cold by an isolated newcomer — see the kit's
[examples/README.md](../README.md) -> *How examples are produced*.


## Protocol adequacy artifacts

This example follows the current adequacy round-trip explicitly:

- [`INTENT_SPEC.md`](INTENT_SPEC.md) — prompt/default-domain intent before accepting implementation behavior.
- [`PUBLIC_EVIDENCE_LEDGER.md`](PUBLIC_EVIDENCE_LEDGER.md) — public evidence ledger mirrored by `SPEC-PROVENANCE` comments.
- [`factorial-spec.k`](factorial-spec.k) — program-specific K claims for `factorial`; [`mini-python.k`](mini-python.k) is only the mini-Python semantics.
- [`FORMAL_SPEC_ENGLISH.md`](FORMAL_SPEC_ENGLISH.md) — English paraphrase of the claims and proof scope.
- [`SPEC_AUDIT.md`](SPEC_AUDIT.md) — intent-vs-formal-spec pass/fail/ambiguous audit.
- [`PUBLIC_COMPATIBILITY_AUDIT.md`](PUBLIC_COMPATIBILITY_AUDIT.md) — public callsite/API/override compatibility audit.
