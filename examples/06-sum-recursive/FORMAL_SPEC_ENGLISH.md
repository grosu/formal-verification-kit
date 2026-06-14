# Formal spec in English — `sum_recursive.py`

This file is the English paraphrase of the program-specific K claims in
[`sum-recursive-spec.k`](sum-recursive-spec.k). The language-fragment semantics live separately in
[`mini-python.k`](mini-python.k); the `*-spec.k` file names the **program** being
specified, not the language.

## Claims / circularities

- **C1.** (REC) recursive-call circularity for `sum_recursive(N)`.
- **C2.** (SUM) user-facing function contract `N*(N+1)/2` on the validated domain.

## Overall contract shape

The claims formalize the public obligation from [`INTENT_SPEC.md`](INTENT_SPEC.md):

> `sum_recursive(n)` should compute `1 + ... + n` recursively for non-negative, non-bool integers, with invalid inputs rejected.

Function-level claims state the precondition/postcondition for the public function(s).
Loop or recursive claims state the circularity/invariant needed to prove the function
claim by symbolic execution over [`mini-python.k`](mini-python.k).

## Proof scope

- Status remains **constructed, not machine-checked** unless a later K run returns `#Top`.
- Default scope is **partial correctness**: termination is documented or recommended separately unless a claim explicitly proves it.
- Any claim side condition that is narrower, ambiguous, implementation-derived, or beyond the bundled proof tier is tracked in [`SPEC_AUDIT.md`](SPEC_AUDIT.md), [`FINDINGS.md`](FINDINGS.md), and [`PROOF.md`](PROOF.md).
