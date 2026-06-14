# array_max(a) — formally specified & verified

> **Authenticity / repair-loop note.** The source program here is the frozen, no-human-touch `.py` output vibe-coded by **Claude Code Opus 4.8 (`opus-4-8`)** from the prompt in `PROMPTS.md`. This example shows the FVK audit/evidence phase before repair: FVK formalizes, proves or hits escalation boundaries, and reports Findings. In normal use, the coding agent then uses those FVK artifacts to repair the code; this corpus keeps the pre-repair source frozen so the Findings remain visible.


**Status:** constructed

A single index scan keeping the running maximum. The postcondition is universally quantified — `(forall j. a[j] <= result) and result in a` — proved with a `result = max of a[0:i)` loop invariant and spec-only `isUpperBound`/`inList` functions. A quantified predicate over a list, not a multiset, so it stays within the bundled tier (no escalation).

**Demonstrates:** Arrays with a **forall-quantified** postcondition (`isUpperBound` + membership) via a running-max loop invariant. **No escalation** — the gentle array example (contrast insertion-sort's multiset).

**Key findings:** `array_max([])` raises **IndexError** — the empty-list precondition; a total-order precondition (NaN/mixed types) the source never states.

| File | What it is |
|---|---|
| [`array_max.py`](array_max.py) | the program — **self-contained** (no libraries or builtins) |
| [`mini-python.k`](mini-python.k) | minimal K semantics of just the constructs it uses |
| [`array-max-spec.k`](array-max-spec.k) | the K reachability claims (contract + circularities) |
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
- [`array-max-spec.k`](array-max-spec.k) — program-specific K claims for `array max`; [`mini-python.k`](mini-python.k) is only the mini-Python semantics.
- [`FORMAL_SPEC_ENGLISH.md`](FORMAL_SPEC_ENGLISH.md) — English paraphrase of the claims and proof scope.
- [`SPEC_AUDIT.md`](SPEC_AUDIT.md) — intent-vs-formal-spec pass/fail/ambiguous audit.
- [`PUBLIC_COMPATIBILITY_AUDIT.md`](PUBLIC_COMPATIBILITY_AUDIT.md) — public callsite/API/override compatibility audit.
