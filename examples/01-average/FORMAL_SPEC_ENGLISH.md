# Formal spec in English — `average.py`

This file is the English paraphrase of the program-specific K claims in
[`average-spec.k`](average-spec.k). The language-fragment semantics live separately in
[`mini-python.k`](mini-python.k); the `*-spec.k` file names the **program** being
specified, not the language.

## Claims / circularities

- **C1.** (LOOP) running-sum loop circularity over `total`, `i`, and `nums`.
- **C2.** (AVG) function contract: sum all elements and divide by `len(nums)` on `len(nums) >= 1`.

## Overall contract shape

The claims formalize the public obligation from [`INTENT_SPEC.md`](INTENT_SPEC.md):

> `average(nums)` should compute the arithmetic mean on the intended non-empty numeric-list domain; the loop should sum all elements and divide by the length.

Function-level claims state the precondition/postcondition for the public function(s).
Loop or recursive claims state the circularity/invariant needed to prove the function
claim by symbolic execution over [`mini-python.k`](mini-python.k).

## Proof scope

- Status remains **constructed, not machine-checked** unless a later K run returns `#Top`.
- Default scope is **partial correctness**: termination is documented or recommended separately unless a claim explicitly proves it.
- Any claim side condition that is narrower, ambiguous, implementation-derived, or beyond the bundled proof tier is tracked in [`SPEC_AUDIT.md`](SPEC_AUDIT.md), [`FINDINGS.md`](FINDINGS.md), and [`PROOF.md`](PROOF.md).
