# Spec adequacy audit — `even_odd.py`

This file performs the adequacy round-trip required by the current FVK protocol:

`INTENT_SPEC.md` → [`is-even-odd-spec.k`](is-even-odd-spec.k) K claims →
`FORMAL_SPEC_ENGLISH.md` → this audit.

## Round-trip checks

| Check | Status | Evidence / note |
|---|---|---|
| Prompt obligation represented | PASS | P1 obligation is recorded in [`INTENT_SPEC.md`](INTENT_SPEC.md) and encoded by the claim provenance in [`is-even-odd-spec.k`](is-even-odd-spec.k). |
| Program-specific claim naming | PASS | Claims live in [`is-even-odd-spec.k`](is-even-odd-spec.k); [`mini-python.k`](mini-python.k) is only the mini-Python semantics. |
| Public evidence traceability | PASS | [`PUBLIC_EVIDENCE_LEDGER.md`](PUBLIC_EVIDENCE_LEDGER.md), [`SPEC.md`](SPEC.md), and `SPEC-PROVENANCE` comments provide the trace. |
| Implementation-as-spec risk | PASS WITH FINDINGS | The source is treated as the candidate implementation. Mismatches/ambiguities remain findings rather than being normalized away. |
| Proof scope honesty | PASS WITH FINDINGS | Constructed/not-machine-checked and escalation/side-condition boundaries are retained in [`PROOF.md`](PROOF.md). |
| Public compatibility | PASS / N/A | No source/API repair is performed in this frozen example; see [`PUBLIC_COMPATIBILITY_AUDIT.md`](PUBLIC_COMPATIBILITY_AUDIT.md). |

## Findings and ambiguities carried forward

- Finding 1 — `n < 0` does NOT terminate: `n >= 0` is load-bearing for TERMINATION (the headline)
- Finding 2 — on the verified domain, the two functions are exact, total, and complementary (a positive finding)
- Finding 3 — recursion-depth limit: a real corner case (measured `n = 998`)
- Finding 4 — spec-difficulty / methodology signal: this is the MUTUAL-recursion shape
- Finding 5 — no overflow, no `bool`/type guard present (a deliberate non-finding + a watch-item)

These items are not hidden by the K proof. They are the protocol-approved feedback for
the next FVK-guided repair or intent-clarification iteration.
