# PROOF — `insertion_sort(a)` reachability proof (in-place)

The count-up `sum` example proves a **polynomial closed form**. This one proves a
**sorted permutation** — two non-arithmetic predicates over a list, through **two
nested loop circularities**. It is the kit's "array/list loop" *escalation* shape,
so this write-up is deliberately split into **what is constructed** and **what is
an open `[ESCALATION BOUNDARY]` obligation**.

> **In-place variant.** The source prompt explicitly asks for in-place sorting. This
> program has **no `result = list(array)`**: it sorts the parameter `a` in place via nested
> `while` loops and index assignment, then `return a`. The *value* contract is the
> same (sorted permutation, equal length); the *behavioral* contract differs — the
> input is **mutated** and the returned object **is** the input (`is`-identity) —
> see [`FINDINGS.md`](FINDINGS.md) #4.

**Status: constructed, not machine-checked — *and* structurally incomplete by
design.** Two honest caveats, both stronger than the sum example's single one:

1. **Not machine-checked.** The toolchain was not run (MVP stopgap). `#Top` from
   `kprove` is what would upgrade "constructed" -> "machine-verified".
2. **Open inductive obligations.** Even on paper, the proof is complete only
   *modulo* two lemma families — multiset-preservation-under-update (**L1**) and
   sorted-prefix-composition (**L2**) — which the kit's bundled simplification tier
   does **not** supply. They are **stated, not admitted** (no `[trusted]` fakery).
   So `kprove` as configured here would **not** reach `#Top`; it would stall
   exactly on L1/L2. That stall is the correct, honest outcome for this shape (see
   sections 5/7), not a bug in the code.

Artifacts (same directory): [`insertion_sort.py`](insertion_sort.py) ·
[`mini-python.k`](mini-python.k) (fragment semantics, no `list()`) ·
[`mini-python-spec.k`](mini-python-spec.k) (the three claims) ·
[`SPEC.md`](SPEC.md) / [`FINDINGS.md`](FINDINGS.md) (the `/formalize` outputs).

The program ([`insertion_sort.py`](insertion_sort.py)):

```python
def insertion_sort(a):
    i = 1
    while i < len(a):
        key = a[i]
        j = i - 1
        while j >= 0 and a[j] > key:
            a[j + 1] = a[j]
            j = j - 1
        a[j + 1] = key
        i = i + 1
    return a
```

---

## 1. The reachability spec — the (SORT) function claim

The contract is one reachability rule `phi_pre => phi_post`: from a configuration
that *defines* `insertion_sort` and *calls* it on a symbolic list `A`, execution
reaches a terminated configuration whose `out` holds a value `?R` that is
**sorted**, a **permutation** of `A`, and of **equal length**.

```
  phi_pre  == < def insertion_sort(a): <body>   out = insertion_sort(A) >_k
             < out |-> _ >_store  < .Map >_funcs  < .List >_stack
  phi_post == < .K >_k  < out |-> ?R >_store  < ?_ >_funcs  < .List >_stack
             /\  size(?R)=size(A) /\ isSorted(?R) /\ bag(?R)=bag(A)
```

(The `(SORT)` claim verbatim is in [`mini-python-spec.k`](mini-python-spec.k).)
Reading: the `<k>` cell rewrites to `.K` (terminated); `<funcs> .Map => ?_:Map`
says some function table now exists; `<stack> .List` says the call stack is
balanced; the `ensures` is the three-conjunct postcondition. `[all-path]` is sound
because mini-Python is deterministic (all-path == one-path here, as in the sum
example). **Partial correctness:** nothing is claimed about halting (termination is
a recommendation — see [`FINDINGS.md`](FINDINGS.md) "Note").

**No `result = list(a)` line.** This is the in-place variant: the body binds `a`
to the argument and mutates it directly, then `return a`. `?R` is therefore both
the return value *and* the final state of the mutated input. The reference-level
identity `insertion_sort(x) is x` is a Python-object fact the value-sort model
cannot express — it is **Finding 4**, not part of the proved contract.

