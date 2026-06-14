# PROOF — `reverse(a)` reachability proof

The `sum` example proves a **polynomial closed form**; `insertion-sort` proves a
**sorted permutation** (two non-arithmetic predicates, two nested loops). `reverse`
sits **between** them: its postcondition is an **index relation + length** (a clean,
first-order, bundled-tier half) **plus** a **permutation** (the multiset half that
hits the same `[ESCALATION BOUNDARY]` as insertion-sort). One loop, one circularity.

**Status: constructed, not machine-checked — *and* one half is an open
`[ESCALATION BOUNDARY]` obligation by design.** Two honest caveats:

1. **Not machine-checked.** The toolchain was not run (MVP stopgap). `#Top` from
   `kprove` is what would upgrade "constructed" → "machine-verified".
2. **One open inductive obligation.** The index-relation/length half **(H-CLEAN)**
   is constructed and rests only on the bundled tier. The permutation half
   **(H-PERM)** needs a multiset (`Bag`) lemma the bundled tier does **not** supply.
   It is **stated, not admitted** (no `[trusted]` fakery). So `kprove` as configured
   would discharge (H-CLEAN) and **stall on (H-PERM)**, not reach `#Top`. That stall
   is the correct, honest outcome for this shape, not a code bug.

Artifacts (same directory): [`reverse.py`](reverse.py) ·
[`mini-python.k`](mini-python.k) (fragment semantics) ·
[`reverse-spec.k`](reverse-spec.k) (the two claims) ·
[`SPEC.md`](SPEC.md) / [`FINDINGS.md`](FINDINGS.md) (the `/formalize` outputs).

The program ([`reverse.py`](reverse.py)):

```python
def reverse(a):
    i = 0
    j = len(a) - 1
    while i < j:
        tmp = a[i]
        a[i] = a[j]
        a[j] = tmp
        i = i + 1
        j = j - 1
    return a            # reversed IN PLACE; returns the same object
```

---

## 1. The reachability spec — the (REV) function claim

The contract is one reachability rule `phi_pre => phi_post`: from a configuration
that *defines* `reverse` and *calls* it on a symbolic list `A`, execution reaches a
terminated configuration whose `out` holds a value `?R` that is the **positional
reversal** of `A` — same length, `?R[i] = A[n-1-i]` for all `i`, and a permutation
of `A`.

```
  phi_pre  = < def reverse(a): <body>   out = reverse(A) >_k
             < out |-> _ >_store  < .Map >_funcs  < .List >_stack
  phi_post = < .K >_k  < out |-> ?R >_store  < ?_ >_funcs  < .List >_stack
             /\  size(?R)=size(A)                       (H-CLEAN: length)
             /\  isMirror(?R, A, 0, size(A))            (H-CLEAN: out[i]=A[n-1-i])
             /\  bag(?R)=bag(A)                         (H-PERM: permutation)  [ESC]
```

(The `(REV)` claim verbatim is in [`reverse-spec.k`](reverse-spec.k).)
Reading: the `<k>` cell rewrites to `.K` (terminated); `<funcs> .Map => ?_:Map`
says some function table now exists; `<stack> .List` says the call stack is
balanced; the `ensures` is the three-conjunct postcondition. `[all-path]` is sound
because mini-Python is deterministic (all-path = one-path here, as in the sum and
insertion-sort examples). **Partial correctness:** nothing is claimed about halting
(termination is a recommendation — see [`FINDINGS.md`](FINDINGS.md) "Note").

**No precondition at all.** Unlike `(SUM)`'s `N >= 0` and unlike insertion-sort's
implicit total order, `(REV)` needs **none**: `reverse` compares nothing, so there
is no order requirement (Finding 1), and empty/singleton inputs are in-domain (the
guard `0 < n-1` is false — the base case).

---

## 2. The loop circularity — (LOOP)

`reverse` has one back-edge, so **one** circularity, generalized over the array
value and both pointers (not pinned to entry values); K's prover adds every claim in
the module to its hypotheses, so `(LOOP)` **discharges its own loop**.

**(LOOP) — "two reversed bands grow toward the centre".** At the head of
`while i < j`, current array `C`, pointers `I` (left), `J` (right), with the
**three-region** invariant relative to the original input `A`:

- `0 <= I`, `J < size(C)`, `size(C) = size(A)` (length invariant under swaps);
- **`I + J = size(A) - 1`** — the centre-reflection side condition: each step
  `i += 1; j -= 1` keeps `I + J` constant, so the bands stay symmetric (Finding 3);
- `isMirror(C, A, 0, I)` — left band `[0,I)` already reversed: `C[k] = A[n-1-k]`;
- `isMirror(C, A, J+1, size(A))` — right band `(J,n)` already reversed;
- `seg(C, I, J+1) = seg(A, I, J+1)` — the untouched middle `[I,J]` still equals `A`'s;
- `bag(C) = bag(A)` — multiset preserved so far **[ESCALATION BOUNDARY]**.

