# PROOF — `array_max(a)` reachability proof (constructed, not machine-checked)

A single forward-pass maximum. Its loop invariant is a **predicate** — "the running
`largest` is the max of the visited prefix `a[0:i)`" — written as a bounded-`forall`
upper bound plus membership over K's `List` value sort, **not** an arithmetic closed
form like the `sum` example. Crucially, because the postcondition is *max* (upper
bound + membership) and **not** *sort* (sortedness + permutation), the whole proof
stays in the kit's **bundled simplification tier**: no multiset, no escalation.

**Status: constructed, not machine-checked.** The artifacts are built to be
`kompile`/`kprove`-checkable but the toolchain was **not run** in this environment
(MVP stopgap). Treat the result as "constructed" until §"Reproduce" turns it into
"machine-verified."

Artifacts referenced (same directory):
[`array_max.py`](array_max.py) · [`mini-python.k`](mini-python.k) (the fragment
semantics, with `if` and the `<`/`>` comparisons array_max uses) ·
[`array-max-spec.k`](array-max-spec.k) (the K claims) · [`SPEC.md`](SPEC.md) and
[`FINDINGS.md`](FINDINGS.md) (the `/formalize` outputs).

The program ([`array_max.py`](array_max.py)):

```python
def array_max(a):
    largest = a[0]
    i = 1
    while i < len(a):
        if a[i] > largest:
            largest = a[i]
        i = i + 1
    return largest
```

---

## 1. The reachability spec — the (MAX) function claim

The whole-function contract is one reachability rule `φ_pre ⇒ φ_post`: from a
configuration that *defines* `array_max` and *calls* it on a **non-empty** list `A`,
execution reaches a terminated configuration whose `result` is an **upper bound of**
and a **member of** `A` (i.e. `result = max A`).

```
  φ_pre  ≡  ⟨ def array_max(a): <body>   result = array_max(A) ⟩_k  ⟨ result ↦ _ ⟩_store
            ⟨ .Map ⟩_funcs  ⟨ .List ⟩_stack    ∧   size(A) ≥ 1
  φ_post ≡  ⟨ .K ⟩_k  ⟨ result ↦ ?M ⟩_store  ⟨ ?_ ⟩_funcs  ⟨ .List ⟩_stack
            ∧   isUpperBound(A, ?M)  ∧  inList(?M, A)
```

As the **(MAX)** `claim` in [`array-max-spec.k`](array-max-spec.k):

```k
claim
  <k>
    def array_max ( a ) : INDENT
      largest = a[0]
      i = 1
      while i < len(a) : INDENT
        if a[i] > largest : INDENT
          largest = a[i]
        DEDENT
        i = i + 1
      DEDENT
      return largest
    DEDENT
    result = array_max ( A:List )
  => .K ... </k>
  <funcs> .Map => ?_:Map </funcs>
  <store> result |-> (_:KResult => ?M:Int) </store>
  <stack> .List </stack>
  requires size(A) >=Int 1
  ensures  isUpperBound(A, ?M) andBool inList(?M, A)
  [all-path]
```