**No numeric precondition.** Unlike `(SUM)`'s `N >= 0`, `(SORT)` needs none on the
`Int` model — `Int` is totally ordered, so the base prefix is sorted for free. The
*generic* total-order precondition (NaN / mixed types) is **Finding 1**, modeled
away by restricting elements to `Int`.

---

## 2. The loop circularities — (OUTER) and (INNER)

Insertion sort has **two** back-edges, so **two** circularities, nested. Both are
generalized over the array value and counter (not pinned to entry values); K's
prover adds every claim in the module to its hypotheses, so each **discharges its
own loop**, and `(OUTER)` additionally **reuses `(INNER)` as a lemma**.

**(OUTER) — "the sorted prefix grows by one".** At the head of `while i < len(a)`,
array `B`, counter `I`, with `1 <= I <= size(B)` and `isSorted(take(B,I))` (the
prefix `[0,I)` is sorted): running the loop to exit leaves the whole array sorted
and a permutation of `B` (length invariant). Closed form of the "invariant" =
*the sorted prefix itself*.

**(INNER) — "insert key into a hole".** At the head of `while j >= 0 and a[j] > key`,
array `C`, counter `J`, fixed `KEY`, outer index `I`, with `-1 <= J < I < size(C)`,
`isSorted(take(C,J+1))`, and `allGt(seg(C,J+2,I+1),KEY)` (positions `[J+2,I]` are
the shifted region, all `> KEY`): the loop shifts until it runs off the front
(`?J2=-1`) or meets `a[?J2] <= KEY`, growing the shifted region and keeping a
*hole* at `?J2+1`. The load-bearing invariant is **`bag(C[J+1 <- KEY]) = MS`** —
*filling the hole with `KEY` recovers the entry multiset `MS`* — which is what
makes the insert a permutation. (Both claims verbatim in the spec file.)

---

## 3. Informal proof (English)

Reachability logic replaces hand-chosen invariants with **guarded coinduction**:
each claim may assume itself, but only after one genuine `=>+` step (evaluating the
loop guard). The proof is three nested applications.

**Prove (INNER).** Evaluate the guard `j >= 0 and a[j] > key` — the genuine first
step (this also shows *why the code is index-safe*: `j >= 0` short-circuits
**before** `a[j]`, so the read never goes out of bounds and the index stays
positive). Case-split:

- **Guard true** (`J >= 0` and `C[J] > KEY`): the body runs `a[j+1] = a[j]`
  (position `J+1` now holds `C[J] > KEY`, extending the shifted region) and
  `j = j - 1`. Control returns to the same `while`. **Invoke (INNER)** at
  `{C := C[J+1 <- C[J]], J := J-1}`; its precondition holds (the shifted region
  `[J+1,I]` is now all `> KEY`; the prefix `[0,J)` is untouched & sorted; the hole
  moved to `J`). Multiset bookkeeping across this single update is **VC-L1**.
- **Guard false** (`J = -1` or `C[J] <= KEY`): the loop exits at `?J2 = J`. The
  post-state holds verbatim — shifted region `[?J2+2,I]` all `> KEY`, prefix
  `[0,?J2+1)` sorted, hole at `?J2+1`.

**Prove (OUTER).** Evaluate `i < len(a)` (genuine step). Case-split:

