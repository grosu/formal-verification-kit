# Findings report — `reverse.py`

Plain-language findings from formalizing [`reverse.py`](reverse.py). Each is
`input → observed vs expected`. **Non-blocking** — this report never edits or
deletes your code; it is advice. These findings **do not** depend on
machine-checking the proof — they are solid today. The concrete cases below were
**executed** against the actual code (not just reasoned about).

---

## Finding 1 — NO total-order precondition (a positive finding: reverse compares nothing)

Writing a clean contract for `insertion_sort` *forced* the precondition "elements
are totally ordered" (NaN / mixed types break it). **`reverse` has no such
precondition** — it never evaluates `<`/`>`/`==` on elements; it only **moves
elements by position**. So inputs that poison a comparison-based algorithm are
handled fine. Executed:

| input | code returns (observed) | expected (positional reversal) | agree? |
|---|---|---|---|
| `[1, "a", None, [3]]` (incomparable mix) | `[[3], None, "a", 1]` | reversed by position | ✓ |
| `[1.0, float('nan'), 2.0]` | `[2.0, nan, 1.0]` (nan stays in middle) | reversed by position | ✓ |

This is the contrast that places `reverse` *below* `insertion_sort` on the
difficulty ladder: the formal contract `(REV)` carries **no `requires`** at all.
Modeling elements as `Int` in the K semantics is therefore a *benign* restriction
(just to give the `bag` multiset a concrete value sort), not a hidden assumption.

## Finding 2 — O(n) in place (a positive finding: contrast the earlier O(n^2) version)

The two-pointer swap touches each of the `n` elements a constant number of times:
exactly `floor(n/2)` iterations, each doing two index reads, two index writes, and
two pointer updates → **O(n) time, O(1) extra space** (just `i`, `j`, `tmp`).

This is a *positive* finding worth recording explicitly because an earlier draft of
this function reversed by repeatedly `result.insert(0, x)` (or building a new list
by prepending), which is **O(n^2)** — every `.insert(0, ...)` shifts all existing
elements. The current self-contained version avoids that: no allocation, no
shifting, linear. (The formal lens confirms it: the loop circularity has a single
constant-work body and the measure `j - i` falls by 2 each step — see the
termination note.)

## Finding 3 — spec-difficulty signal: the load-bearing centre-reflection side condition

As in the sum example (`I <= N+1`) and insertion-sort (`-1 <= j < i < len`),
writing the loop circularity **forced** a side condition that is not in the source
text and that pins exactly why the algorithm is correct:

- `(LOOP)` needs **`i + j == n - 1`** (the two pointers are reflections about the
  centre). The body does `i += 1; j -= 1`, which **keeps `i + j` constant**, so the
  two already-reversed bands grow symmetrically and meet in the middle. Without this
  invariant the two bands could desync and the index relation `out[k] = a[n-1-k]`
  would not follow.
- Together with `0 <= i` and `j < n` it also gives **in-bounds** indices on every
  iteration: from `i < j` (the guard) and `i + j = n-1` you get `0 <= i < j < n`,
  so both `a[i]` and `a[j]` reads/writes are in range. This is a *positive* finding
  — there is **no off-by-one and no out-of-bounds**.

These are not bugs; they are the silent assumptions the formal lens surfaces, and
here they all hold.

## Finding 4 — it MUTATES its input (a behavioral contract point — note this)

`reverse` reverses **in place**: the swaps write back into the *same* list object,
and it `return a` — the same object. So the caller's list **is mutated**, and the
return value is **identity-equal** to the argument. Executed:

| input | after `reverse(b)` | `reverse(b) is b`? |
|---|---|---|
| `b = [10, 20, 30]` | `b == [30, 20, 10]` (caller's list changed) | `True` |
| `x = [1,2,3,4,5]` | `x == [5,4,3,2,1]` | `True` |

**This is a real behavioral contract point**, and it is the **opposite** of
`insertion_sort` (which copies via `list(array)` and leaves the input untouched).
Consequences a caller must know:

- a caller relying on the original order **loses it** after calling `reverse`;
- aliases of the list see the change;
- the returned object is the input, not a copy.

**Caveat on the model:** the K `List` is a *value* sort, so the mini-X model cannot
express Python's aliasing — it models the mutation as rebinding `a |-> L` within
the function scope, and the *caller* observes the result via `out = reverse(A)`.
The **no-copy / mutate-the-caller** behavior is therefore a property the K model
does **not** capture and that the formal contract leaves implicit. **Recommendation:**
document "reverses in place and returns the same object" in a docstring, and keep a
test that pins both (the `__main__` block already asserts `reverse(y) is y` and that
`x` is mutated — keep those).

## Finding 5 — empty and single-element inputs are handled correctly (deliberate non-findings)

Stated because a reviewer will ask:

- **Empty list** `[]` → `[]`: `i = 0`, `j = len([]) - 1 = -1`; the guard
  `0 < -1` is false, the loop never runs. ✓ Executed: `reverse([]) == []`.
- **Single element** `[42]` → `[42]`: `i = 0`, `j = 0`; `0 < 0` is false. ✓
  Executed: `reverse([42]) == [42]`.
- **Even length** `[1,2,3,4]` → `[4,3,2,1]`: `2` swaps, pointers cross at
  `i=2, j=1`. ✓
- **Odd length** `[1,2,3,4,5]` → `[5,4,3,2,1]`: `2` swaps, the centre element `3`
  is never touched (`i = j = 2` exits the guard). ✓

These are the analogue of the sum example's `n = 0` base case; the lower-bound
arithmetic of the loop (`i + j = n - 1`, guard `i < j`) makes them fall out for free.

## Finding 6 — spec-difficulty = ESCALATION signal: the permutation half (NOT a code bug)

This is the headline scope statement, and it is **honest scope**, not a defect.
The contract splits into two halves of very different mechanizability:

- **(H-CLEAN) — index relation + length.** `out[i] = a_old[n-1-i]` for all `i`, and
  `len(out) = len(a_old)`. This is **first-order over positions**: each position
  equality is an `L[_]` / in-bounds fact, and the length is invariant under swaps.
  It is **bundled-tier clean** — discharged by the same simplification tier as
  `sum-up` (in-bounds index facts + map/list extensionality). The clean half.

- **(H-PERM) — permutation.** `bag(out) ==K bag(a_old)` (multiset equality). Proving
  the swap step preserves the multiset (lemma **P1**:
  `bag(L[i<-L[j]][j<-L[i]]) ==K bag(L)`) needs an **inductive list/`Bag` theory** —
  the kit's documented **escalation** case for "recursive data structures /
  inductively defined predicates / multiset reasoning (often `mu`)". It is the
  **same boundary `insertion_sort` hits**.

So:

- The semantics and both claims are **constructed and well-formed**.
- The **(H-CLEAN)** VCs discharge with the bundled tier.
- The **(H-PERM)** VC (P1) is left as an explicit `[ESCALATION BOUNDARY]` obligation
  in [`reverse-spec.k`](reverse-spec.k). It is **not** admitted as
  `[trusted]` — doing so would fake confidence the kit does not have.
- **Route (per [`knowledge/sources.md`](../../../formal-verification-kit/knowledge/sources.md)):**
  OOPSLA'20 (unified fixpoint reasoning over inductive data structures) and LICS'19
  (Matching mu-Logic) for the multiset (`Bag`) lemma.

**Recorded honesty (does not let us skip the obligation):** (H-PERM) is **logically
redundant** given (H-CLEAN) — `i |-> n-1-i` is a *bijection* on positions `[0,n)`, so
`out[i] = a_old[n-1-i]` for all `i` already implies `out` is a rearrangement of
`a_old`, hence the multisets are equal. But **mechanizing** "index bijection => 
multiset equality" is itself an inductive/combinatorial fact over lists that the
bundled tier cannot close, so (H-PERM) stays at the escalation boundary despite
being a semantic consequence of the clean half. We keep it in the contract for
explicitness and parallelism with `insertion_sort`.

## Note — termination (partial vs total correctness)

The contract is **partial correctness**: it says nothing about halting. The loop
clearly terminates: the measure **`j - i`** strictly decreases by **2** each
iteration (`i += 1`, `j -= 1`), bounded below by the exit guard `i >= j`. So it runs
exactly `floor(n/2)` iterations. **Recommendation-only:** if you want it proved, add
that variant to `(LOOP)` and discharge "strictly decreases, bounded below" alongside
the existing VCs. Not attempted unless you ask.

---

*Next: run `/verify` to construct the proof of `(REV)`/`(LOOP)` and get the
test-redundancy recommendation (benefit 1). Expect `/verify` to land cleanly on the
structure and the **(H-CLEAN)** index/length VCs, and to **stop at the `[ESCALATION
BOUNDARY]`** multiset lemma (Finding 6) — that stop is the honest signal, not a
failure.*
