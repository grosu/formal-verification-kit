# Specification note — `insertion_sort.py` (in-place)

## Public intent ledger (protocol refresh)

This section makes the example conform to the current `/formalize` protocol: the
claim provenance is explicit before the formal claims, and the original source program
remains unchanged. The program under audit is `insertion_sort.py`, preserved as the
exact Claude Code Opus 4.8 (`opus-4-8`) vibe-coded output from `PROMPTS.md`; FVK's
role in this example is to expose obligations and Findings before the repair iteration. In the full FVK loop, the coding agent uses this evidence to repair the code; this corpus preserves the pre-repair source so the issue remains visible.

- **I1 — prompt / public task statement**
  - Evidence: P1 in `PROMPTS.md`: "Write `insertion_sort(a)` that sorts the list **in place** (nested while loops, index assignment) and returns it. Self-contained — no `list()`/slicing/builtins."
  - Obligation: `insertion_sort(a)` should sort the same list in place, returning the mutated list as a sorted permutation of the input.
  - Status: encoded in the function contract(s) and, where needed, the loop/recursion circularity.
- **I2 — implementation shape being audited**
  - Evidence: `insertion_sort.py`: The code uses an outer index `i`, saves `key = a[i]`, shifts larger elements right in an inner loop, writes `key`, and returns `a`.
  - Obligation: the mini-Python semantics and proof obligations model this control/data-flow shape.
  - Status: encoded in `mini-python.k` and `mini-python-spec.k`; the source program is intentionally not rewritten.
- **I3 — FVK finding / conflict signal**
  - Evidence: `FINDINGS.md`: A total-order precondition is required (NaN/mixed types break it); strict `>` makes stability intent-relevant; mutation is a visible behavioral contract.
  - Obligation: keep the issue visible as next-iteration feedback instead of weakening the spec or silently fixing the code during the provenance refresh.
  - Status: reported in `FINDINGS.md` / `PROOF.md`; source repair is deferred to the next explicit FVK-guided coding iteration, while this example refresh preserves the original source.
- **I4 — proof-scope / escalation evidence**
  - Evidence: `PROOF.md` and `[ESCALATION BOUNDARY]` notes where present.
  - Obligation: Sortedness/permutation and nested-loop invariants are escalation-bounded rather than faked as trusted facts.
  - Status: constructed, not machine-checked; escalation boundaries are stated honestly rather than trusted.


Plain-English companion to the formal artifacts, for a developer who will never
open the `.k` files. Produced by the formal-verification-kit `/formalize` step.

- **Program:** [`insertion_sort.py`](insertion_sort.py) — `insertion_sort(a)`
  rearranges the list `a` **in place** into non-decreasing order and returns the
  same list, using the classic **two-nested-`while`-loop** insertion sort (outer
  loop walks `i` up the array; inner loop shifts larger elements right via index
  assignment to open a slot for `key = a[i]`). **There is no `list()` copy** — it
  mutates the caller's list.
- **Artifacts:** [`mini-python.k`](mini-python.k) (the mini-X fragment semantics,
  over **lists**, no `list()`), [`mini-python-spec.k`](mini-python-spec.k) (three K
  `claim`s: the function contract and the two loop circularities).
- **Status:** specs **constructed, not machine-checked** (the MVP does not run
  `kompile`/`kprove`). The Findings (see [`FINDINGS.md`](FINDINGS.md)) hold today
  regardless of machine-checking.
- **Default scope:** **partial correctness** — the contract constrains terminating
  runs; termination itself is a recommendation (see Findings), not proved.

> **Up front — this is a kit *escalation* target, not a fast-path one.** Every
> bundled `sum-*` example has a **polynomial closed-form** postcondition
> (`n*(n+1)/2`). Sorting does not. Its contract is two **non-arithmetic**
> predicates — *sortedness* and *permutation (multiset equality)* — over a
> **list**. The kit explicitly lists "array / list loop" as a roadmap shape and
> "recursive data structures / inductively-defined predicates" as an escalation
> case. So the claims below are **constructed at the fragment level and
> well-formed**, but some of their verification conditions need an inductive
> list/multiset theory the bundled simplification tier does not supply. Those are
> flagged `[ESCALATION BOUNDARY]` in the spec file and itemized in
> [`FINDINGS.md`](FINDINGS.md) #6. This honesty *is* the deliverable here.

> **This is the IN-PLACE variant.** The source prompt explicitly asks for in-place
> sorting (`PROMPTS.md` P1): there is no `result = list(array)` copy. The parameter
> `a` is **mutated**, and the returned object **is** the input object
> (`insertion_sort(x) is x`). The *value-level* contract is sorted permutation with
> equal length; the reference/aliasing behavior is recorded as a behavioral finding
> rather than hidden or repaired (Finding 4).

## What is specified

### Function contract — `(SORT)`

> **Precondition:** none beyond the model (elements are `Int`, which is totally
> ordered — see the modeling note and Finding 1).
> **Postcondition:** `insertion_sort(A)` returns `R` (the same list, now mutated)
> with **(a)** `len(R) == len(A)`, **(b)** `R` is sorted (non-decreasing), and
> **(c)** `R` is a permutation of `A` (same multiset of elements).