Running the loop to exit (`I >= J`) collapses the middle and yields the whole array
mirrored: `size(?D)=size(A)`, `isMirror(?D, A, 0, size(A))`, `bag(?D)=bag(A)`.
(Claim verbatim in the spec file.) The "two reversed bands" play the role a
hand-written invariant used to.

---

## 3. Informal proof (English)

Reachability logic replaces hand-chosen invariants with **guarded coinduction**:
the claim may assume itself, but only after one genuine `=>+` step (evaluating the
loop guard). The proof is two applications, `(LOOP)` then `(REV)` reusing it.

**Prove (LOOP).** Evaluate the guard `i < j` — the genuine first step (the
`=>+` that earns the hypothesis). Case-split:

- **Guard true** (`I < J`, hence with `I+J = n-1` also `0 <= I < J < n`, so both
  indices are in bounds — *this is where index-safety is proved*): the body runs
  - `tmp = a[i]` (saves `C[I]`),
  - `a[i] = a[j]` (position `I` now holds `C[J]`),
  - `a[j] = tmp` (position `J` now holds the old `C[I]`) — i.e. the array becomes
    `C' = C[I <- C[J]][J <- C[I]]`, a **single swap**,
  - `i = i + 1`, `j = j - 1`.
  Control returns to the same `while`. The post-swap state satisfies the invariant
  at `{C := C', I := I+1, J := J-1}`:
  - `(I+1)+(J-1) = I+J = n-1` (centre reflection preserved — **VC-CENTRE**, linear);
  - the left band grows to `[0,I+1)`: position `I` now holds `C[J] = A[n-1-J] =
    A[(n-1)-((n-1)-I)] = A[I]`... more directly, since `I+J=n-1`, `C[J]` (which by
    the middle-equality is `A[J]`) lands at position `I`, and `A[J] = A[n-1-I]`, so
    `C'[I] = A[n-1-I]` — extending `isMirror(C',A,0,I+1)` — **VC-MIRROR-L**;
  - symmetrically the right band grows to `(J-1,n)`: `C'[J] = A[I] = A[n-1-J]` —
    **VC-MIRROR-R**;
  - the middle shrinks to `[I+1,J-1]` and is still equal to `A`'s there (untouched
    by the two end-writes) — **VC-MID**;
  - `bag(C') = bag(C) = bag(A)`: one swap preserves the multiset — **VC-PERM (P1)**
    **[ESCALATION BOUNDARY]**.
  **Invoke (LOOP)** at the shifted state; its precondition is exactly the above. The
  index/length VCs are bundled-tier; the bag VC is the boundary.
- **Guard false** (`I >= J`): the loop exits at `?D = C`, `?I2 = I`, `?J2 = J`. With
  `I+J = n-1` and `I >= J`, the two bands `[0,I)` and `(J,n)` already cover all
  positions except possibly the single centre `I = J` (odd length), which equals
  `A[n-1-I]` trivially since `I = n-1-I`. So `isMirror(?D, A, 0, n)` holds, length is
  unchanged, and `bag` is carried from the invariant. ✓

**Prove (REV).** `def` files the body into `<funcs>` (witnesses `?_:Map`);
`out = reverse(A)` evaluates the argument and `(call)` pushes the caller frame,
gives a fresh scope, binds `a = A`. `i = 0`; `j = len(a) - 1 = n-1`. Then **apply
(LOOP) as a lemma** at `{C := A, I := 0, J := n-1}` — its precondition holds
trivially at entry:
- `I+J = 0 + (n-1) = n-1` (base case of the centre reflection);
- both bands empty: `isMirror(A,A,0,0)` and `isMirror(A,A,n,n)` are vacuous;
- the middle is the whole list: `seg(A,0,n) = seg(A,0,n)`;
- `bag(A) = bag(A)`.
That yields `a` = the mirrored list; `return a` pops the frame and delivers it;
`out |-> ?R` with the three conjuncts. ∎ *(modulo VC-PERM / P1.)*

---

## 4. Machine-detailed proof sketch (for `kprove`)

Each step cites a rule of [`mini-python.k`](mini-python.k); VCs go to Z3 + the
`[simplification]` lemmas. Abbreviations: `seg(L,a,b)`, `isMirror`, `bag` are the
spec functions in [`reverse-spec.k`](reverse-spec.k).

**PART A — (LOOP) by circularity.** Reuse only after >=1 genuine rewrite.
- **A1 progress / guard:** `(while)` -> `B ~> #whileLoop(B, Bdy)`; evaluate `i < j`
  via `(lookup)` x2 + `(lt)`. This `=>+` discharges guardedness **and** (with
  `I+J=n-1`) proves `0 <= I < J < n`, so the body's index reads/writes are in bounds.
