# Specification note — `reverse.py`

## Public intent ledger (protocol refresh)

This section makes the example conform to the current `/formalize` protocol: the
claim provenance is explicit before the formal claims, and the original source program
remains unchanged. The program under audit is `reverse.py`, preserved as the
exact Claude Code Opus 4.8 (`opus-4-8`) vibe-coded output from `PROMPTS.md`; FVK's
role in this example is to expose obligations and Findings before the repair iteration. In the full FVK loop, the coding agent uses this evidence to repair the code; this corpus preserves the pre-repair source so the issue remains visible.

- **I1 — prompt / public task statement**
  - Evidence: P1 in `PROMPTS.md`: "Write `reverse(a)` that reverses the list **in place** (two pointers, index swaps) and returns it. Self-contained — no slicing/`.insert`/`list()`."
  - Obligation: `reverse(a)` should mutate the list in place so returned positions mirror the original positions, preserving the same elements.
  - Status: encoded in the function contract(s) and, where needed, the loop/recursion circularity.
- **I2 — implementation shape being audited**
  - Evidence: `reverse.py`: The code swaps `a[i]` and `a[j]` while moving two pointers inward, then returns `a`.
  - Obligation: the mini-Python semantics and proof obligations model this control/data-flow shape.
  - Status: encoded in `mini-python.k` and `mini-python-spec.k`; the source program is intentionally not rewritten.
- **I3 — FVK finding / conflict signal**
  - Evidence: `FINDINGS.md`: FVK records mutation as a behavioral contract point and notes that no total-order precondition is needed; permutation preservation is escalation-bounded.
  - Obligation: keep the issue visible as next-iteration feedback instead of weakening the spec or silently fixing the code during the provenance refresh.
  - Status: reported in `FINDINGS.md` / `PROOF.md`; source repair is deferred to the next explicit FVK-guided coding iteration, while this example refresh preserves the original source.
- **I4 — proof-scope / escalation evidence**
  - Evidence: `PROOF.md` and `[ESCALATION BOUNDARY]` notes where present.
  - Obligation: The index-relation part is the clean proof payload; multiset/permutation preservation is the explicit escalation boundary.
  - Status: constructed, not machine-checked; escalation boundaries are stated honestly rather than trusted.


Plain-English companion to the formal artifacts, for a developer who will never
open the `.k` files. Produced by the formal-verification-kit `/formalize` step.

- **Program:** [`reverse.py`](reverse.py) — `reverse(a)` reverses the list `a`
  **in place** using the classic **two-pointer swap**: a left pointer `i` starts
  at `0`, a right pointer `j` at `len(a) - 1`; while `i < j` it swaps `a[i]` and
  `a[j]` (through a temporary `tmp`), then moves the pointers inward (`i += 1`,
  `j -= 1`). It **returns the same list object** it mutated.
- **Artifacts:** [`mini-python.k`](mini-python.k) (the mini-X fragment semantics,
  over **lists**), [`mini-python-spec.k`](mini-python-spec.k) (two K `claim`s: the
  function contract `(REV)` and the loop circularity `(LOOP)`).
- **Status:** specs **constructed, not machine-checked** (the MVP does not run
  `kompile`/`kprove`). The Findings (see [`FINDINGS.md`](FINDINGS.md)) hold today
  regardless of machine-checking.
- **Default scope:** **partial correctness** — the contract constrains terminating
  runs; termination itself is a recommendation (see Findings), not proved.

> **Where this sits in the kit.** `reverse` is **between** the fast-path examples
> (`sum-up`: a polynomial closed form) and the escalation example
> (`insertion-sort`: a sorted permutation, two non-arithmetic predicates). Its
> contract splits into two halves of very different difficulty:
>
> - an **index relation + length** half — `out[i] = a_old[n-1-i]` for all `i`, and
>   `len(out) = len(a_old)` — which is **first-order over positions** and rests
>   only on the **bundled simplification tier** (in-bounds index facts, map/list
>   extensionality). This is the *clean* half, the analogue of `sum-up`'s closed
>   form.
> - a **permutation** half — `out` is a multiset-rearrangement of `a_old` — which
>   needs an inductive list/multiset (`Bag`) theory and hits the **same
>   `[ESCALATION BOUNDARY]`** as `insertion-sort`. It is flagged in the spec file
>   and itemized in [`FINDINGS.md`](FINDINGS.md) #6.
>
> A subtlety worth stating up front: the permutation half is **logically
> redundant** given the index-relation half (a length-preserving *bijection* of
> positions, `i ↦ n−1−i`, already makes `out` a rearrangement of `a_old`). We keep
> it in the contract for explicitness and parallelism with `insertion-sort`, but
> mechanizing "index bijection ⇒ multiset equality" is itself the inductive fact
> the bundled tier cannot close — hence still `[ESCALATION BOUNDARY]`.

## What is specified

### Function contract — `(REV)`

> **Precondition:** **none.** `reverse` **compares nothing** — it only moves
> elements by position — so unlike `insertion_sort` there is **no total-order
> requirement** on the elements (no NaN / mixed-type hazard). Empty and singleton
> inputs are in-domain (the loop simply never runs).
> **Postcondition:** `reverse(a)` returns `R` with
> **(a)** `len(R) == len(a_old)` (same length),
> **(b)** `R[i] == a_old[n-1-i]` for every `i` (the **index relation**), and
> **(c)** `R` is a permutation of `a_old` (same multiset).

