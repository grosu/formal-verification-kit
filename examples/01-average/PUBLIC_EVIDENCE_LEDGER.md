# Public evidence ledger — `average.py`

This ledger is the standalone companion to the shorter ledger embedded in
[`SPEC.md`](SPEC.md). Critical entries are mirrored as `SPEC-PROVENANCE` comments in
[`average-spec.k`](average-spec.k).

| ID | Source | Evidence | Obligation / use | Status |
|---|---|---|---|---|
| P1 | prompt | `Write `average(nums)` returning the arithmetic mean of a non-empty list of numbers. Self-contained: sum with your own `while` loop and divide by `len` — no `sum()` or other builtins.` | `average(nums)` should compute the arithmetic mean on the intended non-empty numeric-list domain; the loop should sum all elements and divide by the length. | Intent source for the function contract(s). |
| API | public symbol/name | `average` in [`average.py`](average.py) | The named public function(s) are the verified unit(s). | Encoded by the program-specific claim file. |
| SEM | implementation shape | The frozen source determines which mini-Python constructs the semantics must cover. | Used only to model execution in [`mini-python.k`](mini-python.k), not to weaken intent. | Implementation-derived modeling evidence. |
| FVK | findings/proof scope | [`FINDINGS.md`](FINDINGS.md) and [`PROOF.md`](PROOF.md) record missing preconditions, ambiguities, and escalation boundaries. | Must be surfaced to the next repair/spec iteration. | Audited in [`SPEC_AUDIT.md`](SPEC_AUDIT.md). |

## Notes

The program source remains frozen as the pre-repair artifact. This ledger exists so a
future `/formalize` or `/verify` pass can check adequacy without mining intent from prose
scattered across the other files.
