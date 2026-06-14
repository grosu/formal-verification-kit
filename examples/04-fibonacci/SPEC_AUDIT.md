# Spec adequacy audit — `fib.py`

This file performs the adequacy round-trip required by the current FVK protocol:

`INTENT_SPEC.md` → [`fibonacci-spec.k`](fibonacci-spec.k) K claims →
`FORMAL_SPEC_ENGLISH.md` → this audit.

## Round-trip checks

| Check | Status | Evidence / note |
|---|---|---|
| Prompt obligation represented | PASS | P1 obligation is recorded in [`INTENT_SPEC.md`](INTENT_SPEC.md) and encoded by the claim provenance in [`fibonacci-spec.k`](fibonacci-spec.k). |
| Program-specific claim naming | PASS | Claims live in [`fibonacci-spec.k`](fibonacci-spec.k); [`mini-python.k`](mini-python.k) is only the mini-Python semantics. |
| Public evidence traceability | PASS | [`PUBLIC_EVIDENCE_LEDGER.md`](PUBLIC_EVIDENCE_LEDGER.md), [`SPEC.md`](SPEC.md), and `SPEC-PROVENANCE` comments provide the trace. |
| Implementation-as-spec risk | PASS WITH FINDINGS | The source is treated as the candidate implementation. Mismatches/ambiguities remain findings rather than being normalized away. |
| Proof scope honesty | PASS WITH FINDINGS | Constructed/not-machine-checked and escalation/side-condition boundaries are retained in [`PROOF.md`](PROOF.md). |
| Public compatibility | PASS / N/A | No source/API repair is performed in this frozen example; see [`PUBLIC_COMPATIBILITY_AUDIT.md`](PUBLIC_COMPATIBILITY_AUDIT.md). |

## Findings and ambiguities carried forward

- Finding 1 — missing precondition `n >= 0` (negative input returns a meaningless `0`)
- Finding 2 — POSITIVE: the iterative form is O(n), not exponential (a real strength)
- Finding 3 — spec-difficulty signal: the side condition `0 <= I <= N`
- Finding 4 — no overflow corner case (a deliberate non-finding)
- Note — termination (partial vs total correctness)

These items are not hidden by the K proof. They are the protocol-approved feedback for
the next FVK-guided repair or intent-clarification iteration.