- **A2 split** (`#Or` on the guard):
  - **true / `(while-t)`:** `(asgn)` `tmp |-> C[I]`; `(index-assign)` x2 performs the
    swap `C[I<-C[J]][J<-C[I]]` (in-bounds `0 <= I,J < size`); `(asgn)` `i|->I+1`,
    `j|->J-1`; **reuse (LOOP)**. Closes via VC-CENTRE / VC-MIRROR-L / VC-MIRROR-R /
    VC-MID (bundled) and **VC-PERM/P1 (escalation)**.
  - **false / `(while-f)`:** store unchanged; post-state is the entry pattern with
    `?D=C, ?I2=I, ?J2=J`. Closes via the `isMirror` frame + the linear coverage fact
    `I+J=n-1 /\ I>=J => bands [0,I) and (J,n) cover [0,n)` (Z3).

**PART B — (REV) over the call layer.**
`(def)` files the body (witnesses `?_:Map`) -> arg eval + `(call)` pushes
`state(CONT,STORE)`, resets `<store>` to `.Map` -> `#makeBindings((a),(A))` binds
`a |-> A` -> `(asgn)` `i |-> 0` -> `len`+`(sub)` `j |-> size(A)-1` -> **apply (LOOP)
at `{C:=A, I:=0, J:=size(A)-1}`** (precondition trivial, see §3) -> `(return)` pops
the frame, delivers the list -> `(asgn)` `out |-> ?R`. Map-extensionality
`[simplification]` reduces the post-store `#Equals` to the value-level `?R`
obligations.

**Verification conditions.**

