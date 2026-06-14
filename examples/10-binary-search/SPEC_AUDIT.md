# Spec adequacy audit — `binary_search.py`

This file performs the adequacy round-trip required by the current FVK protocol:

`INTENT_SPEC.md` → [`binary-search-spec.k`](binary-search-spec.k) K claims →
`FORMAL_SPEC_ENGLISH.md` → this audit.

## Round-trip checks

| Check | Status | Evidence / note |
|---|---|---|
| Prompt obligation represented | PASS | P1 obligation is recorded in [`INTENT_SPEC.md`](INTENT_SPEC.md) and encoded by the claim provenance in [`binary-search-spec.k`](binary-search-spec.k). |
| Program-specific claim naming | PASS | Claims live in [`binary-search-spec.k`](binary-search-spec.k); [`mini-python.k`](mini-python.k) is only the mini-Python semantics. |
| Public evidence traceability | PASS | [`PUBLIC_EVIDENCE_LEDGER.md`](PUBLIC_EVIDENCE_LEDGER.md), [`SPEC.md`](SPEC.md), and `SPEC-PROVENANCE` comments provide the trace. |
| Implementation-as-spec risk | PASS WITH FINDINGS | The source is treated as the candidate implementation. Mismatches/ambiguities remain findings rather than being normalized away. |
| Proof scope honesty | PASS WITH FINDINGS | Constructed/not-machine-checked and escalation/side-condition boundaries are retained in [`PROOF.md`](PROOF.md). |
| Public compatibility | PASS / N/A | No source/API repair is performed in this frozen example; see [`PUBLIC_COMPATIBILITY_AUDIT.md`](PUBLIC_COMPATIBILITY_AUDIT.md). |

## Findings and ambiguities carried forward

- Finding 1 — missing precondition: elements must form a total order (NaN / mixed types)
- Finding 2 — the `mid = (lo + hi) // 2` midpoint: NO overflow in Python, but the famous C/Java overflow bug
- Finding 3 — the unstated **sortedness precondition** (real bug on unsorted input)
- Finding 4 — spec-difficulty signal: the load-bearing invariant side conditions
- Finding 5 — duplicates: returns *some* matching index, not a specific one
- Finding 6 — spec-difficulty = ESCALATION signal: the **not-present** half is beyond the bundled fast path (NOT a code bug)
- Finding 7 — corner cases that are handled correctly (deliberate non-findings)
- Note — termination (partial vs total correctness)

These items are not hidden by the K proof. They are the protocol-approved feedback for
the next FVK-guided repair or intent-clarification iteration.
