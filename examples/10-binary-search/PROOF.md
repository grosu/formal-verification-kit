# PROOF — `binary_search(a, x)` reachability proof

The count-up `sum` example proves a **polynomial closed form**. This one proves a
**disjunctive, data-predicate** postcondition over a list — *found an index `i` with
`a[i] == x`*, **or** *returned `-1` and `x` is absent* — through **one
narrowing-window loop circularity**. It splits cleanly into a **constructed (clean)
half** and an **open `[ESCALATION BOUNDARY]` half**, so this write-up is deliberately
divided into *what is constructed* and *what is an open obligation*.

**Status: constructed, not machine-checked — *and* structurally incomplete by
design.** Two honest caveats, both stronger than the sum example's single one:

1. **Not machine-checked.** The toolchain was not run (MVP stopgap). `#Top` from
   `kprove` is what would upgrade "constructed" → "machine-verified".
2. **Open inductive obligation (the not-present half only).** The proof is complete
   *modulo* two membership lemmas — window-narrowing (**M1**) and
   empty-window-absence (**M2**) — which the kit's bundled simplification tier does
   **not** supply. They are **stated, not admitted** (no `[trusted]` fakery). So
   `kprove` as configured here would **not** reach `#Top`; it would stall exactly on
   M1/M2 in the not-present branch. That stall is the correct, honest outcome for
   this shape (see §5/§6), not a bug in the code. **The entire found half, the loop
   structure, and every in-bounds/linear VC are constructed and dischargeable with
   the bundled tier.**

Artifacts (same directory): [`binary_search.py`](binary_search.py) ·
[`mini-python.k`](mini-python.k) (fragment semantics) ·
[`binary-search-spec.k`](binary-search-spec.k) (the two claims) ·
[`SPEC.md`](SPEC.md) / [`FINDINGS.md`](FINDINGS.md) (the `/formalize` outputs).

The program:

```python
def binary_search(a, x):
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

## 1. The reachability spec — the (SEARCH) function claim

The contract is one reachability rule `φ_pre ⇒ φ_post`: from a configuration that
*defines* `binary_search` and *calls* it on a symbolic **sorted** list `A` and key
`X`, execution reaches a terminated configuration whose `out` holds a value `?r`
that is *either* `-1`-with-`X`-absent *or* an in-range index witnessing `A[?r] == X`.

```
  φ_pre  ≡ ⟨ def binary_search(a,x): <body>   out = binary_search(A, X) ⟩_k
           ⟨ out ↦ _ ⟩_store  ⟨ .Map ⟩_funcs  ⟨ .List ⟩_stack   ∧  isSorted(A)
  φ_post ≡ ⟨ .K ⟩_k  ⟨ out ↦ ?r ⟩_store  ⟨ ?_ ⟩_funcs  ⟨ .List ⟩_stack
           ∧ ( (?r = -1 ∧ ¬ inList(A,X))
               ∨ (0 ≤ ?r < size(A) ∧ A[?r] = X) )
```

(The `(SEARCH)` claim verbatim is in [`binary-search-spec.k`](binary-search-spec.k).)
Reading: the `<k>` cell rewrites to `.K` (terminated); `<funcs> .Map => ?_:Map` says
some function table now exists; `<stack> .List` says the call stack is balanced; the
`ensures` is the disjunctive postcondition. `[all-path]` is sound because
mini-Python is deterministic (all-path ≡ one-path here, as in the sum example).
**Partial correctness:** nothing is claimed about halting (termination is a
recommendation — see [`FINDINGS.md`](FINDINGS.md) "Note").

**Precondition `isSorted(A)`.** Unlike `(SUM)`'s `N >= 0`, this is a *data*
precondition, and it is the **silently-assumed sortedness** of Finding 3: without it
the postcondition is false (an unsorted list yields false negatives). The *generic*
total-order precondition (NaN / mixed types) is **Finding 1**, modeled away by
restricting elements to `Int`.

---

## 2. The loop circularity — (LOOP), the narrowing window

Binary search has one back-edge, so **one** circularity. It is generalized over the
window `(LO, HI)` and target `X` (not pinned to entry values); K's prover adds every
claim in the module to its hypotheses, so it **discharges its own loop**.

**(LOOP) — "the window narrows, always containing X if X is present".** At the head
of `while lo <= hi`, list `A` (constant — never written), window `(LO, HI)`, with
`0 ≤ LO`, `HI < size(A)`, `isSorted(A)`, and the **narrowing-window invariant**
`inList(A,X) → inWindow(A, LO, HI, X)` (if `X` is in `A` at all, it is in the current
window): running the loop reaches one of the two post-states of §1. The closed form
of the "invariant" is the window membership predicate itself; the role a hand-written
invariant used to play is played by `inWindow(A, LO, HI, X)`.

Each iteration computes `MID = (LO+HI)//2` (in range because `LO ≤ MID ≤ HI`) and
case-splits on `A[MID]` vs `X`:
- `A[MID] == X` → **return `MID`** (found; clean — see §3).
- `A[MID] < X` → `LO := MID+1` (prune the lower half; needs **M1**).
- `A[MID] > X` → `HI := MID-1` (prune the upper half; needs **M1**).

