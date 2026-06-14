# Findings report — `binary_search.py`

Plain-language findings from formalizing [`binary_search.py`](binary_search.py).
Each is `input → observed vs expected`. **Non-blocking** — this report never edits
or deletes your code; it is advice. These findings **do not** depend on
machine-checking the proof — they are solid today. The concrete cases below were
**executed** against the actual code (not just reasoned about).

The program:

```python
def binary_search(a, x):
    """Return the index of x in sorted list a, or -1 if x is not present."""
    lo, hi = 0, len(a) - 1
    while lo <= hi:
        mid = (lo + hi) // 2
        if a[mid] == x:
            return mid
        elif a[mid] < x:
            lo = mid + 1
        else:
            hi = mid - 1
    return -1
```

---

## Finding 1 — missing precondition: elements must form a total order (NaN / mixed types)

Writing a clean contract forces the question "what does `==`/`<` mean on the
elements?" The code silently assumes elements (and the key `x`) are **pairwise
comparable and totally ordered**. Two concrete ways that fails:

- **`float('nan')` poisons the order.** Every comparison with NaN is `False`, so
  the branch logic mis-routes and the search can miss a present value or report a
  wrong one. NaN cannot meaningfully sit in a "sorted" list at all.
- **Mixed incomparable types raise.** `binary_search([1, "a"], 1)` can raise
  `TypeError: '<' not supported between 'str' and 'int'` (Python 3). The function
  is only defined on a domain of mutually-orderable elements.

**Recommendation:** document/enforce "elements and `x` are mutually comparable and
totally ordered (no NaN)." The formal contract `(SEARCH)` makes this explicit by
**modeling elements as `Int`** (a total order); the gap between "generic element"
and "`Int`" is exactly this finding.

## Finding 2 — the `mid = (lo + hi) // 2` midpoint: NO overflow in Python, but the famous C/Java overflow bug

This is the headline cross-language finding. The midpoint is computed as
`(lo + hi) // 2`.

- **In Python: safe.** Python integers are arbitrary-precision, so `lo + hi` never
  overflows. Executed: `mid` of `(0, 2**62)` is `2305843009213693952` — exact, no
  wrap. Modeled faithfully as `divInt` (floor) in [`mini-python.k`](mini-python.k);
  on the non-negative indices here floor = truncate, so it is the true mathematical
  `floor((lo+hi)/2)`.
- **In C/Java: the historic bug.** This exact line is the subject of the famous
  *"Nearly All Binary Searches and Mergesorts Are Broken"* defect (Bloch, 2006): in
  a fixed-width signed integer type, `lo + hi` can **overflow** for large arrays
  (near `2^31` elements for 32-bit `int`), producing a **negative** `mid` and an
  out-of-bounds access or wrong result. The fix is `mid = lo + (hi - lo) // 2`,
  which never overflows.

**Why the formal lens surfaces it:** verifying the index `mid` stays in range
`[lo, hi]` forces the assumption "`lo + hi` does not wrap." That assumption is
*free* in Python (and in the K `Int` model, which is also unbounded), but it is a
**real silently-assumed precondition in C/Java**. **Recommendation:** in Python no
change is required; if this algorithm is ever ported to a fixed-width-integer
language, use `mid = lo + (hi - lo) // 2`. (A great teaching finding precisely
because the Python code is *correct* while the "same" line in C/Java is not.)

## Finding 3 — the unstated **sortedness precondition** (real bug on unsorted input)

The docstring says "index of x in **sorted** list a" — but nothing enforces it, and
**on an unsorted list the result is meaningless**: binary search can return `-1`
for an element that is *actually present*, or report a wrong index. This is the
direct analogue of the sum example's missing `n >= 0`. Executed:

| input | code returns (observed) | expected (linear search) | agree? |
|---|---|---|---|
| `binary_search([2, 5, 1, 9, 3], 2)` | `-1` | `0` (`2` is at index 0!) | ✗ **false negative** |
| `binary_search([2, 5, 1, 9, 3], 5)` | `-1` | `1` (`5` is at index 1!) | ✗ **false negative** |
| `binary_search([2, 5, 1, 9, 3], 3)` | `-1` | `4` (`3` is at index 4!) | ✗ **false negative** |
| `binary_search([3, 1, 2], 1)` | `1` | `1` | ✓ (accidental) |

`binary_search([2,5,1,9,3], 2)` returns `-1` even though `2` is present at index 0 —
a silent false negative. The function is **only correct for sorted `a`**.

**Recommendation:** document and/or enforce the precondition `a` is sorted. The
formal contract `(SEARCH)` makes this explicit with `requires isSorted(A)`; without
it the postcondition simply does not hold (this is the loop invariant's
load-bearing assumption — see Finding 4).

## Finding 4 — spec-difficulty signal: the load-bearing invariant side conditions

As in the sum example (`I <= N+1`), writing the loop circularity **forced** side
conditions not in the source text, each marking a real boundary:

- `(LOOP)` needs `0 <= lo` and `hi < len(a)` (window indices in range) plus the
  narrowing-window invariant *"if `x` is in `a`, it is in `a[lo : hi+1]`."* The
  in-range bounds are what guarantee **no IndexError**: `lo <= mid <= hi` keeps the
  read `a[mid]` inside `[0, len)` every iteration, and the updates `lo = mid+1` /
  `hi = mid-1` preserve `0 <= lo` / `hi < len`.
- `isSorted(a)` is the precondition that makes the *pruning* sound: discarding the
  half on the wrong side of `mid` is only correct because the list is ordered
  (Finding 3). Drop it and the invariant is false.

These are not bugs; they are the silent assumptions the formal lens surfaces.