- **Guard true** (`I < size(B)`): `key = a[i]` saves the element; `j = i - 1`.
  **Apply (INNER) as a lemma** at `{C := B, J := I-1, KEY := B[I]}` — at this entry
  the shifted region `[I+1,I]` is empty (`allGt` vacuous) and the hole condition is
  trivial (`B[I <- KEY] = B` since `B[I] = KEY`, so `MS = bag(B)`). After (INNER),
  the statement `a[j+1] = key` **fills the hole** at `?J2+1`. Two facts close the
  step:
  - **Sortedness of `[0,I+1)`:** prefix `[0,?J2+1)` is `<= KEY` (sorted, and the
    exit guard gave `a[?J2] <= KEY`); position `?J2+1 = KEY`; region `[?J2+2,I]` is
    `> KEY` **and** sorted (a contiguous shifted block of the originally-sorted
    prefix). Concatenating `prefix <= KEY < block` is sorted — **VC-L2**.
  - **Multiset:** filling the hole with `KEY` restores `bag` to the entry value —
    **VC-L1**.
  Then `i = i + 1` gives `isSorted(take(a,I+1))`, and we **re-invoke (OUTER)** at
  `{B := a, I := I+1}` (precondition `I+1 <= size` from `I < size`).
- **Guard false** (`I >= size(B)`, with `I <= size(B)` => `I = size(B)`): exit.
  `take(a, size) =` the whole array, sorted by the invariant; `bag` preserved
  throughout.

**Prove (SORT).** `def` files the body into `<funcs>` (witnesses `?_:Map`);
`out = insertion_sort(A)` evaluates the argument and `(call)` pushes the caller
frame, gives a fresh scope, binds `a = A`. **There is no `list()` step** — the body
mutates `a` directly. `i = 1`, then **apply (OUTER) as a lemma** at `{B := A, I := 1}`
— precondition `isSorted(take(A,1))` is "a <=1-element prefix is sorted", true (the
analogue of `1 <= N+1` from `N >= 0`). That yields `a` = a sorted permutation of
`A`; `return a` pops the frame and delivers it; `out |-> ?R` with the three
conjuncts. QED *(modulo L1/L2.)*

---

## 4. Machine-detailed proof sketch (for `kprove`)

Each step cites a rule of [`mini-python.k`](mini-python.k); VCs go to Z3 + the
`[simplification]` lemmas. Abbreviations: `take(L,k)`, `seg(L,a,b)`, `isSorted`,
`allGt`, `bag` are the spec functions in [`mini-python-spec.k`](mini-python-spec.k).

**PART A — (INNER) by circularity.** Reuse only after >=1 genuine rewrite.
- **A1 progress / guard:** `(while)` -> `B ~> #whileLoop(B, Bdy)`; `and` is
  `strict(1)` -> evaluate `j >= 0` via `(lookup)`+`(geq)`; short-circuit
  `(and-true)`/`(and-false)`; if continuing, evaluate `a[j] > key` via
  `(lookup)`+`(index-read)`+`(gt)`. This `=>+` discharges guardedness **and** the
  `j >= 0`-before-`a[j]` ordering proves the index-read is in bounds.
- **A2 split** (`#Or` on the guard):
  - **true / `(while-t)`:** `(index-assign)` writes `C[J+1 <- C[J]]` (in-bounds:
    `0 <= J+1 < size`); `(asgn)` `j |-> J-1`; **reuse (INNER)**. Closes via **VC-L1**.
  - **false / `(while-f)`:** store unchanged; post-state is the entry pattern with
    `?J2 = J`. Closes via the `allGt`/`isSorted` frame (no new arithmetic).

**PART B — (OUTER) by circularity, reusing (INNER).**
`(while)`+guard (progress) -> split:
- **true:** `(asgn)` `key |-> B[I]` (in-bounds `I < size`), `j |-> I-1` -> **apply
  (INNER)** -> `(index-assign)` fills the hole `a[?J2+1 <- KEY]` -> `(asgn)`
  `i |-> I+1` -> **reuse (OUTER)**. Closes via **VC-L2** (sortedness) + **VC-L1**
  (multiset).
- **false:** `I = size(B)`; `take` = whole array; closes via the `isSorted` frame.

