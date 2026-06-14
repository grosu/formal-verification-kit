# Spec adequacy audit — `tree_height.py`

This file performs the adequacy round-trip required by the current FVK protocol:

`INTENT_SPEC.md` → [`tree-height-spec.k`](tree-height-spec.k) K claims →
`FORMAL_SPEC_ENGLISH.md` → this audit.

## Round-trip checks

| Check | Status | Evidence / note |
|---|---|---|
| Prompt obligation represented | PASS | P1 obligation is recorded in [`INTENT_SPEC.md`](INTENT_SPEC.md) and encoded by the claim provenance in [`tree-height-spec.k`](tree-height-spec.k). |
| Program-specific claim naming | PASS | Claims live in [`tree-height-spec.k`](tree-height-spec.k); [`mini-python.k`](mini-python.k) is only the mini-Python semantics. |
| Public evidence traceability | PASS | [`PUBLIC_EVIDENCE_LEDGER.md`](PUBLIC_EVIDENCE_LEDGER.md), [`SPEC.md`](SPEC.md), and `SPEC-PROVENANCE` comments provide the trace. |
| Implementation-as-spec risk | PASS WITH FINDINGS | The source is treated as the candidate implementation. Mismatches/ambiguities remain findings rather than being normalized away. |
| Proof scope honesty | PASS WITH FINDINGS | Constructed/not-machine-checked and escalation/side-condition boundaries are retained in [`PROOF.md`](PROOF.md). |
| Public compatibility | PASS / N/A | No source/API repair is performed in this frozen example; see [`PUBLIC_COMPATIBILITY_AUDIT.md`](PUBLIC_COMPATIBILITY_AUDIT.md). |

## Findings and ambiguities carried forward

- Finding 1 — `max2` is correct, including the tie case (a *positive* finding)
- Finding 2 — `tree_height` is correct on every well-formed tree (the core result)
- Finding 3 — recursion-depth limit: a real corner case (verified boundary)
- Finding 4 — the exact tuple shape is ASSUMED (out-of-domain inputs raise)
- Finding 5 — spec-difficulty / methodology signal: the recursive-DATA-STRUCTURE shape
- Finding 6 — no overflow; non-negative; well-defined (a deliberate non-finding)

These items are not hidden by the K proof. They are the protocol-approved feedback for
the next FVK-guided repair or intent-clarification iteration.