The window strictly shrinks (`MID+1 > LO`, `MID-1 < HI`): measure `HI-LO+1`, the
termination variant (partial correctness here; see [`FINDINGS.md`](FINDINGS.md)).

---

## 3. Informal proof (English)

Reachability logic replaces hand-chosen invariants with **guarded coinduction**: the
claim may assume itself, but only after one genuine `=>⁺` step (evaluating the loop
guard). The proof is the loop circularity reused once by the function contract.

**Prove (LOOP).** Evaluate the guard `lo <= hi` — the genuine first step (also the
reason the body's reads are index-safe: the body runs only when `LO ≤ HI`, and with
`0 ≤ LO`, `HI < size`, the midpoint `MID = (LO+HI)//2 ∈ [LO,HI] ⊆ [0,size)`).
Case-split:

- **Guard false** (`LO > HI`): the loop exits to `return -1`, so `?r = -1`. The
  invariant `inList(A,X) → inWindow(A, LO, HI, X)` with an **empty** window
  (`LO > HI` ⇒ `inWindow = false`) forces `¬ inList(A,X)`: `X` occurs at no index of
  `A`. This is the not-present post-state. **Closing it is VC-M2** — the
  universally-quantified "X is absent" conclusion. `[ESCALATION BOUNDARY]`.

- **Guard true** (`LO ≤ HI`): compute `MID`. Inner `if/elif/else` splits three ways:
  - **`A[MID] == X`** (`(while-t)`+`(index-read)`+`(eq)`+`(if-true)`): the body runs
    `return mid`, so `?r = MID` with `0 ≤ MID < size(A)` and `A[MID] = X`. This is
    the **found** post-state and it is **CLEAN**: `A[?r] == X` is *exactly* what the
    branch guard just established, discharged by a single index read + `Int` equality
    (bundled tier). No escalation. ✓
  - **`A[MID] < X`** (`(if-false)`+inner `(if-true)`): `lo = mid + 1`. Control
    returns to the same `while`. **Invoke (LOOP)** at `{LO := MID+1, HI := HI}`; its
    precondition holds — `0 ≤ MID+1`, `HI < size` unchanged, `isSorted(A)` unchanged,
    and the narrowing invariant is preserved because for *sorted* `A`, `A[MID] < X`
    means `X` cannot be at any position `≤ MID`, so
    `inWindow(A,LO,HI,X) = inWindow(A,MID+1,HI,X)`. **This preservation is VC-M1.**
    `[ESCALATION BOUNDARY]`.
  - **`A[MID] > X`** (`(if-false)`+inner `(if-false)`): `hi = mid - 1`, symmetric;
    **invoke (LOOP)** at `{LO := LO, HI := MID-1}`, invariant preserved by the mirror
    of **VC-M1**. `[ESCALATION BOUNDARY]`.