(a)+(b) together are the clean **(H-CLEAN)** half; (c) is the **(H-PERM)** half.
All three pin "the exact positional reversal of the input." Note (b) alone already
implies (a) and (c) — see the redundancy note above — but each is stated.

### Loop invariant — `(LOOP)` (the circularity)

> At the head of `while i < j`, with the original input named `A` and the current
> array `C`: the array is split into **three regions**, and the invariant tracks
> all three —
>
> - the **left band** `C[0:i]` has **already been reversed** — it mirrors `A`'s
>   tail: `C[k] = A[n-1-k]` for `k in [0, i)`;
> - the **right band** `C[j+1:n]` has **already been reversed** likewise;
> - the **untouched middle** `C[i:j+1]` still equals `A[i:j+1]`;
> - and **the two pointers are reflections about the centre**: `i + j = n - 1`.
>   This is the load-bearing arithmetic side condition — each step does `i += 1;
>   j -= 1`, which **keeps `i + j` constant** at `n - 1`, so the two bands always
>   grow symmetrically and meet exactly in the middle. (Length is invariant: a swap
>   never changes `len`.)
>
> Running the loop to exit (`i >= j`) collapses the middle and leaves the **whole**
> array mirrored: `R[k] = A[n-1-k]` for all `k`, same length, same multiset.

Generalized over the array value and the two pointers (not pinned to entry
values), this is the loop's reachability claim; K's prover uses it as its own
coinduction hypothesis, so it **discharges its own loop**. The "two reversed bands
that grow toward the centre" plays the role a hand-written invariant used to.

## How the function proof composes (for `/verify`)

`def` files the body into `<funcs>` → `call` binds `a = A` in a fresh scope (the
**in-place** mutation is modeled as repeated rebinding of the single store binding
`a |-> L`, because K's `List` is a *value* sort) → `i = 0` → `j = len(a) - 1`
(`= n-1`) → **apply `(LOOP)` at `{C := A, I := 0, J := n-1}`**; its precondition
holds trivially at entry: `I+J = n-1` (centre reflection, base case), both bands
empty (`isMirror(A,A,0,0)` / `isMirror(A,A,n,n)` vacuous), the middle is the whole
list (`seg(A,0,n) = seg(A,0,n)`), `bag(A) = bag(A)` → the loop yields the fully
mirrored list → `return a` delivers it → `out |-> R`.

So the lemma chain is **one level deep**: `(REV)` reuses `(LOOP)` — like the sum
example's `(SUM)` reuses `(LOOP)`, and one level shallower than `insertion-sort`'s
nested `(SORT)`→`(OUTER)`→`(INNER)`.

## Arithmetic / data the proof will need

- **Bundled (supplied here):** map extensionality
  `{M[K<-V] #Equals M[K<-V']} => {V #Equals V'}` (closes the post-store cell
  equality), plus linear index/centre facts for Z3 — `i + j = n-1`, in-bounds
  reads/writes of `a[i]`/`a[j]` (`0 <= i < j < n` on every iteration), and the
  per-position index equalities of `isMirror`. These are the **(H-CLEAN)** VCs and
  they discharge with the bundled tier.
- **Escalation boundary (stated, NOT bundled-derivable):**
  1. **(P1) multiset preservation under one swap** — `bag(L[i<-L[j]][j<-L[i]])`
     equals `bag(L)`; the engine of permutation across the loop. Needs a
     multiset/`Bag` theory with element delete/insert symmetry.
  Route per [`knowledge/sources.md`](../../../formal-verification-kit/knowledge/sources.md):
  **OOPSLA'20** (unified fixpoint reasoning over inductive data structures) and
  **LICS'19** (Matching μ-Logic). `/verify --refresh` re-fetches these.

## Mini-X semantics scope (only what the code touches)

Integer literals/names, `len`, index read `e[e]`, index assign `x[e]=e`, `+`, `-`,
`<` (the **only** comparison), `=`, `while`, `def`, `return`, call. **No `if`**,
**no `and`/`or`/`not`**, **no `*`/`/`**, **no `list()`/copy**, **no slices**, **no
exceptions**. Elements are modeled as `Int` — a *benign* restriction here, because
**reverse compares nothing** (it only needs a concrete value sort for the `bag`
abstraction; genericity is Finding 1, a positive finding). `reverse.py`'s spec
targets the **pure function** — the `__main__` self-test block is not modeled.

## Next step

Run the kit's **`/verify`** to construct the proof of `(REV)`/`(LOOP)`, emit the
`kompile`/`kprove` commands, and get the test-redundancy recommendation — and to
make the `[ESCALATION BOUNDARY]` permutation obligation concrete. Expect `/verify`
to land cleanly on the structure and the **(H-CLEAN)** index/length VCs, and to
**stop at the `[ESCALATION BOUNDARY]`** multiset lemma (Finding 6) — that stop is
the honest signal, not a failure.
