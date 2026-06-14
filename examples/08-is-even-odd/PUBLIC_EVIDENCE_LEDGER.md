# Public evidence ledger — `even_odd.py`

This ledger is the standalone companion to the shorter ledger embedded in
[`SPEC.md`](SPEC.md). Critical entries are mirrored as `SPEC-PROVENANCE` comments in
[`is-even-odd-spec.k`](is-even-odd-spec.k).

| ID | Source | Evidence | Obligation / use | Status |
|---|---|---|---|---|
| P1 | prompt | `Write two mutually recursive functions for n>=0: `is_even(n)` and `is_odd(n)` (is_even(0)=True, is_odd(0)=False; is_even(n)=is_odd(n-1), is_odd(n)=is_even(n-1)). Self-contained.` | `is_even` and `is_odd` should decide parity for non-negative integers using mutual recursion. | Intent source for the function contract(s). |
| API | public symbol/name | `is_even`, `is_odd` in [`even_odd.py`](even_odd.py) | The named public function(s) are the verified unit(s). | Encoded by the program-specific claim file. |
| SEM | implementation shape | The frozen source determines which mini-Python constructs the semantics must cover. | Used only to model execution in [`mini-python.k`](mini-python.k), not to weaken intent. | Implementation-derived modeling evidence. |
| FVK | findings/proof scope | [`FINDINGS.md`](FINDINGS.md) and [`PROOF.md`](PROOF.md) record missing preconditions, ambiguities, and escalation boundaries. | Must be surfaced to the next repair/spec iteration. | Audited in [`SPEC_AUDIT.md`](SPEC_AUDIT.md). |

## Notes

The program source remains frozen as the pre-repair artifact. This ledger exists so a
future `/formalize` or `/verify` pass can check adequacy without mining intent from prose
scattered across the other files.
