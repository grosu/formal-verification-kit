# Specification note — `sum_recursive.py`

## Public intent ledger (protocol refresh)

This section makes the example conform to the current `/formalize` protocol: the
claim provenance is explicit before the formal claims, and the original source program
remains unchanged. The program under audit is `sum_recursive.py`, preserved as the
exact Claude Code Opus 4.8 (`opus-4-8`) vibe-coded output from `PROMPTS.md`; FVK's
role in this example is to expose obligations and Findings before the repair iteration. In the full FVK loop, the coding agent uses this evidence to repair the code; this corpus preserves the pre-repair source so the issue remains visible.

- **I1 — prompt / public task statement**
  - Evidence: P1 in `PROMPTS.md`: "Let's write a very simple Python program which calculates the sum of numbers from 1 to n. Let's call it sum_recursive. It takes an input integer n. Do it with recursion, not a loop: the base case is `if n == 0: return 0`, and the recursive case is `return n + sum_recursive(n - 1)`. Validate the input: raise on n < 0, and reject bool (in Python bool is a subclass of int, so guard it explicitly)."
  - Obligation: `sum_recursive(n)` should compute `1 + ... + n` recursively for non-negative, non-bool integers, with invalid inputs rejected.
  - Status: encoded in the function contract(s) and, where needed, the loop/recursion circularity.
- **I2 — implementation shape being audited**
  - Evidence: `sum_recursive.py`: The code validates type/bool/negative cases and then uses the base case `n == 0` plus recursive case `n + sum_recursive(n-1)`.
  - Obligation: the mini-Python semantics and proof obligations model this control/data-flow shape.
  - Status: encoded in `mini-python.k` and `mini-python-spec.k`; the source program is intentionally not rewritten.
- **I3 — FVK finding / conflict signal**
  - Evidence: `FINDINGS.md`: Here the validation guards are positive findings: they enforce the domain FVK needs. The real residual issue is Python recursion depth for large `n`.
  - Obligation: keep the issue visible as next-iteration feedback instead of weakening the spec or silently fixing the code during the provenance refresh.
  - Status: reported in `FINDINGS.md` / `PROOF.md`; source repair is deferred to the next explicit FVK-guided coding iteration, while this example refresh preserves the original source.
- **I4 — proof-scope / escalation evidence**
  - Evidence: `PROOF.md` and `[ESCALATION BOUNDARY]` notes where present.
  - Obligation: The recursive-call contract `(REC)` is the circularity; no loop invariant is involved.
  - Status: constructed, not machine-checked; escalation boundaries are stated honestly rather than trusted.


Plain-English companion to the formal artifacts, for a developer who will never
open the `.k` files. Produced by the formal-verification-kit `/formalize` step.

- **Program:** [`sum_recursive.py`](sum_recursive.py) — `sum_recursive(n)` sums the
  integers `0..n` by **recursion** (`if n == 0: return 0; return n + sum_recursive(n - 1)`),
  guarded by type/value checks (`isinstance` / `n < 0` → raises).
- **Artifacts:** [`mini-python.k`](mini-python.k) (the mini-X fragment semantics),
  [`mini-python-spec.k`](mini-python-spec.k) (the two K `claim`s).
- **Status:** specs **constructed, not machine-checked** (the MVP does not run
  `kompile`/`kprove`). The Findings (see [`FINDINGS.md`](FINDINGS.md)) hold today
  regardless of machine-checking.
- **Default scope:** **partial correctness** — the contract constrains terminating
  runs; termination is a recommendation, not proved (and see Finding 3 — for this
  *recursive* function termination has a real implementation caveat).

## What is specified

### Function contract — `(SUM)`

> **Precondition:** `n >= 0` (and `n` a genuine `int`, not a `bool`).
> **Postcondition:** `sum_recursive(n) = n*(n+1)/2`.

For every non-negative `n`, the function returns the closed-form triangular number
`n*(n+1)/2`. Encoded as a reachability claim: from a configuration that *defines*
`sum_recursive` and *calls* it on a symbolic `N >= 0`, execution terminates with
`result |-> N*(N+1)/2`.

### Recursion circularity — `(REC)` (this example's distinctive claim)

> Evaluating a call `sum_recursive(N)` (with the function already defined, side
> condition `N >= 0`) reduces to the value `N*(N+1)/2`, threading the caller's
> continuation through and leaving the store and stack net-unchanged.

