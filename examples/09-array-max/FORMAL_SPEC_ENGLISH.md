# Formal spec in English — `array_max.py`

This file is the English paraphrase of the program-specific K claims in
[`array-max-spec.k`](array-max-spec.k). The language-fragment semantics live separately in
[`mini-python.k`](mini-python.k); the `*-spec.k` file names the **program** being
specified, not the language.

## Claims / circularities

- **C1.** (LOOP) max-prefix loop circularity over the visited prefix.
- **C2.** (MAX) function contract returning a member that upper-bounds all elements.

## Overall contract shape

The claims formalize the public obligation from [`INTENT_SPEC.md`](INTENT_SPEC.md):

> `array_max(a)` should return an element that is a maximum of a non-empty list under a total order.

Function-level claims state the precondition/postcondition for the public function(s).
Loop or recursive claims state the circularity/invariant needed to prove the function
claim by symbolic execution over [`mini-python.k`](mini-python.k).

## Proof scope

- Status remains **constructed, not machine-checked** unless a later K run returns `#Top`.
- Default scope is **partial correctness**: termination is documented or recommended separately unless a claim explicitly proves it.
- Any claim side condition that is narrower, ambiguous, implementation-derived, or beyond the bundled proof tier is tracked in [`SPEC_AUDIT.md`](SPEC_AUDIT.md), [`FINDINGS.md`](FINDINGS.md), and [`PROOF.md`](PROOF.md).
