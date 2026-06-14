# Spec adequacy audit — `insertion_sort.py`

This file performs the adequacy round-trip required by the current FVK protocol:

`INTENT_SPEC.md` → [`insertion-sort-spec.k`](insertion-sort-spec.k) K claims →
`FORMAL_SPEC_ENGLISH.md` → this audit.

## Round-trip checks

| Check | Status | Evidence / note |
|---|---|---|
| Prompt obligation represented | PASS | P1 obligation is recorded in [`INTENT_SPEC.md`](INTENT_SPEC.md) and encoded by the claim provenance in [`insertion-sort-spec.k`](insertion-sort-spec.k). |
| Program-specific claim naming | PASS | Claims live in [`insertion-sort-spec.k`](insertion-sort-spec.k); [`mini-python.k`](mini-python.k) is only the mini-Python semantics. |
| Public evidence traceability | PASS | [`PUBLIC_EVIDENCE_LEDGER.md`](PUBLIC_EVIDENCE_LEDGER.md), [`SPEC.md`](SPEC.md), and `SPEC-PROVENANCE` comments provide the trace. |
| Implementation-as-spec risk | PASS WITH FINDINGS | The source is treated as the candidate implementation. Mismatches/ambiguities remain findings rather than being normalized away. |
| Proof scope honesty | PASS WITH FINDINGS | Constructed/not-machine-checked and escalation/side-condition boundaries are retained in [`PROOF.md`](PROOF.md). |
| Public compatibility | PASS / N/A | No source/API repair is performed in this frozen example; see [`PUBLIC_COMPATIBILITY_AUDIT.md`](PUBLIC_COMPATIBILITY_AUDIT.md). |

## Findings and ambiguities carried forward

- Finding 1 — missing precondition: elements must form a total order (real bug with NaN / mixed types)
- Finding 2 — spec-difficulty signal: the load-bearing invariant side conditions
- Finding 3 — stability hinges on the **strict** `>` in the inner guard (subtle, intent-relevant)
- Finding 4 — input IS mutated (in-place); the returned object is the input object
- Finding 5 — spec-difficulty = ESCALATION signal: sorting is beyond the bundled fast path (NOT a code bug)
- Finding 6 — corner cases that are handled correctly (deliberate non-findings)
- Note — termination (partial vs total correctness)

These items are not hidden by the K proof. They are the protocol-approved feedback for
the next FVK-guided repair or intent-clarification iteration.
