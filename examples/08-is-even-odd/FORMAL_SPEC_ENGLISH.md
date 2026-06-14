# Formal spec in English — `even_odd.py`

This file is the English paraphrase of the program-specific K claims in
[`is-even-odd-spec.k`](is-even-odd-spec.k). The language-fragment semantics live separately in
[`mini-python.k`](mini-python.k); the `*-spec.k` file names the **program** being
specified, not the language.

## Claims / circularities

- **C1.** (EVEN) recursive-call circularity for `is_even(N)`.
- **C2.** (ODD) recursive-call circularity for `is_odd(N)`.
- **C3.** (EVENFN) user-facing contract for `is_even`.
- **C4.** (ODDFN) user-facing contract for `is_odd`.

## Overall contract shape

The claims formalize the public obligation from [`INTENT_SPEC.md`](INTENT_SPEC.md):

> `is_even` and `is_odd` should decide parity for non-negative integers using mutual recursion.

Function-level claims state the precondition/postcondition for the public function(s).
Loop or recursive claims state the circularity/invariant needed to prove the function
claim by symbolic execution over [`mini-python.k`](mini-python.k).

## Proof scope

- Status remains **constructed, not machine-checked** unless a later K run returns `#Top`.
- Default scope is **partial correctness**: termination is documented or recommended separately unless a claim explicitly proves it.
- Any claim side condition that is narrower, ambiguous, implementation-derived, or beyond the bundled proof tier is tracked in [`SPEC_AUDIT.md`](SPEC_AUDIT.md), [`FINDINGS.md`](FINDINGS.md), and [`PROOF.md`](PROOF.md).
