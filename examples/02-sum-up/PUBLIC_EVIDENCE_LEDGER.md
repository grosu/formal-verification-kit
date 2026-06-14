# Public evidence ledger — `sum.py`

This ledger is the standalone companion to the shorter ledger embedded in
[`SPEC.md`](SPEC.md). Critical entries are mirrored as `SPEC-PROVENANCE` comments in
[`sum-up-spec.k`](sum-up-spec.k).

| ID | Source | Evidence | Obligation / use | Status |
|---|---|---|---|---|
| P1 | prompt | `Write a simple Python program that sums the numbers from 1 to n. Call it sum. Take an integer n. Use a while loop counting UP from 1 to n.` | `sum_to_n(n)` should compute `1 + ... + n` using an increasing counter on the intended non-negative domain. | Intent source for the function contract(s). |
| API | public symbol/name | `sum_to_n` in [`sum.py`](sum.py) | The named public function(s) are the verified unit(s). | Encoded by the program-specific claim file. |
| SEM | implementation shape | The frozen source determines which mini-Python constructs the semantics must cover. | Used only to model execution in [`mini-python.k`](mini-python.k), not to weaken intent. | Implementation-derived modeling evidence. |
| FVK | findings/proof scope | [`FINDINGS.md`](FINDINGS.md) and [`PROOF.md`](PROOF.md) record missing preconditions, ambiguities, and escalation boundaries. | Must be surfaced to the next repair/spec iteration. | Audited in [`SPEC_AUDIT.md`](SPEC_AUDIT.md). |

## Notes

The program source remains frozen as the pre-repair artifact. This ledger exists so a
future `/formalize` or `/verify` pass can check adequacy without mining intent from prose
scattered across the other files.
