# Specification note — `binary_search.py`

## Public intent ledger (protocol refresh)

This section makes the example conform to the current `/formalize` protocol: the
claim provenance is explicit before the formal claims, and the original source program
remains unchanged. The program under audit is `binary_search.py`, preserved as the
exact Claude Code Opus 4.8 (`opus-4-8`) vibe-coded output from `PROMPTS.md`; FVK's
role in this example is to expose obligations and Findings before the repair iteration. In the full FVK loop, the coding agent uses this evidence to repair the code; this corpus preserves the pre-repair source so the issue remains visible.

- **I1 — prompt / public task statement**
  - Evidence: P1 in `PROMPTS.md`: "Write `binary_search(a, x)` returning the index of `x` in a sorted list, or `-1` if absent. Iterative. Self-contained."
  - Obligation: `binary_search(a,x)` should return some index whose value is `x` when present in a sorted, totally ordered list, and `-1` when absent.
  - Status: encoded in the function contract(s) and, where needed, the loop/recursion circularity.
- **I2 — implementation shape being audited**
  - Evidence: `binary_search.py`: The code narrows `[lo, hi]` around `mid = (lo + hi) // 2`, returning on equality and moving either boundary otherwise.
  - Obligation: the mini-Python semantics and proof obligations model this control/data-flow shape.
  - Status: encoded in `mini-python.k` and `binary-search-spec.k`; the source program is intentionally not rewritten.
- **I3 — FVK finding / conflict signal**
  - Evidence: `FINDINGS.md`: Sortedness and total order are real preconditions; duplicate winner semantics are underspecified, and the not-present proof half is escalation-bounded.
  - Obligation: keep the issue visible as next-iteration feedback instead of weakening the spec or silently fixing the code during the provenance refresh.
  - Status: reported in `FINDINGS.md` / `PROOF.md`; source repair is deferred to the next explicit FVK-guided coding iteration, while this example refresh preserves the original source.
- **I4 — proof-scope / escalation evidence**
  - Evidence: `PROOF.md` and `[ESCALATION BOUNDARY]` notes where present.
  - Obligation: The window invariant is the main proof shape; Python avoids the classic fixed-width midpoint overflow bug but the finding is documented for portability.
  - Status: constructed, not machine-checked; escalation boundaries are stated honestly rather than trusted.


Plain-English companion to the formal artifacts, for a developer who will never
open the `.k` files. Produced by the formal-verification-kit `/formalize` step.

- **Program:** [`binary_search.py`](binary_search.py) — `binary_search(a, x)`
  returns the **index of `x`** in the **sorted** list `a`, or **`-1`** if `x` is
  not present. Classic iterative binary search: maintain a window `[lo, hi]`,
  inspect the midpoint `mid = (lo + hi) // 2`, and on each step either return
  (`a[mid] == x`), discard the lower half (`a[mid] < x` ⇒ `lo = mid + 1`), or
  discard the upper half (`a[mid] > x` ⇒ `hi = mid - 1`). When `lo > hi` the
  window is empty and the function returns `-1`.
- **Artifacts:** [`mini-python.k`](mini-python.k) (the mini-X fragment semantics,
  over **lists**, with `if/elif/else`, floor-division `//`, and tuple assignment),
  [`binary-search-spec.k`](binary-search-spec.k) (two K `claim`s: the function contract
  and the loop circularity).
- **Status:** specs **constructed, not machine-checked** (the MVP does not run
  `kompile`/`kprove`). The Findings (see [`FINDINGS.md`](FINDINGS.md)) hold today
  regardless of machine-checking.
- **Default scope:** **partial correctness** — the contract constrains terminating
  runs; termination itself is a recommendation (see Findings), not proved.

> **Up front — this splits into a CLEAN half and an ESCALATION half.** The bundled
> fast-path examples (`sum-up`, `sum-down`, `sum-recursive`) have a **polynomial
> closed-form** postcondition. Binary search does not: its postcondition is a
> *disjunction* —
> *either* it returns an index `i` with `a[i] == x` (the **found** half, which is
> **clean**: the return rule itself just checked `a[mid] == x`), *or* it returns
> `-1` and `x` is in **no** position of `a` (the **not-present** half, which is an
> **inductive / universally-quantified membership** statement over a sorted list).
> The found half discharges with the bundled tier; the not-present half needs an
> inductive list-membership theory the bundled simplification tier does not supply,
> and is flagged `[ESCALATION BOUNDARY]` in the spec file. This honesty *is* part of
> the deliverable.

## What is specified

### Function contract — `(SEARCH)`

> **Precondition:** `isSorted(a)` — `a` is in non-decreasing order. This is the
> **unstated** requirement the source silently assumes (Finding 3); on an unsorted
> list the result is meaningless. (Elements are modeled as `Int`, which is totally
> ordered — see the modeling note and Finding 1.)
> **Postcondition:** `binary_search(a, x)` returns `r` with **either**
> **(a)** `r == -1` **and** `x` occurs at no index of `a`, **or**
> **(b)** `0 <= r < len(a)` **and** `a[r] == x`.

Both disjuncts matter: (b) without (a) would not pin the `-1` behavior; (a) without
(b) would not pin the found behavior. Together they say "returns a *witnessing
index* if present, and a faithful `-1` if absent."

### Loop invariant — `(LOOP)` (circularity, the **narrowing window**)