**Prove (SEARCH).** `def` files the body into `<funcs>` (witnesses `?_:Map`);
`out = binary_search(A, X)` evaluates the arguments and `(call)` pushes the caller
frame, gives a fresh scope, binds `a = A`, `x = X`. `lo, hi = 0, len(a) - 1` (tuple
assignment) sets `lo = 0`, `hi = size(A) - 1`. **Apply (LOOP) as a lemma** at
`{LO := 0, HI := size(A) - 1}` — precondition: `0 ≤ 0` ✓, `size(A)-1 < size(A)` ✓,
`isSorted(A)` (the contract's precondition) ✓, and the narrowing invariant is
`inList(A,X) → inWindow(A, 0, size-1, X)`, i.e. `inList → inList`, **trivially true**
(the entry window is the whole list — the analogue of `1 ≤ N+1` from `N ≥ 0`). That
yields one of the two post-states; `return` pops the frame and delivers `?r`;
`out ↦ ?r` with the disjunctive `ensures`. ∎ *(modulo M1/M2 in the not-present
direction; the found direction is unconditional.)*

> **Empty list is NOT escalation.** `A = .List` ⇒ `size = 0` ⇒ `HI = -1` ⇒ guard
> `0 ≤ -1` false ⇒ exit to `return -1`, and `inList(.List,X) = inWindow(.List,0,-1,X)
> = false` by the `inWindow` **base rule** (`LO > HI ⇒ false`) — discharged directly,
> no M1/M2 needed. Only a *non-empty* sorted list with `X` genuinely absent invokes
> M1 (each prune) and M2 (the exit).

---

## 4. Machine-detailed proof sketch (for `kprove`)

Each step cites a rule of [`mini-python.k`](mini-python.k); VCs go to Z3 + the
`[simplification]` lemmas. Abbreviations: `inWindow`, `inList`, `isSorted` are the
spec functions in [`binary-search-spec.k`](binary-search-spec.k).

**PART A — (LOOP) by circularity.** Reuse only after ≥1 genuine rewrite.
- **A1 progress / guard:** `(while)` → `B ~> #whileLoop(B, Bdy)`; evaluate
  `lo <= hi` via `(lookup)`×2 + `(leq)`. This `=>⁺` discharges guardedness.
- **A2 split** (`#Or` on the guard):
  - **false / `(while-f)`:** store unchanged; reach `return -1` (`(return)`),
    `?r = -1`. Obligation `¬ inList(A,X)` from empty `inWindow` = **VC-M2**. ✗
  - **true / `(while-t)`:** `mid = (lo+hi)//2` via `(add)`+`(floordiv = divInt)`,
    `(asgn)` `mid ↦ MID`; `MID ∈ [LO,HI] ⊆ [0,size)` = **VC-bounds** (Z3). Then
    `a[mid] == x` via `(index-read)`+`(eq)`; `(if/else)` 3-way:
    - `==` true: `(if-true)` → `return mid` → `?r = MID`, `A[MID] = X` from the
      guard = **found, clean** (bundled). ✓
    - `<`: `(if-false)`, inner `(if-true)` → `(asgn)` `lo ↦ MID+1` → **reuse (LOOP)**.
      Invariant preservation = **VC-M1** (lower prune). ✗
    - `>` (else): inner `(if-false)` → `(asgn)` `hi ↦ MID-1` → **reuse (LOOP)**.
      Invariant preservation = **VC-M1** (upper prune). ✗

**PART B — (SEARCH) over the call layer.**
`(def)` files the body (witnesses `?_:Map`) → arg eval + `(call)` pushes
`state(CONT,STORE)`, resets `<store>` to `.Map` → `#makeBindings((a,x),(A,X))` binds
`a ↦ A`, `x ↦ X` → `(tuple-asgn)` `lo ↦ 0`, `hi ↦ size(A)-1` → **apply (LOOP) at
`{LO:=0, HI:=size(A)-1}`** (precondition trivially true, §3) → `(return)` pops the
frame, delivers `?r` → `(asgn)` `out ↦ ?r`. Map-extensionality `[simplification]`
reduces the post-store `#Equals` to the value-level `?r` obligation.

**Verification conditions.**

| VC | Statement | Discharged by |
|---|---|---|
| **VC-bounds** | `0≤LO`, `HI<size`, `MID=(LO+HI)//2 ∈ [LO,HI] ⊆ [0,size)`, window strictly shrinks; reads `a[mid]` in `[0,size)` | **Z3** (linear) ✓ |
| **VC-found** | `if a[mid]==x: return mid` ⇒ `0≤?r<size ∧ A[?r]=X` | **bundled** (index read + `Int` eq) ✓ |
| **VC-ext** | post-store cell `#Equals` ⇒ value `?r` | **map-extensionality `[simplification]`** ✓ |
| **VC-M1** | sorted `A`, `A[MID]<X` ⇒ `inWindow(A,LO,HI,X)=inWindow(A,MID+1,HI,X)` (and the `>` mirror): the narrowing invariant is preserved across each prune | **`[ESCALATION BOUNDARY]`** — needs inductive `isSorted`/`inWindow` membership theory (OOPSLA'20 / LICS'19) ✗ |
| **VC-M2** | empty window (`LO>HI`) ⇒ `¬ inList(A,X)`: `X` is absent from the whole list (universally quantified) | **`[ESCALATION BOUNDARY]`** — needs the quantified membership predicate (OOPSLA'20 / LICS'19) ✗ |

So **VC-bounds**, **VC-found**, **VC-ext** discharge with the bundled tier (and they
cover the **entire found half** and the loop's structure/index-safety); **VC-M1** and
**VC-M2** are the open inductive obligations, both in the **not-present** direction.
The structural proof (symbolic execution + the circularity + the call layer) is
complete; the *membership-over-a-sorted-list* reasoning is the boundary. This is
exactly the kit's documented escalation case for recursive/inductive data-structure
predicates.

---

## 5. FINDINGS — benefit 2 (these do NOT depend on machine-checking)

Formalizing + proving surfaced real, executed findings — full detail in
[`FINDINGS.md`](FINDINGS.md). The three the formal lens makes sharp:

> **A hidden bug — the sortedness precondition (Finding 3).** Constructing a clean
> contract forced `requires isSorted(A)`. Violate it and the function disagrees with
> its own docstring. Executed:
>
> | input | observed | expected |
> |---|---|---|
> | `binary_search([2, 5, 1, 9, 3], 2)` | `-1` | `0` (2 is present!) |
>
> A silent **false negative** on an unsorted list. Recommendation: document/enforce
> that `a` is sorted (what `(SEARCH)`'s `isSorted(A)` encodes).

> **A cross-language gem — the `(lo+hi)//2` overflow (Finding 2).** No overflow in
> Python (arbitrary-precision ints; executed `mid` of `(0,2**62)` exact), but the
> *identical* line is the famous **C/Java signed-overflow bug** (Bloch 2006) for
> arrays near `2^31`. The formal need to keep `mid ∈ [lo,hi]` is what exposes the
> assumption "`lo+hi` doesn't wrap" — free in Python, a real precondition in C/Java.
> Recommendation: no Python change; on a fixed-width port use `lo + (hi-lo)//2`.

> **Spec-difficulty = escalation, not a code defect (Finding 6).** The proof above is
> complete *modulo* M1/M2, both in the **not-present** half — proving `x` is absent
> from a sorted list is a quantified/inductive membership statement. That the bundled
> tier cannot close it is the honest signal that this shape needs an inductive
> membership theory — **route:** OOPSLA'20, LICS'19
> ([`knowledge/sources.md`](../../../formal-verification-kit/knowledge/sources.md);
> `/verify --refresh` re-fetches them). The **found** half is fully clean.

---

## 6. TEST REDUNDANCY — benefit 1 (DOUBLY conditioned — do not delete anything yet)

> A verified function is proven for *all* inputs in its domain, so in-domain unit
> tests that re-check single points become redundant — **once the proof actually
> discharges.** Here that is gated **twice**.

If `(SEARCH)` were machine-checked, it would prove `binary_search(a, x)` returns a
witnessing index when `x` is present and a faithful `-1` when absent, for **every**
**sorted** `Int` list `a`. The inline tests in
[`binary_search.py`](binary_search.py)'s `__main__` block map as follows (all inputs
are sorted lists ⇒ in the verified domain):

| Test (inline assertion) | In verified domain? | Covered by which half | Status |
|---|---|---|---|
| `binary_search([], 5) == -1` | yes (empty, sorted) | not-present, **base rule** (not M1/M2) | *would-be* redundant |
| `binary_search([1], 1) == 0` | yes | **found** (clean) | *would-be* redundant |
| `binary_search([1], 2) == -1` | yes | not-present (M2) | *would-be* redundant |
| `binary_search([1,3,5,7,9], 1) == 0` | yes | **found** | *would-be* redundant |
| `binary_search([1,3,5,7,9], 9) == 4` | yes | **found** | *would-be* redundant |
| `binary_search([1,3,5,7,9], 5) == 2` | yes | **found** | *would-be* redundant |
| `binary_search([1,3,5,7,9], 4) == -1` | yes | not-present (M1+M2) | *would-be* redundant |
| `binary_search([1,3,5,7,9], 0) == -1` | yes | not-present (M2) | *would-be* redundant |
| `binary_search([1,3,5,7,9], 10) == -1` | yes | not-present (M2) | *would-be* redundant |

- **The 4 "found" tests** (`[1],1`; `[1,3,5,7,9]` for `1`,`9`,`5`) are subsumed by
  the **clean** found half *as soon as `kprove` returns `#Top`* — they do not even
  depend on M1/M2.
- **The 5 "not-present" tests** (and the empty-list one) are subsumed only once the
  M1/M2 inductive lemmas are supplied *and* `kprove` returns `#Top` — they exercise
  exactly the `[ESCALATION BOUNDARY]` direction.
- **ADD an out-of-domain boundary test (there is none today).** The verified domain
  is *sorted* lists; nothing pins behavior on an **unsorted** list. Add e.g.
  `assert binary_search([2, 5, 1, 9, 3], 2) == -1` to **pin the observed
  false-negative** of Finding 3 (the analogue of the sum example keeping
  `sum_to_n(-1)`). This guards the boundary the proof deliberately does **not**
  cover. A NaN/mixed-type test (Finding 1) is also worth adding.

**Honesty gate — stronger than usual here.** Do **not** drop any test now, for
**two** reasons: (1) the MVP did not run `kprove` ("constructed, not
machine-checked"), and (2) the construction has **open `[ESCALATION BOUNDARY]`
obligations** (M1/M2) — so `(SEARCH)` is not even fully constructed-to-`#Top` on
paper. The "found" tests become *actually* redundant after `kprove` returns `#Top`;
the "not-present" tests additionally need the M1/M2 lemmas first. Until then they are
your only real correctness coverage — **keep all of them.**

---

## Reproduce the (attempted) machine check

```sh
kompile mini-python.k --backend haskell        # compile the fragment semantics
kast    --backend haskell binary-search-spec.k   # (optional) confirm claims parse
kprove  binary-search-spec.k                       # EXPECTED HERE: the found half +
                                                 # structure close; residual goals on
                                                 # VC-M1 / VC-M2 (not-present half),
                                                 # NOT #Top — until the inductive
                                                 # membership lemmas (escalation)
                                                 # are added.
```

Reaching `#Top` requires **first** adding the inductive `inWindow`/`inList`
membership lemmas (M1: sorted-prune narrowing; M2: empty-window absence) per
OOPSLA'20 / LICS'19, **then** running the toolchain. Only after a genuine `#Top` are
the §6 test deletions safe.

---

*Status: constructed, not machine-checked; the found half + loop structure + all
in-bounds/linear VCs are constructed and dischargeable with the bundled tier, the
not-present half is complete modulo the M1/M2 inductive membership obligations.
References: kframework.org; runtimeverification/k; K Tutorial Lesson 1.22. Roșu,
"Matching Logic", LMCS 2017. Chen & Roșu, "Matching μ-Logic", LICS 2019. Roșu &
Ștefănescu, FM 2012 / LICS 2013 (reachability & Circularity). Chen et al., unified
fixpoint reasoning, OOPSLA 2020 (inductive data structures). On the midpoint
overflow: Bloch, "Nearly All Binary Searches and Mergesorts Are Broken" (2006).*