## Finding 5 — duplicates: returns *some* matching index, not a specific one

The list may contain repeated values; binary search returns **whichever** matching
index it happens to land on, not necessarily the first or last. Executed:

| input | observed | note |
|---|---|---|
| `binary_search([2, 2, 2, 2], 2)` | `1` | not the first (`0`) nor last (`3`) |
| `binary_search([1, 2, 2, 3], 2)` | `1` | one of the two `2`s |

This is **correct** against the contract (`a[r] == x`), which only promises *a*
witnessing index. **Recommendation:** if callers need the *leftmost* (or rightmost)
occurrence — common for `bisect`-style use — this function does **not** provide it;
use `bisect_left`/`bisect_right` or document that the returned index is unspecified
among duplicates. The contract `(SEARCH)`'s found half is deliberately
`a[?r] == x` (existential), matching this behavior.

## Finding 6 — spec-difficulty = ESCALATION signal: the **not-present** half is beyond the bundled fast path (NOT a code bug)

This is the formal headline, and it is **honest scope**, not a defect in your code.
The postcondition is a **disjunction**, and the two halves are not equal in
difficulty:

- **Found half — CLEAN.** `return mid` ⇒ `a[mid] == x`. The `if a[mid] == x` branch
  *just checked* that equality, so the post is an immediate consequence of the rule
  that fired: one index read + one `Int` equality, fully inside the bundled tier.
- **Not-present half — ESCALATION.** `return -1` ⇒ `x` occurs at **no index** of
  `a`. Concluding this needs a **universally-quantified / inductive membership**
  predicate over the whole sorted list, plus two facts the bundled tier cannot
  discharge:
  - **VC-M1 (window narrowing):** for sorted `a`, `a[mid] < x` ⇒ `x` is absent from
    `a[lo : mid+1]`, so membership over `[lo, hi]` reduces to membership over
    `[mid+1, hi]` (and symmetrically). This preserves the invariant across a prune.
  - **VC-M2 (empty window ⇒ absent):** at loop exit `lo > hi`, the empty window
    contains nothing, so by the invariant `x` is in **no** position of `a`.

  The kit's bundled simplification tier (exact-halving + map-extensionality)
  discharges *polynomial/linear* VCs, not quantified array-membership. The kit
  itself flags "array / list loop" as a **roadmap** shape and "recursive data
  structures / inductively-defined predicates (often `μ`)" as an **escalation** case.
  So:

  - The semantics and both claims are **constructed and well-formed**; the **found**
    half and **all** in-bounds/linear VCs discharge with the bundled tier.
  - VC-M1 and VC-M2 are left as explicit `[ESCALATION BOUNDARY]` obligations in
    [`binary-search-spec.k`](binary-search-spec.k) (`(M1)`, `(M2)`). They are **not**
    admitted as `[trusted]` — doing so would fake confidence the kit does not have.
  - **Route (per [`knowledge/sources.md`](../../../formal-verification-kit/knowledge/sources.md)):**
    OOPSLA'20 (unified fixpoint reasoning over inductive data structures) and
    LICS'19 (Matching μ-Logic) for the `μ`-defined membership predicate and its
    lemmas. The durable fix is a **worked array/list-membership example** added to
    the kit — this function is a good candidate once those lemmas exist.

## Finding 7 — corner cases that are handled correctly (deliberate non-findings)

Stated because a reviewer will ask:

- **Empty list** `[]` → `-1`: `len([]) - 1 = -1`, so `hi = -1`, `lo <= hi` is
  `0 <= -1` = false, the loop never runs. Executed: `binary_search([], 5) == -1`. ✓
  (And this case is **not** escalation — the `inWindow` base rule `lo > hi ⇒ false`
  closes it directly; see SPEC.md.)
- **Single element** `[v]` → `0` if `x == v` else `-1`. Executed:
  `binary_search([1], 1) == 0`, `binary_search([1], 2) == -1`. ✓
- **Target below / above all elements** → `-1`. Executed:
  `binary_search([1,3,5,7,9], 0) == -1`, `binary_search([1,3,5,7,9], 10) == -1`. ✓
- **Target between elements (genuinely absent)** → `-1`. Executed:
  `binary_search([1,3,5,7,9], 4) == -1`. ✓ (This is the case whose *proof* needs the
  escalation lemmas — the behavior is right; closing the formal "absent" obligation
  is what's open.)
- **First / last element** → correct index. Executed:
  `binary_search([1,3,5,7,9], 1) == 0`, `binary_search([1,3,5,7,9], 9) == 4`. ✓
- **No index-out-of-bounds:** the in-range window invariant (`0 <= lo`,
  `hi < len`, `lo <= mid <= hi`) keeps every read `a[mid]` inside `[0, len)`. ✓

## Note — termination (partial vs total correctness)

The contract is **partial correctness**: it says nothing about halting. The loop
clearly terminates: the measure `hi - lo + 1` (the window size) strictly decreases
by at least 1 each iteration — `lo = mid+1` raises `lo` above `mid >= lo`, and
`hi = mid-1` lowers `hi` below `mid <= hi` — and is bounded below by `0` (the loop
exits at `lo > hi`). **Recommendation-only:** if you want it proved, add that
variant to `(LOOP)` and discharge "strictly decreases, bounded below" alongside the
existing VCs. Not attempted unless you ask.

---

*Next: run `/verify` to construct the proof of `(SEARCH)`/`(LOOP)` and get the
test-redundancy recommendation (benefit 1). Expect `/verify` to land cleanly on the
structure, the in-bounds/linear VCs, and the entire **found** half, and to **stop at
the not-present half** (VC-M1 narrowing, VC-M2 empty-window-absence) — that stop is
the honest signal, not a failure.*