> At the head of `while lo <= hi`, with `0 <= lo` and `hi < len(a)`, `isSorted(a)`
> still holding, and the **narrowing-window invariant**
>
> > **if `x` occurs anywhere in `a`, then `x` occurs in the current window
> > `a[lo : hi+1]`.**
>
> Running the loop to exit (or to an early `return`) lands in one of the two
> post-states above. Each iteration computes `mid = (lo + hi) // 2` and:
> `a[mid] == x` ⇒ **return `mid`** (found, clean); `a[mid] < x` ⇒ `lo = mid + 1`
> (the target, if present, is strictly above `mid`); `a[mid] > x` ⇒ `hi = mid - 1`
> (strictly below `mid`). Because `lo <= mid <= hi`, the window **strictly shrinks**
> every iteration — that is both the soundness shape and the termination measure
> `hi - lo + 1`.

Generalized over the window `(lo, hi)` and target `x` (not pinned to entry values),
this is the loop's reachability claim; K's prover uses it as its own coinduction
hypothesis, so it **discharges its own loop**. The "window that always contains `x`
if `x` is present, and shrinks each step" plays the role a hand-written invariant
used to.

## How the function proof composes (for `/verify`)

`def` files the body → `call` binds `a = A`, `x = X` in a fresh scope →
`lo, hi = 0, len(a) - 1` (tuple assignment) → **apply `(LOOP)` at
`{lo := 0, hi := size(A) - 1}`**; its precondition is the narrowing-window invariant
at entry, which is `inList(A, X) -> inWindow(A, 0, size-1, X)`, i.e. `inList ->
inList` — **trivially true** (the entry window is the whole list; the analogue of
the sum example's `1 <= N+1` from `N >= 0`) → the loop yields one of the two
post-states → `return` delivers `mid` or `-1` → `out |-> r`.

So the lemma chain mirrors the sum example's `(SUM)` reuses `(LOOP)` — one loop, one
circularity. The novelty over the arithmetic examples is the **disjunctive,
data-predicate postcondition**, not extra loop nesting.

## Arithmetic / data the proof will need

- **Bundled (supplied here):** map extensionality
  `{M[K<-V] #Equals M[K<-V']} => {V #Equals V'}` (closes the post-store cell
  equality for `out`); linear index/bounds facts for Z3 (`0 <= lo`, `hi < size`,
  `lo <= mid <= hi`, `mid = (lo+hi)//2` in range, the window strictly shrinks); and
  the **found half** `a[mid] == x ⇒ a[?r] == x` (a single index read + an `Int`
  equality, both in the bundled tier).
- **Escalation boundary (stated, NOT bundled-derivable):**
  1. **VC-M1 — window narrowing.** For a **sorted** list, `a[mid] < x` means `x`
     cannot lie in `a[lo : mid+1]`, so membership over `[lo, hi]` equals membership
     over `[mid+1, hi]` (symmetrically for `a[mid] > x`). This preserves the
     invariant across one prune. It needs sortedness combined with a
     quantified-membership cut on the discarded sub-window.
  2. **VC-M2 — empty window ⇒ absent.** When the loop exits with `lo > hi`, the
     invariant gives `inList(a, x) == inWindow(a, lo, hi, x)`, and an empty window
     forces `inWindow == false`, hence `x` occurs at **no** index of `a`. This
     **universally-quantified "x is absent"** conclusion is exactly what the bundled
     tier cannot discharge.
  Route per [`knowledge/sources.md`](../../../formal-verification-kit/knowledge/sources.md):
  **OOPSLA'20** (unified fixpoint reasoning over inductive data structures) and
  **LICS'19** (Matching μ-Logic) for the `μ`-defined / inductive membership predicate
  and its lemmas. `/verify --refresh` re-fetches these.

  > Note: the **empty-list** case (`a = []`) is **not** escalation — it is handled by
  > the base rule of `inWindow` (`lo > hi ⇒ false`): `len([]) - 1 = -1`, so `hi = -1`,
  > `0 <= -1` is false, the loop never runs, `-1` is returned, and
  > `inList([], x) = inWindow([], 0, -1, x) = false`. Only the *general* not-present
  > case (a non-empty sorted list where `x` is genuinely absent) needs M1/M2.

## Mini-X semantics scope (only what the code touches)

Integer literals/names, `len`, index **read** `e[e]` (no index *assign* — binary
search never writes the list), `+`, `-`, floor-division `//`, comparisons `==`, `<`,
`<=`, tuple assignment `x, y = e1, e2`, simple assignment `x = e`, `if/elif/else`
(`elif` desugars to a nested `if/else`), `while`, `def`, `return`, call. **No `*`**,
**no `and`/`or`/`not`**, **no slices**, **no exceptions**, **no index assign**.
Elements and the key are modeled as `Int` (faithful restriction; genericity is
Finding 1). `binary_search.py`'s `__main__` block is **inline tests**, not part of
the verified unit; the spec covers the **pure function** only.

## Next step

Run the kit's **`/verify`** to construct the proof of these claims, emit the
`kompile`/`kprove` commands, and get the test-redundancy recommendation — and to make
the `[ESCALATION BOUNDARY]` obligations concrete. Expect `/verify` to land cleanly on
the structure, the in-bounds/linear VCs, **and the entire found half**, and to **stop
at the not-present half** (VC-M1 narrowing, VC-M2 empty-window-absence) — that stop is
the honest signal that this shape needs the inductive membership theory above.