Reading: `requires size(A) >=Int 1` is the **precondition** — the non-emptiness that
`largest = a[0]` silently needs (FINDINGS #1); framed on every step. The `<k>` cell
rewrites the program to `.K` (terminated). The post-`<store>` binds `result` to some
`?M`; the `ensures` is the **∀-quantified postcondition** — `isUpperBound(A, ?M)` is
`forall j in [0, len). A[j] <= ?M`, and `inList(?M, A)` is membership. `?M` is a
`?`-existential (Lesson 1.22 §3.3): "*some* value exists" — witnessed by the computed
max. `<funcs> .Map => ?_:Map` says some function table now exists; `<stack> .List`
says the call stack is balanced again. `[all-path]` demands *every* terminating path
hit the target — sound here because mini-Python is deterministic, so all-path
coincides with one-path. This is **partial correctness** (it constrains terminating
runs; it does not assert the loop halts).

---

## 2. The loop circularity — the (LOOP) claim

The proof turns on one auxiliary claim about the loop, generalized over the running
max `R` and the counter `I`, with side condition `1 ≤ I ≤ size(A)` and the invariant
`R = maxPrefix(A, I)` (the max of the first `I` elements):

```
  (LOOP)  ⟨ while i<len(a): (if a[i]>largest: largest=a[i]); i=i+1
            | a↦A, largest↦R, i↦I ⟩  ∧  1 ≤ I ≤ size(A)  ∧  R = maxPrefix(A,I)
      ⇒   ⟨ .K | a↦A, largest ↦ maxPrefix(A, size(A)),  i ↦ size(A) ⟩
```

As the **(LOOP)** `claim` in [`array-max-spec.k`](array-max-spec.k):

```k
claim
  <k>
    while i < len(a) : INDENT
      if a[i] > largest : INDENT
        largest = a[i]
      DEDENT
      i = i + 1
    DEDENT => .K ...
  </k>
  <store>
    a       |-> A:List
    largest |-> (R:Int => maxPrefix(A, size(A)))
    i       |-> (I:Int => size(A))
  </store>
  requires 1 <=Int I andBool I <=Int size(A)
   andBool R ==Int maxPrefix(A, I)
  [all-path]
```

It reads: *running the loop from counter `i = I` with `largest = R = max of a[0:I)`
(and `1 ≤ I ≤ size(A)`) leaves `largest = max of a[0:size(A)) = max A` and
`i = size(A)`.* The running closed form `maxPrefix(A, I)` plays the role the classical
invariant would. The side condition **`1 ≤ I` is necessary**: it records that `a[0]`
is already folded into `largest` before the loop (so the visited prefix is non-empty
and `maxPrefix` is defined); drop it and the entry invariant for the `(MAX)` call is
unjustified — this is the loop-level echo of the non-empty precondition (FINDINGS #1).

---

## 3. Informal proof (English)

Reachability logic replaces the hand-chosen *loop invariant* with **coinduction**: K
adds every claim in the module to its hypotheses, so **(LOOP) may assume itself** while
proving itself — *provided* it first makes one genuine step (guardedness). The
`maxPrefix` formula plays the role the invariant used to.

**Prove (LOOP).** Run the loop one step. `(while)` evaluates the guard `i < len(a)` —
that genuine first step earns the right to reuse the hypothesis — then case-split:

- **Guard true (`I < size(A)`):** the body runs. `if a[i] > largest` case-splits again
  (the prover's `#Or` on the `if` guard):
  - **`a[I] > R`:** `largest = a[i]` sets `largest = a[I]`.
  - **`a[I] <= R`:** no `else`, so `largest` stays `R`.
  Either way the new `largest` is `maxInt(R, a[I])` (this is VC-MAX-DEF: the two
  branches *are* the two cases of `maxInt`). Then `i = i + 1` makes `i = I + 1`, and
  control returns to the same `while`. The new state has
  `largest = maxInt(maxPrefix(A,I), a[I]) = maxPrefix(A, I+1)` (this is **VC-MAXSTEP**,
  the definitional recurrence of `maxPrefix`), and `1 ≤ I+1 ≤ size(A)` from
  `I < size(A)`. **Invoke (LOOP) itself** at `{R := maxPrefix(A,I+1), I := I+1}`; its
  precondition holds. ✓
- **Guard false (`I >= size(A)`, with `I <= size(A)` from the precondition):** then
  `I = size(A)`, the body never runs, `largest` is unchanged `= maxPrefix(A, size(A))`,
  and `i = size(A)`. ✓

Both branches land on (LOOP)'s post-state, and the hypothesis was used only after a
real step, so the circularity discharges.

**Prove (MAX).** Execute the program against the semantics: `def array_max` files the
body into `<funcs>`; `result = array_max(A)` evaluates the argument (the `List` value
`A`), and `(call)` pushes the caller's frame, gives the callee a fresh scope, and
binds `a = A`. The body runs `largest = a[0]` (in-bounds because `size(A) ≥ 1`),
giving `largest = A[0] = maxList(A[0:1)) = maxPrefix(A, 1)`; then `i = 1`. Now **use
(LOOP) as a lemma** at `{R := maxPrefix(A,1), I := 1}` — its precondition
`1 ≤ 1 ≤ size(A)` follows from `size(A) ≥ 1`, and `R = maxPrefix(A,1)` holds — making
`largest = maxPrefix(A, size(A)) = maxList(A) = max A`. Then `return largest` pops the
frame, restores the caller store, and the returned value is assigned to `result`.
Finally the **VC-UB / VC-MEM** bridges turn `result = maxList(A)` into the two
postcondition predicates: `isUpperBound(A, maxList(A))` and `inList(maxList(A), A)`,
both of which hold for non-empty `A`. Final state:
`result ↦ ?M` with `isUpperBound(A, ?M) ∧ inList(?M, A)` — exactly the spec. ∎

---

## 4. Machine-detailed proof sketch (for `kprove`)

Each step cites a rule of [`mini-python.k`](mini-python.k); the VCs are discharged by
Z3 plus the `[simplification]` lemmas in [`array-max-spec.k`](array-max-spec.k).
Abbreviation: `mp(I) := maxPrefix(A, I) = max of A[0:I)`; `N := size(A)`.

**PART A — (LOOP) by circularity.** Reuse (LOOP) only after ≥ 1 genuine rewrite.
- **A1 progress:** `(while)` → `(i<len(a)) ~> #whileLoop(...)`. This `=>+` transition
  discharges guardedness.
- **A2 guard:** `<` is `seqstrict` → `(lookup)` `i⇒I`; `len(a)`→`(len)` `size(A)=N`;
  `(lt)` → `I <Int N`.
- **A3 split** (`#Or` on `I <Int N` under `I <=Int N`):
  - **true / `(while-t)`:** rebuild the `while`; the body's `if a[i] > largest`:
    `a[i]`→`(index-read)` `A[I]` (in-bounds: `0 ≤ I < N` from `1 ≤ I < N`), `largest`→
    `R`, `(gt)` → `A[I] >Int R`; **inner `#Or` split** on that guard:
    - `A[I] >Int R`: `(if-t)` runs `largest = a[i]` → `largest ↦ A[I]`.
    - `notBool (A[I] >Int R)`: `(if-f)` → `largest ↦ R` unchanged.
    Both unify to `largest ↦ maxInt(R, A[I])` via **VC-MAX-DEF**. Then `(add)`+`(asgn)`
    give `i ↦ I +Int 1`. **Reuse (LOOP)** at `{R := maxInt(R,A[I]), I := I+Int 1}`,
    after **VC-MAXSTEP** rewrites `maxInt(mp(I), A[I]) ⇒ mp(I+1)`. Closes via **VC1**.
  - **false / `(while-f)`:** antisymmetry ⇒ `I = N`; store unchanged, `largest = mp(N)`,
    `i = N`. Closes via **VC2**.

**PART B — (MAX) over the real call layer.**
`(def)` files the body (witnesses `?_:Map`) → arg eval + `(call)` pushes
`state(CONT, STORE)` and resets `<store>` to `.Map` → `#makeBindings((a),(A))` binds
`a ↦ A` → `largest = a[0]`: `(index-read)` `A[0]` (in-bounds: `0 < N` from
`size(A) ≥ 1`), `(asgn)` `largest ↦ A[0] = mp(1)` (**VC3**) → `(asgn)` `i ↦ 1` →
**apply (LOOP) at `{R := mp(1), I := 1}`** (precondition `1 ≤ 1 ≤ N` from `N ≥ 1`),
`largest ↦ mp(N) = maxList(A)` → `(return)` pops the frame, restores caller store,
delivers the `Int` → `(asgn)` `result ↦ maxList(A)`. Map-extensionality
`[simplification]` reduces the post-store `#Equals` to a scalar one; the `ensures`
closes via **VC-UB / VC-MEM**.

**Verification conditions** — every one is linear-over-a-total-order or a finite
unfolding of a `[function]` abstraction; **none is a multiset/permutation fact**:

| VC | Statement | Discharged by |
|---|---|---|
| **VC1** | `maxInt(mp(I), A[I]) = mp(I+1)` | VC-MAXSTEP `[simplification]` + Z3 |
| **VC2** | `I = N ⇒ mp(N)` is the exit value (store unchanged) | Z3 (linear) |
| **VC3** | `A[0] = mp(1)` (`= maxList(A[0:1))`) | take/maxList unfold + Z3 |
| **VC-UB** | `isUpperBound(A, maxList(A))` for `A ≠ .List` | VC-UB `[simplification]` |
| **VC-MEM** | `inList(maxList(A), A)` for `A ≠ .List` | VC-MEM `[simplification]` |
| **VC-MAX-DEF** | the `if` branches = the two cases of `maxInt` | VC-MAX-DEF `[simplification]` + Z3 |
| sides | `N≥1 ⇒ 1≤N`; `I<N ⇒ I+1≤N`; index in-bounds `0≤I<N` | Z3 (linear) |

**Tier confirmation (no escalation).** The `[simplification]` lemmas here are
**definitional unfoldings of the spec-only `[function]`s** (`maxPrefix`/`maxList`/
`isUpperBound`/`inList`) over K's total order on `Int`, plus the standard
map-extensionality lemma — exactly the *same kind* of lemma as the `sum` example's
exact-halving rule, not the inductive multiset reasoning that pushed
`examples/12-insertion-sort` to its boundary. There is **no `[ESCALATION BOUNDARY]`
obligation** in this proof; nothing is faked as `[trusted]`. The single genuinely
list-shaped fact, VC-MAXSTEP, is a finite `take`/`maxList` recurrence the bundled tier
rewrites and Z3 then closes — it does **not** require a `Bag`/permutation theory.

---

## 5. FINDINGS — the hidden subtle preconditions (benefit 2)

Two preconditions the code silently assumes, both **executed** against the real
program (full detail + tables in [`FINDINGS.md`](FINDINGS.md)):

- **Non-empty list (`len(a) ≥ 1`).** `array_max([])` → `IndexError` (observed), because
  `largest = a[0]` indexes element 0 of an empty list. The contract `(MAX)` encodes
  this as `requires size(A) >=Int 1`; the loop side condition `1 ≤ i ≤ len(a)` is the
  same fact through the scan.
- **Total order on elements.** `array_max([1, 2, nan]) → 2` but `array_max([nan, 1, 2])
  → nan` (both observed): the answer depends on **position**, so the postcondition
  "`result` is the max" is **false** on any input containing `NaN`. Mixed types
  (`[1,'a',2]`) → `TypeError`. The `Int` element model gives a genuine total order
  (the faithful analogue of `sum`'s Int restriction); the gap is reported, not hidden.

These are exactly the difficulties the kit predicts surfacing when you pin down a clean
precondition — here both are real domain restrictions, not structural defects.

---

## 6. TEST REDUNDANCY — fewer tests, faster CI (benefit 1)

> **A verified function is proven correct for all inputs in its domain**, so unit tests
> that only re-check points inside that domain become redundant.

Once `(MAX)` is machine-checked, it proves `array_max(a)` returns the upper-bound-and-
member (= `max a`) for **every** non-empty list of `Int`. The in-domain unit tests in
[`array_max.py`](array_max.py)'s `__main__` block are then subsumed:

- `array_max([42]) == 42` → subsumed (singleton; `max = 42`, `len ≥ 1`). **Redundant.**
- `array_max([1, 2, 3]) == 3` → subsumed (`max = 3`). **Redundant.**
- `array_max([3, 2, 1]) == 3` → subsumed (`max = 3`; first-element max). **Redundant.**
- `array_max([5, 1, 9, 4, 9, 2]) == 9` → subsumed (`max = 9`; duplicate max). **Redundant.**
- `array_max([-3, -1, -7, -2]) == -1` → subsumed (all-negative; `max = -1`). **Redundant.**
- `array_max([0, 0, 0]) == 0` → subsumed (all-equal; `max = 0`). **Redundant.**
- `array_max([2, 2, 2, 2]) == 2` → subsumed (all-equal; `max = 2`). **Redundant.**
- `array_max([-10, 5, 0, 5, -10]) == 5` → subsumed (`max = 5`; duplicate max). **Redundant.**

**CI saving.** All 8 in-domain assertions only re-check points the single proof already
covers for *every* non-empty `Int` list, so dropping them removes 8 assertion executions
from every CI run — one proof replaces an unbounded family of point-checks.

**Keep the out-of-domain boundary tests** — and ideally **add** them, since the current
suite has none:

- An **empty-list** test pinning the FINDINGS #1 behavior, e.g.
  `with pytest.raises(IndexError): array_max([])` (or, if you add a guard,
  `pytest.raises(ValueError)`) — outside the verified domain `len(a) ≥ 1`.
- A **`NaN` / total-order** test pinning the FINDINGS #2a behavior — outside the
  verified `Int` (total-order) domain. This is exactly where a regression would hide.

**Conditioned on machine-checking.** This recommendation is conservative and
recommendation-only. The MVP **does not run `kprove`** — the proof here is "constructed,
not machine-checked." Do **not** delete any test until the claims actually discharge
(`kprove` returns `#Top`); see "Reproduce" below.

---

## Residual risk (read before trusting)

- **Partial, not total, correctness.** The proof says: *if and when* `array_max`
  returns, the result is the max. Termination is **not** proved (no decreasing measure
  in the proof). It is obvious here — `i` strictly increases by 1 toward the fixed
  bound `len(a)` — and is offered as a recommendation: to get total correctness, add
  the variant `len(a) − i` (bounded below by 0, strictly decreasing per iteration) to
  `(LOOP)` and discharge it alongside the VCs. Not attempted by default.
- **Trusted base.** (i) The **adequacy of the mini-X fragment semantics** — that
  [`mini-python.k`](mini-python.k) faithfully models the slice of Python `array_max`
  uses; (ii) the reachability proof-system metatheory and `kprove`; (iii) the
  SMT/`[simplification]` oracle (Z3 + the lemmas here).
- **Element model = `Int`.** The clean total order is `Int`'s; the genericity gap and
  the `NaN`/mixed-type total-order precondition are FINDINGS #2, not modeled away.
- **Constructed, not machine-checked.** The toolchain was not run; a `#Top` from
  `kprove` upgrades this from *constructed* to *machine-verified*.

---

## Reproduce the machine check

```sh
kompile mini-python.k --backend haskell      # compile the fragment semantics (Haskell backend)
kast    --backend haskell array-max-spec.k # (optional) confirm the claims parse
kprove  array-max-spec.k                    # expected: #Top  (all claims proved)
```

`kprove` inherits the Haskell backend from the `kompile`d definition above, so it needs
no `--backend haskell` of its own. A `#Top` result upgrades everything above from
**constructed** to **machine-verified**, and only then are the §6 test deletions safe.

---

*References: kframework.org; runtimeverification/k; K Tutorial Lesson 1.22.
Roșu, "Matching Logic", LMCS 2017. Chen & Roșu, "Matching μ-Logic", LICS 2019.
Roșu & Ștefănescu, FM 2012 / LICS 2013 (reachability logic & Circularity).
Modeling imitated from the kit's examples/02-sum-up/ (loop circularity) and
examples/12-insertion-sort/ (the List value sort + KResult-argument call machinery).*