**PART C — (SORT) over the call layer.**
`(def)` files the body (witnesses `?_:Map`) -> arg eval + `(call)` pushes
`state(CONT,STORE)`, resets `<store>` to `.Map` -> `#makeBindings((a),(A))` binds
`a |-> A` -> *(no `(list)` rule here)* -> `(asgn)` `i |-> 1` -> **apply (OUTER) at
`{B:=A, I:=1}`** (precondition `isSorted(take(A,1))`, trivially true) ->
`(return)` pops the frame, delivers the list -> `(asgn)` `out |-> ?R`.
Map-extensionality `[simplification]` reduces the post-store `#Equals` to the
value-level `?R` obligations.

**Verification conditions.**

| VC | Statement | Discharged by |
|---|---|---|
| **VC-bounds** | `1<=I<=size`; `-1<=J<I<size`; reads/writes of `a[i]`,`a[j]`,`a[j+1]` in `[0,size)`; `I<size => I+1<=size` | **Z3** (linear) — bundled |
| **VC-ext** | post-store cell `#Equals` => value `?R` | **map-extensionality `[simplification]`** — bundled |
| **VC-L1** | `bag(L[p <- v])` = `bag(L)` with one element swapped (multiset preserved across each shift + the hole fill) | **`[ESCALATION BOUNDARY]`** — needs a `Bag`/multiset theory (OOPSLA'20) — OPEN |
| **VC-L2** | a shifted contiguous block of a sorted list is sorted; `prefix <= key < block => isSorted(prefix ++ [key] ++ block)` | **`[ESCALATION BOUNDARY]`** — needs inductive `isSorted`/`range` lemmas (LICS'19/OOPSLA'20) — OPEN |

So **VC-bounds** and **VC-ext** discharge with the bundled tier; **VC-L1** and
**VC-L2** are the open inductive obligations. The structural proof (symbolic
execution + the two circularities + their nesting) is complete; the *arithmetic-of-
data* is the boundary. This is exactly the kit's documented escalation case for
recursive/inductive data-structure predicates.

---

## 5. FINDINGS — benefit 2 (these do NOT depend on machine-checking)

Formalizing + proving surfaced real, executed findings — full detail in
[`FINDINGS.md`](FINDINGS.md). The ones the formal lens makes sharp:

> **A hidden bug — the total-order precondition (Finding 1).** Constructing a clean
> contract forced "elements are totally ordered". Violate it and the function
> disagrees with its intent. Executed:
>
> | input | observed | expected |
> |---|---|---|
> | `[3, float('nan'), 1]` | `[3, nan, 1]` (3 before 1) | a sorted order |
>
> The output is **not sorted**. Recommendation: document/enforce comparable,
> NaN-free elements (what `(SORT)`'s `Int` model encodes).

> **The behavioral contract — mutation (Finding 4).** This in-place prompt yields
> code that **mutates its input** and returns the same object. Executed:
> `a = [3,1,2]`; after `insertion_sort(a)`, `a == [1,2,3]` and `ret is a` is
> **True**. This is a behavioral contract point a caller must know (copy before
> calling if the original order is
> needed). The value-sort model captures the sorted-permutation *value*; the
> `is`-identity is a reference-level fact left as a finding, not modeled.

> **A subtle correctness-adjacent property — stability (Finding 3).** The inner
> guard uses **strict** `>`. That is precisely what makes the sort **stable**
> (equal elements never reorder); `>=` would still sort correctly but **lose
> stability**. Executed: `[1a,1b,0c,1d]` -> `[0c,1a,1b,1d]`. The `>`-vs-`>=` choice
> is load-bearing and invisible to a quick read.

> **Spec-difficulty = escalation, not a code defect (Finding 5).** The proof above
> is complete *modulo* L1/L2. That the bundled tier cannot close them is the honest
> signal that sorting needs an inductive list/multiset theory — **route:**
> OOPSLA'20, LICS'19 ([`../../knowledge/sources.md`](../../knowledge/sources.md);
> `/verify --refresh` re-fetches them). The durable fix is a worked array/list
> example in the kit, of which this function is a natural seed.

---

## 6. TEST REDUNDANCY — benefit 1 (DOUBLY conditioned — do not delete anything yet)

> A verified function is proven for *all* inputs in its domain, so in-domain unit
> tests that re-check single points become redundant — **once the proof actually
> discharges.** Here that is gated **twice**.

This program ships its tests **inline in `__main__`** (there is no separate
`test_*.py` file). If `(SORT)` were machine-checked, it would prove
`insertion_sort(A)` is a sorted permutation for **every** `Int` list `A`. The
`__main__` asserts map as follows:

| Inline assert | In verified domain? | Status |
|---|---|---|
| `insertion_sort([]) == []` | yes (Int list) | *would-be* redundant |
| `insertion_sort([1]) == [1]` | yes | *would-be* redundant |
| `insertion_sort([2,1]) == [1,2]` | yes | *would-be* redundant |
| `insertion_sort([5,2,4,6,1,3]) == [1,2,3,4,5,6]` | yes | *would-be* redundant |
| `insertion_sort([3,3,1,2,1]) == [1,1,2,3,3]` (duplicates) | yes | *would-be* redundant |
| `insertion_sort([5,4,3,2,1]) == [1,2,3,4,5]` (reverse) | yes | *would-be* redundant |
| `insertion_sort([-1,-3,2,0]) == [-3,-1,0,2]` (negatives) | yes | *would-be* redundant |
| `insertion_sort(b) is b` (in-place identity) | reference-level frame | **KEEP** |

- **KEEP the `is b` identity assert.** The `is`-identity (returns the same object,
  i.e. in-place) is a **reference-level** property the value-sort model does **not**
  prove — it is exactly the Finding-4 behavioral contract. It pins behavior the
  proof assumes/omits rather than establishes, so keep it.
- **ADD an out-of-domain boundary test.** There is currently **no** assert for the
  Finding-1 boundary. Add e.g. `insertion_sort([3, float('nan'), 1])` (pin the
  observed `[3, nan, 1]`) and/or "mixed types raise `TypeError`". This is the
  analogue of the sum example keeping `sum_to_n(-1)`; it guards the boundary the
  proof does **not** cover.

**Honesty gate — stronger than usual here.** Do **not** drop any test now, for
**two** reasons: (1) the MVP did not run `kprove` ("constructed, not
machine-checked"), and (2) the construction has **open `[ESCALATION BOUNDARY]`
obligations** (L1/L2) — so `(SORT)` is not even fully constructed-to-`#Top` on
paper. The 7 "*would-be* redundant" asserts become *actually* redundant only after
**both**: the L1/L2 lemmas are supplied (the inductive theory), **and** `kprove`
returns `#Top`. Until then they are your only real correctness coverage — **keep
all of them.**

---

## Reproduce the (attempted) machine check

```sh
kompile mini-python.k --backend haskell        # compile the fragment semantics
kast    --backend haskell mini-python-spec.k   # (optional) confirm claims parse
kprove  mini-python-spec.k                       # EXPECTED HERE: residual goals on
                                                 # VC-L1 / VC-L2, NOT #Top — until
                                                 # the inductive Bag/isSorted lemmas
                                                 # (escalation) are added.
```

Reaching `#Top` requires **first** adding the multiset (`Bag`) and sorted-list
inductive lemmas (L1/L2) per OOPSLA'20 / LICS'19, **then** running the toolchain.
Only after a genuine `#Top` are the section-6 test deletions safe.

---

*Status: constructed, not machine-checked; structurally complete modulo the L1/L2
inductive obligations. In-place variant (input mutated; returns same object).
References: kframework.org; runtimeverification/k; K Tutorial Lesson 1.22. Rosu,
"Matching Logic", LMCS 2017. Chen & Rosu, "Matching mu-Logic", LICS 2019. Rosu &
Stefanescu, FM 2012 / LICS 2013 (reachability & Circularity). Chen et al., unified
fixpoint reasoning, OOPSLA 2020 (inductive data structures).*
