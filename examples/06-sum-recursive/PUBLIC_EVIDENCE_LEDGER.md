# Public evidence ledger — `sum_recursive.py`

This ledger is the standalone companion to the shorter ledger embedded in
[`SPEC.md`](SPEC.md). Critical entries are mirrored as `SPEC-PROVENANCE` comments in
[`sum-recursive-spec.k`](sum-recursive-spec.k).

| ID | Source | Evidence | Obligation / use | Status |
|---|---|---|---|---|
| P1 | prompt | `Let's write a very simple Python program which calculates the sum of numbers from 1 to n. Let's call it sum_recursive. It takes an input integer n. Do it with recursion, not a loop: the base case is `if n == 0: return 0`, and the recursive case is `return n + sum_recursive(n - 1)`. Validate the input: raise on n < 0, and reject bool (in Python bool is a subclass of int, so guard it explicitly).` | `sum_recursive(n)` should compute `1 + ... + n` recursively for non-negative, non-bool integers, with invalid inputs rejected. | Intent source for the function contract(s). |
| API | public symbol/name | `sum_recursive` in [`sum_recursive.py`](sum_recursive.py) | The named public function(s) are the verified unit(s). | Encoded by the program-specific claim file. |
| SEM | implementation shape | The frozen source determines which mini-Python constructs the semantics must cover. | Used only to model execution in [`mini-python.k`](mini-python.k), not to weaken intent. | Implementation-derived modeling evidence. |
| FVK | findings/proof scope | [`FINDINGS.md`](FINDINGS.md) and [`PROOF.md`](PROOF.md) record missing preconditions, ambiguities, and escalation boundaries. | Must be surfaced to the next repair/spec iteration. | Audited in [`SPEC_AUDIT.md`](SPEC_AUDIT.md). |

## Notes

The program source remains frozen as the pre-repair artifact. This ledger exists so a
future `/formalize` or `/verify` pass can check adequacy without mining intent from prose
scattered across the other files.