| VC | Statement | Discharged by |
|---|---|---|
| **VC-bounds** | `0 <= I < J < n` from `I < J /\ I+J=n-1`; reads/writes of `a[i]`,`a[j]` in `[0,n)` | **Z3** (linear) ✓ |
| **VC-CENTRE** | `(I+1)+(J-1) = I+J = n-1` | **Z3** (linear) ✓ |
| **VC-MIRROR-L/R** | each end-write lands the mirror element: `C'[I]=A[n-1-I]`, `C'[J]=A[n-1-J]` (uses `I+J=n-1` + middle-equality) | **Z3 + map/list ext.** (per-position index facts) ✓ |
| **VC-MID** | the middle `[I+1,J-1]` is untouched by the two end-writes, still `= A` | **Z3 + list ext.** ✓ |
| **VC-coverage** | `I+J=n-1 /\ I>=J` => the two bands cover all positions (centre `=A[n-1-I]` if odd) | **Z3** (linear) ✓ |
| **VC-ext** | post-store cell `#Equals` => value `?R` | **map-extensionality `[simplification]`** ✓ |
| **VC-PERM (P1)** | `bag(L[i<-L[j]][j<-L[i]]) = bag(L)` (one swap preserves the multiset) | **`[ESCALATION BOUNDARY]`** — needs a `Bag`/multiset theory (OOPSLA'20) ✗ |

So **every (H-CLEAN) VC discharges with the bundled tier**; only **VC-PERM/P1**
(the (H-PERM) half) is the open inductive obligation. The structural proof (symbolic
execution + the single circularity) is complete; the *arithmetic-of-data* multiset
fact is the boundary — exactly the kit's documented escalation case for
recursive/inductive data-structure predicates.

> **Logical-redundancy note (honest, does not skip P1).** (H-PERM) is a *semantic
> consequence* of (H-CLEAN): `i |-> n-1-i` is a bijection on `[0,n)`, so
> `out[i]=A[n-1-i]` for all `i` already forces `bag(out)=bag(A)`. But mechanizing
> "index bijection => multiset equality" is itself the inductive/combinatorial fact
> the bundled tier cannot close (it is P1 in whole-list form). So P1 remains an
> `[ESCALATION BOUNDARY]` obligation; we do **not** admit it as `[trusted]`.

---

## 5. FINDINGS — benefit 2 (these do NOT depend on machine-checking)

Formalizing + proving surfaced real, executed findings — full detail in
[`FINDINGS.md`](FINDINGS.md). The ones the formal lens makes sharp:

> **NO total-order precondition (Finding 1, a positive finding).** `reverse`
> compares nothing, so it has no order requirement — incomparable mixes and NaN
> reverse fine. Executed: `[1,"a",None,[3]]` -> `[[3],None,"a",1]`;
> `[1.0,nan,2.0]` -> `[2.0,nan,1.0]`. This is the contrast with `insertion_sort`'s
> hidden total-order bug, and it is why `(REV)` carries no `requires`.

> **O(n) in place (Finding 2, a positive finding).** Linear time, O(1) space —
> contrast an earlier `.insert(0, x)` formulation, which is O(n^2) (each insert
> shifts the whole list). The two-pointer swap does `floor(n/2)` constant-work
> iterations.

> **It MUTATES its input (Finding 4, a behavioral contract point).** Reverses in
> place and returns the **same object** — the opposite of `insertion_sort`'s copy.
> Executed: `b=[10,20,30]; reverse(b)` leaves `b==[30,20,10]` and `reverse(b) is b`.
> The K value-sort model cannot express Python aliasing, so this no-copy behavior
> is a property the contract leaves implicit — keep the `is`/mutation tests.

> **Spec-difficulty = escalation, not a code defect (Finding 6).** The index-
> relation/length half is bundled-tier clean; the permutation half needs an
> inductive `Bag` theory — **route:** OOPSLA'20, LICS'19
> ([`knowledge/sources.md`](../../../formal-verification-kit/knowledge/sources.md);
> `/verify --refresh` re-fetches them). That the bundled tier stops there is the
> honest signal, and the permutation half is logically redundant given the index
> bijection anyway (§4 note).

---

## 6. TEST REDUNDANCY — benefit 1 (DOUBLY conditioned — do not delete anything yet)

> A verified function is proven for *all* inputs in its domain, so in-domain unit
> tests that re-check single points become redundant — **once the proof actually
> discharges.** Here that is gated **twice** (as in insertion-sort).

If `(REV)` were machine-checked, it would prove `reverse(A)` is the positional
reversal (same length, `out[i]=A[n-1-i]`, a permutation) for **every** `Int` list
`A`. The asserts in the `reverse.py` `__main__` self-test map as follows:

| Assertion | In verified domain? | Status |
|---|---|---|
| `reverse([1,2,3,4,5]) == [5,4,3,2,1]` | yes (index relation) | *would-be* redundant |
| `reverse([1,2,3,4]) == [4,3,2,1]` | yes | *would-be* redundant |
| `reverse([]) == []` | yes (base case) | *would-be* redundant |
| `reverse([42]) == [42]` | yes (base case) | *would-be* redundant |
| `x == [5,4,3,2,1]` (input mutated in place) | **frame/aliasing property** | **KEEP** |
| `reverse(y) is y` (returns the same object) | **identity/aliasing property** | **KEEP** |

- **KEEP the two aliasing asserts (`x` mutated, `reverse(y) is y`).** In-place
  mutation and object-identity hold in the model only *by construction* (value-sort
  `List`), **not** as a proof about Python's reference semantics — the K model cannot
  even express aliasing (Finding 4). These pin behavior the proof assumes rather than
  establishes — exactly the kind of test to keep.
- **ADD nothing for a total-order boundary** (unlike insertion-sort): `reverse` has
  no such boundary (Finding 1). Optionally add an `is`-based aliasing test on a fresh
  variable to lock the mutate-in-place contract.

**Honesty gate — stronger than usual here.** Do **not** drop any test now, for
**two** reasons: (1) the MVP did not run `kprove` ("constructed, not
machine-checked"), and (2) the construction has an **open `[ESCALATION BOUNDARY]`
obligation** (VC-PERM/P1) — so `(REV)`'s permutation conjunct is not even fully
constructed-to-`#Top` on paper (its clean half is). The 4 "*would-be* redundant"
value asserts become *actually* redundant only after **both**: the P1 multiset lemma
is supplied (the inductive `Bag` theory), **and** `kprove` returns `#Top`. The two
aliasing asserts stay regardless. Until then, keep everything.

---

## Reproduce the (attempted) machine check

```sh
kompile mini-python.k --backend haskell        # compile the fragment semantics
kast    --backend haskell reverse-spec.k   # (optional) confirm claims parse
kprove  reverse-spec.k                       # EXPECTED HERE: (H-CLEAN) discharges;
                                                 # residual goal on VC-PERM / P1 (the
                                                 # bag multiset half), NOT #Top — until
                                                 # the inductive Bag lemma (escalation)
                                                 # is added.
```

Reaching `#Top` requires **first** adding the multiset (`Bag`) swap-preservation
lemma (P1) per OOPSLA'20 / LICS'19, **then** running the toolchain. Only after a
genuine `#Top` are the §6 value-assert deletions safe (the two aliasing asserts stay
regardless).

---

*Status: constructed, not machine-checked; the index-relation/length half is
structurally complete on the bundled tier, the permutation half is the open P1
inductive obligation. References: kframework.org; runtimeverification/k; K Tutorial
Lesson 1.22. Rosu, "Matching Logic", LMCS 2017. Chen & Rosu, "Matching mu-Logic",
LICS 2019. Rosu & Stefanescu, FM 2012 / LICS 2013 (reachability & Circularity).
Chen et al., unified fixpoint reasoning, OOPSLA 2020 (inductive data structures).*
