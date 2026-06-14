# Public evidence ledger — `reverse.py`

This ledger is the standalone companion to the shorter ledger embedded in
[`SPEC.md`](SPEC.md). Critical entries are mirrored as `SPEC-PROVENANCE` comments in
[`reverse-spec.k`](reverse-spec.k).

| ID | Source | Evidence | Obligation / use | Status |
|---|---|---|---|---|
| P1 | prompt | `Write `reverse(a)` that reverses the list **in place** (two pointers, index swaps) and returns it. Self-contained — no slicing/`.insert`/`list()`.` | `reverse(a)` should mutate the list in place so returned positions mirror the original positions, preserving the same elements. | Intent source for the function contract(s). |
| API | public symbol/name | `reverse` in [`reverse.py`](reverse.py) | The named public function(s) are the verified unit(s). | Encoded by the program-specific claim file. |
| SEM | implementation shape | The frozen source determines which mini-Python constructs the semantics must cover. | Used only to model execution in [`mini-python.k`](mini-python.k), not to weaken intent. | Implementation-derived modeling evidence. |
| FVK | findings/proof scope | [`FINDINGS.md`](FINDINGS.md) and [`PROOF.md`](PROOF.md) record missing preconditions, ambiguities, and escalation boundaries. | Must be surfaced to the next repair/spec iteration. | Audited in [`SPEC_AUDIT.md`](SPEC_AUDIT.md). |

## Notes

The program source remains frozen as the pre-repair artifact. This ledger exists so a
future `/formalize` or `/verify` pass can check adequacy without mining intent from prose
scattered across the other files.
