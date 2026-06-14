# Formal spec in English — `sum.py`

This file is the English paraphrase of the program-specific K claims in
[`sum-down-spec.k`](sum-down-spec.k). The language-fragment semantics live separately in
[`mini-python.k`](mini-python.k); the `*-spec.k` file names the **program** being
specified, not the language.

## Claims / circularities

- **C1.** (LOOP) count-down loop circularity with remaining-work closed form.
- **C2.** (SUM) function contract `N*(N+1)/2` for `N >= 0`.

## Overall contract shape

The claims formalize the public obligation from [`INTENT_SPEC.md`](INTENT_SPEC.md):

> `sum_to_n(n)` should compute `1 + ... + n` using a decreasing counter on the intended non-negative domain.

Function-level claims state the precondition/postcondition for the public function(s).
Loop or recursive claims state the circularity/invariant needed to prove the function
claim by symbolic execution over [`mini-python.k`](mini-python.k).

## Proof scope

- Status remains **constructed, not machine-checked** unless a later K run returns `#Top`.
- Default scope is **partial correctness**: termination is documented or recommended separately unless a claim explicitly proves it.
- Any claim side condition that is narrower, ambiguous, implementation-derived, or beyond the bundled proof tier is tracked in [`SPEC_AUDIT.md`](SPEC_AUDIT.md), [`FINDINGS.md`](FINDINGS.md), and [`PROOF.md`](PROOF.md).
