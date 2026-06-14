# Spec adequacy audit — `reverse.py`

This file performs the adequacy round-trip required by the current FVK protocol:

`INTENT_SPEC.md` → [`reverse-spec.k`](reverse-spec.k) K claims →
`FORMAL_SPEC_ENGLISH.md` → this audit.

## Round-trip checks

| Check | Status | Evidence / note |
|---|---|---|
| Prompt obligation represented | PASS | P1 obligation is recorded in [`INTENT_SPEC.md`](INTENT_SPEC.md) and encoded by the claim provenance in [`reverse-spec.k`](reverse-spec.k). |
| Program-specific claim naming | PASS | Claims live in [`reverse-spec.k`](reverse-spec.k); [`mini-python.k`](mini-python.k) is only the mini-Python semantics. |
| Public evidence traceability | PASS | [`PUBLIC_EVIDENCE_LEDGER.md`](PUBLIC_EVIDENCE_LEDGER.md), [`SPEC.md`](SPEC.md), and `SPEC-PROVENANCE` comments provide the trace. |
| Implementation-as-spec risk | PASS WITH FINDINGS | The source is treated as the candidate implementation. Mismatches/ambiguities remain findings rather than being normalized away. |
| Proof scope honesty | PASS WITH FINDINGS | Constructed/not-machine-checked and escalation/side-condition boundaries are retained in [`PROOF.md`](PROOF.md). |
| Public compatibility | PASS / N/A | No source/API repair is performed in this frozen example; see [`PUBLIC_COMPATIBILITY_AUDIT.md`](PUBLIC_COMPATIBILITY_AUDIT.md). |

## Findings and ambiguities carried forward

- Finding 1 — NO total-order precondition (a positive finding: reverse compares nothing)
- Finding 2 — O(n) in place (a positive finding: contrast the earlier O(n^2) version)
- Finding 3 — spec-difficulty signal: the load-bearing centre-reflection side condition
- Finding 4 — it MUTATES its input (a behavioral contract point — note this)
- Finding 5 — empty and single-element inputs are handled correctly (deliberate non-findings)
- Finding 6 — spec-difficulty = ESCALATION signal: the permutation half (NOT a code bug)
- Note — termination (partial vs total correctness)

These items are not hidden by the K proof. They are the protocol-approved feedback for
the next FVK-guided repair or intent-clarification iteration.
