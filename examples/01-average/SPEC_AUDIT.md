# Spec adequacy audit — `average.py`

This file performs the adequacy round-trip required by the current FVK protocol:

`INTENT_SPEC.md` → [`average-spec.k`](average-spec.k) K claims →
`FORMAL_SPEC_ENGLISH.md` → this audit.

## Round-trip checks

| Check | Status | Evidence / note |
|---|---|---|
| Prompt obligation represented | PASS | P1 obligation is recorded in [`INTENT_SPEC.md`](INTENT_SPEC.md) and encoded by the claim provenance in [`average-spec.k`](average-spec.k). |
| Program-specific claim naming | PASS | Claims live in [`average-spec.k`](average-spec.k); [`mini-python.k`](mini-python.k) is only the mini-Python semantics. |
| Public evidence traceability | PASS | [`PUBLIC_EVIDENCE_LEDGER.md`](PUBLIC_EVIDENCE_LEDGER.md), [`SPEC.md`](SPEC.md), and `SPEC-PROVENANCE` comments provide the trace. |
| Implementation-as-spec risk | PASS WITH FINDINGS | The source is treated as the candidate implementation. Mismatches/ambiguities remain findings rather than being normalized away. |
| Proof scope honesty | PASS WITH FINDINGS | Constructed/not-machine-checked and escalation/side-condition boundaries are retained in [`PROOF.md`](PROOF.md). |
| Public compatibility | PASS / N/A | No source/API repair is performed in this frozen example; see [`PUBLIC_COMPATIBILITY_AUDIT.md`](PUBLIC_COMPATIBILITY_AUDIT.md). |

## Findings and ambiguities carried forward

- Finding 1 — missing precondition `len(nums) >= 1` — **ZeroDivisionError on `[]`** (the headline bug, executed)
- Finding 2 — the missing precondition is *load-bearing in the spec* (spec-difficulty = bug signal)
- Finding 3 — int-vs-float division: `/` is TRUE division, the model uses `/Int` (executed)
- Finding 4 — element-type genericity (a modeling restriction, stated)
- Finding 5 — the spec-only fold's *totality* is the lone `[ESCALATION BOUNDARY]` (a mild capability gap, not a code defect) — and the loop is otherwise escalation-FREE
- Finding 6 — the loop side condition `0 <= i <= n` is clean (a deliberate non-finding, contrast with sum-up)
- Note — termination (trivial here, easily total)

These items are not hidden by the K proof. They are the protocol-approved feedback for
the next FVK-guided repair or intent-clarification iteration.
