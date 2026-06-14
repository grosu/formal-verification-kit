# binary_search(a, x) — formally specified & verified

> **Authenticity / repair-loop note.** The source program here is the frozen, no-human-touch `.py` output vibe-coded by **Claude Code Opus 4.8 (`opus-4-8`)** from the prompt in `PROMPTS.md`. This example shows the FVK audit/evidence phase before repair: FVK formalizes, proves or hits escalation boundaries, and reports Findings. In normal use, the coding agent then uses those FVK artifacts to repair the code; this corpus keeps the pre-repair source frozen so the Findings remain visible.


**Status:** constructed (escalation-bounded)

Iterative binary search over a sorted list. Precondition `isSorted(a)`; the loop invariant narrows the window and maintains 'if x is in a then x is in a[lo:hi]'. The 'found' half (`return i => a[i]==x`) is bundled-tier clean; the 'not present' half (membership over a sorted list) needs an inductive/quantified array predicate.

**Demonstrates:** Arrays with a **sortedness precondition** (mirror of insertion-sort's postcondition) and a **narrowing-window** invariant. The found half is clean; the not-present/membership half escalates.

**Key findings:** `mid=(lo+hi)//2` — no overflow in Python, but the historic **C/Java overflow bug** on a fixed-width port; an unstated sortedness precondition (unsorted input gives a silent false negative).

| File | What it is |
|---|---|
| [`binary_search.py`](binary_search.py) | the program — **self-contained** (no libraries or builtins) |
| [`mini-python.k`](mini-python.k) | minimal K semantics of just the constructs it uses |
| [`binary-search-spec.k`](binary-search-spec.k) | the K reachability claims (contract + circularities) |
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
- [`binary-search-spec.k`](binary-search-spec.k) — program-specific K claims for `binary search`; [`mini-python.k`](mini-python.k) is only the mini-Python semantics.
- [`FORMAL_SPEC_ENGLISH.md`](FORMAL_SPEC_ENGLISH.md) — English paraphrase of the claims and proof scope.
- [`SPEC_AUDIT.md`](SPEC_AUDIT.md) — intent-vs-formal-spec pass/fail/ambiguous audit.
- [`PUBLIC_COMPATIBILITY_AUDIT.md`](PUBLIC_COMPATIBILITY_AUDIT.md) — public callsite/API/override compatibility audit.