**This replaces the loop invariant of the `sum-up`/`sum-down` examples.** There is
no loop here, so there is **no `(LOOP)` claim**. Instead the *function's own
contract is the coinductive hypothesis*: K's reachability prover treats every claim
in the module as a circularity, so `(REC)` **discharges its own recursive call**
`sum_recursive(N-1)`. The closed form `N*(N+1)/2` plays the role the classical loop
invariant used to; the recursive call plays the role of the loop back-edge.

**Two things specific to this recursive program** (the recursion analog of the loop
examples' "two specifics"):

1. **The circularity is on the recursive call, not a loop.** Where `sum-up` proves
   a `(LOOP)` claim that re-enters the same `while`, here `(REC)` is a claim about a
   *call expression* in continuation-passing form (`sum_recursive(N) ~> CONT =>
   N*(N+1)/2 ~> CONT`), and the hypothesis is reused on the inner call
   `sum_recursive(N-1)`. **Guardedness** is paid by the `(call)` step that fires
   before the hypothesis is reused. This is exactly the kit's recursion-escalation
   case (circularity on the recursive call's contract).

2. **The side condition is the base-case bound `N >= 0`, and it is enforced, not
   assumed.** The recursion bottoms out at `n == 0`; for `N >= 1` the recursive
   branch is taken and `(REC)` is applied at `N-1` (precondition `N-1 >= 0` from
   `N >= 1`). Unlike `sum-up` (whose `n < 0` bug was *silent*), here `n >= 0` is
   **enforced at runtime** by the `if n < 0: raise ValueError` guard — so the
   missing-precondition finding becomes a *positive* one (see [`FINDINGS.md`](FINDINGS.md),
   Finding 1).

## How the function proof composes (for `/verify`)

`def` files the body → `result = sum_recursive(N)` evaluates the argument and the
call heats to the head of `<k>` → **apply `(REC)` at the symbolic `N`** (side
condition `N >= 0` is the function precondition) → the call delivers `N*(N+1)/2` →
the assignment lands `result |-> N*(N+1)/2`.

`(REC)` itself is proved by symbolic execution + coinduction: run the call one step
(the `(call)` rule — the genuine `=>⁺` step that earns the hypothesis), bind `n = N`
in a fresh scope, evaluate the guard `n == 0`, and case-split:

- **base (`N == 0`):** `if true: return 0` returns `0`, and `N*(N+1)/2 = 0`. ✓ (VC-BASE)
- **recursive (`N >= 1`):** the guard is false and falls through to
  `return n + sum_recursive(n - 1)`; the inner call is closed by **`(REC)` on
  `N-1`** giving `(N-1)*N/2`, then `n + …` makes `N + (N-1)*N/2`, which equals
  `N*(N+1)/2`. ✓ (VC-STEP)

## Arithmetic the proof will need

- **Map extensionality** `{M[K<-V] #Equals M[K<-V']} => {V #Equals V'}` — to close
  the post-store implication that pins `result`.
- **Exact-halving** lemma — the recursive step equates two symbolic products under
  truncating `/Int` (`N + (N-1)*N/2 = N*(N+1)/2`); since a product of consecutive
  integers is even, each halving is exact. Supplied as `[simplification]` rules in
  [`mini-python-spec.k`](mini-python-spec.k). The product being halved is `(N-1)*N`,
  i.e. `X*(X+1)` at `X = N-1`, so the simple consecutive-integer lemma carries it
  (the guarded sum-form lemma is included for robustness; cf. sum-up).

## Mini-X semantics scope (only what the in-domain core touches)

Integer literals/names, `+`, `-`, `==`, assignment, `if` (no `else`), `def`,
`return`, call. **No `while`**, **no `+=`**, **no `<=`/`<`** (the recursive core
uses none of them). **Set aside, deliberately:** the type/value **guard layer**
(`isinstance`, `not`/`or`, `raise TypeError`/`ValueError`) — Python exceptions are
an escalation case for this kit, and on the verified domain `n >= 0` those guards
are no-ops, so the modeled body is value-faithful (the guards only change behavior
*outside* the domain, where they raise — itself the subject of Finding 1). The
`if __name__ == "__main__"` demo (`print`/loop over a tuple) is I/O outside the
verified core and is intentionally **not** modeled.

## Next step

Run the kit's **`/verify`** to construct the proof of `(SUM)`/`(REC)`, emit the
`kompile`/`kprove` commands, and get the test-redundancy recommendation.