All three conjuncts are needed: (b) alone is met by `[]`; (c) alone is met by
returning `A` unchanged. Together they pin "sorted *rearrangement* of the input."
Because the sort is in place, `R` and the caller's list are the same sequence — the
postcondition simultaneously describes the return value and the final state of the
mutated input.

### Outer-loop invariant — `(OUTER)` (circularity #1)

> At the head of `while i < len(a)`, with `1 <= i <= len`: the prefix `a[0:i]` is
> **sorted**, and `a` as a whole is a **permutation** of the original input (length
> is invariant — insertion sort never grows or shrinks the array). Running the loop
> to exit (`i = len`) leaves the **whole** array sorted and still a permutation.

Generalized over the array value and the counter `i` (not pinned to entry
values), this is the loop's reachability claim; K's prover uses it as its own
coinduction hypothesis, so it **discharges its own loop**. The "sorted prefix that
grows by one each iteration" plays the role a hand-written invariant used to.

### Inner-loop invariant — `(INNER)` (circularity #2, the crux)

> At the head of `while j >= 0 and a[j] > key`, the array is in a **"hole"** state:
> positions `[0, j+1)` are the original sorted prefix (untouched); positions
> `[j+2, i]` hold the elements that have been **shifted one step right** (by the
> index assignment `a[j+1] = a[j]`) and are all `> key`; and position `j+1` is a
> *duplicate hole*. The key invariant is that **filling the hole with `key`
> recovers the entry multiset** — that is what makes the whole insert a
> permutation. The loop exits when it runs off the front (`j = -1`) or finds
> `a[j] <= key`; the following statement `a[j+1] = key` fills the hole, restoring
> both sortedness of `[0, i+1)` and the multiset.

This nested "insert into a hole" invariant is the genuinely intricate part, and is
exactly where multiset-preservation-under-a-shift and sorted-prefix-composition
arguments are required — the `[ESCALATION BOUNDARY]` obligations.

## How the function proof composes (for `/verify`)

`def` files the body → `call` binds `a = A` in a fresh scope → `i = 1` (NO
`list()` step — the body mutates `a` directly) → **apply `(OUTER)` at
`{B := A, I := 1}`**; its precondition `isSorted(take(A,1))` holds because any 0- or
1-element prefix is trivially sorted (the analogue of the sum example's `1 <= N+1`
following from `N >= 0`) → the loop yields a fully sorted permutation in `a` →
`return a` delivers it → `out |-> R`. Each outer iteration in turn **applies
`(INNER)` as a lemma** to perform one insertion.

So the lemma chain is **nested**: `(SORT)` reuses `(OUTER)` reuses `(INNER)` —
one level deeper than the sum example's `(SUM)` reuses `(LOOP)`. That extra nesting
is the teaching payload of this example (a *two-nested-loop* shape).

## Arithmetic / data the proof will need

- **Bundled (supplied here):** map extensionality
  `{M[K<-V] #Equals M[K<-V']} => {V #Equals V'}` (closes the post-store cell
  equality), plus linear index/bounds facts for Z3 (`1 <= I <= size`,
  `-1 <= J < I`, in-bounds index reads/writes). In particular the `j >= 0`
  short-circuit *before* `a[j]` makes every inner read in-bounds — a **linear**,
  bundled VC.
- **Escalation boundary (stated, NOT bundled-derivable):**
  1. **Multiset preservation under one index-update** — `bag(L[p<-v])` differs
     from `bag(L)` only by swapping one element; the engine of permutation across
     a shift. Needs a multiset/`Bag` theory with element delete.
  2. **Sorted-prefix composition** — a contiguous shifted block of a sorted list
     stays sorted, and `prefix ++ [key] ++ block` is sorted when
     `prefix <= key < block`. Needs inductive `isSorted`/`range` lemmas.
  Route per [`../../knowledge/sources.md`](../../knowledge/sources.md):
  **OOPSLA'20** (unified fixpoint reasoning over inductive data structures) and
  **LICS'19** (Matching mu-Logic). `/verify --refresh` re-fetches these.

## Mini-X semantics scope (only what the code touches)

Integer literals/names, `len`, index read `e[e]`, index assign `x[e]=e`, `+`, `-`,
`<`, `>`, `>=`, short-circuit `and`, `=`, `while`, `def`, `return`, call. **No
`list()`** (the in-place variant never copies), **no `if`**, **no `or`/`not`**, **no
`*`/`/`**, **no slices**, **no exceptions**. Elements are modeled as `Int` (faithful
restriction; genericity is Finding 1). The verified unit is the **pure function
only** — the `__main__` self-tests / `print` are not modeled.

## Next step

Run the kit's **`/verify`** to construct the proof of these claims, emit the
`kompile`/`kprove` commands, and get the test-redundancy recommendation — and to
make the `[ESCALATION BOUNDARY]` obligations concrete (it will get stuck exactly
there, which is itself the honest signal that this shape needs the inductive
theory above).
