# PROOF — `sum_to_n(n)` reachability proof

Constructed by the formal-verification-kit `/verify` step for the **down-counting**
`sum_to_n` in [`sum.py`](sum.py). Same shape as the kit's worked `sum` example, but
proving the `>=` / `-=` mirror: `i = n; while i >= 1: total += i; i -= 1`.

**Status: constructed, not machine-checked.** The K toolchain is not installed in
this environment, so `kompile`/`kprove` were **not run**. The artifacts are built to
be checkable; see [Reproduce](#reproduce-the-machine-check). The Findings (§5) and
the proof structure hold regardless; only the *test-removal* recommendation (§6) is
gated on an actual `#Top`.

**Contract verified: option (A)** — the contract *as written*, `n >= 0`. This proof
says **nothing** about `n < 0`; that region is the §5 finding, deliberately outside
the verified domain. (Options B "prove the as-built behavior over all integers" and
C "fix then verify" remain one `/formalize` step away.)

Artifacts (same directory): [`sum.py`](sum.py) · [`mini-python.k`](mini-python.k)
(fragment semantics) · [`sum-down-spec.k`](sum-down-spec.k) (the K claims) ·
[`SPEC.md`](SPEC.md) (spec note) · [`FINDINGS.md`](FINDINGS.md).

The program:

```python
def sum_to_n(n):
    total = 0
    i = n
    while i >= 1:
        total += i
        i -= 1
    return total
```

Abbreviation used throughout: **`cf(I) := I *Int (I +Int 1) /Int 2 = Σ_{k=1}^{I} k`**
(the down-counting running sum, from the current counter down to 1). Note
`cf(N) = N*(N+1)/2` *syntactically* — this matters in §4.

---

## 1. The reachability spec — the (SUM) function claim

The whole-function contract is one reachability rule `φ_pre ⇒ φ_post`: from a
configuration that *defines* `sum_to_n` and *calls* it on a non-negative `N`,
execution reaches a terminated configuration whose `result` holds `N*(N+1)/2`.

```
  φ_pre  ≡  ⟨ def sum_to_n(n): <body>   result = sum_to_n(N) ⟩_k  ⟨ result ↦ _ ⟩_store
            ⟨ .Map ⟩_funcs  ⟨ .List ⟩_stack    ∧   N ≥ 0
  φ_post ≡  ⟨ .K ⟩_k  ⟨ result ↦ N*(N+1)/2 ⟩_store  ⟨ ?_ ⟩_funcs  ⟨ .List ⟩_stack
```

As the **(SUM)** `claim` in [`sum-down-spec.k`](sum-down-spec.k):

```k
claim
  <k>
    def sum_to_n ( n ) : INDENT
      total = 0
      i = n
      while i >= 1 : INDENT total += i  i -= 1 DEDENT
      return total
    DEDENT
    result = sum_to_n ( N:Int )
  => .K ... </k>
  <funcs> .Map => ?_:Map </funcs>
  <store> result |-> (_:Int => N *Int (N +Int 1) /Int 2) </store>
  <stack> .List </stack>
  requires N >=Int 0
  [all-path]
```

`requires N >=Int 0` is the **precondition** (framed on every step). The `<k>` cell
rewrites to `.K` (terminated). The post-`<store>` asserts `result |-> N*(N+1)/2`;
`<funcs> .Map => ?_:Map` says *some* function table now exists (the `?_` existential
is witnessed by the `sum_to_n` entry); `<stack> .List` says the call stack is
balanced again. `[all-path]` demands *every* terminating path hit the target — sound
here because mini Python is deterministic, so all-path coincides with one-path. This
is **partial correctness**: it constrains terminating runs and says nothing about
whether the loop halts.

---

## 2. The loop circularity — the (LOOP) claim

The proof turns on one auxiliary claim about the loop, generalized over the
accumulator `T` and the counter `I`, with side condition `I ≥ 0` and the running
closed form `cf(I) = I*(I+1)/2`:

```
  (LOOP)   ⟨ while i>=1: (total+=i; i-=1) | total↦T, i↦I, … ⟩  ∧  I ≥ 0
       ⇒   ⟨ .K | total ↦ T + cf(I),  i ↦ 0,  … ⟩
```

As the **(LOOP)** `claim` in [`sum-down-spec.k`](sum-down-spec.k):

```k
claim
  <k> while i >= 1 : INDENT total += i  i -= 1 DEDENT => .K ... </k>
  <store>
    total |-> (T:Int => T +Int I *Int (I +Int 1) /Int 2)
    i     |-> (I:Int => 0)
    ...
  </store>
  requires I >=Int 0
  [all-path]
```

It reads: *running the loop from counter `i = I` (with `I ≥ 0`) adds
`Σ_{k=1}^{I} k = cf(I)` to `total` and leaves `i = 0`.* The `...` store frame is the
first thing that's different from the up-counting example: the guard `i >= 1`
compares to the **constant** `1`, so **`n` does not occur in the loop spec at all**.
The loop's effect depends only on `total` and `i`; everything else in scope
(`n ↦ N`) is framed through unchanged.

---

## 3. Informal proof (English)

Reachability logic replaces the hand-chosen *loop invariant* with **coinduction**:
K adds every claim in the module to its hypotheses, so **(LOOP) may assume itself**
while proving itself — *provided* it first makes one genuine step (guardedness). The
running-sum formula `cf(I)` plays the role the invariant used to.

**Prove (LOOP).** Run the loop one step. `(while)` evaluates the guard `i >= 1` —
that genuine first step earns the right to reuse the hypothesis — then case split on
the guard:

- **Guard true (`I ≥ 1`):** the body runs. `total += i` makes `total = T + I`;
  `i -= 1` makes `i = I − 1`; control returns to the same `while`. **Invoke (LOOP)
  itself** at `T := T+I, I := I−1` (its precondition `I−1 ≥ 0` follows from `I ≥ 1`).
  The one arithmetic fact to check is that peeling the *top* term is consistent:
  `I + Σ_{k=1}^{I−1} k = Σ_{k=1}^{I} k`, i.e. `I + cf(I−1) = cf(I)`. ✓
- **Guard false (`I < 1`, and `I ≥ 0` from the precondition):** then `I = 0`, the
  body never runs, `total` is unchanged, and `cf(0) = 0`. So `total = T + 0` and
  `i = 0`. ✓

Both branches land on (LOOP)'s post-state, and the hypothesis was used only after a
real step, so the circularity discharges. The side condition **`I ≥ 0` is
necessary**: drop it and for `I ≤ −2` the body still never runs (added sum `0`) but
`cf(I) > 0` — false. (It happens to survive at `I = −1`, where `cf(−1) = 0`; the
tight bound is `I ≥ −1`. We state `I ≥ 0` — it mirrors the loop exiting at `0` and is
exactly what the function entry supplies.)

**Prove (SUM).** Execute the program against the semantics: `def sum_to_n` files the
body into `<funcs>`; `result = sum_to_n(N)` evaluates the argument, and `(call)`
pushes the caller's frame, gives the callee a fresh scope, and binds `n = N`. The
body runs `total = 0`, then `i = n` — so the loop is entered at **`i = N`**. Here we
**use (LOOP) as a lemma** at `T = 0, I = N` (its precondition `N ≥ 0` is the
function precondition *verbatim* — no weakening), making `total = 0 + cf(N)`. Then
`return total` pops the frame, restores the caller store, and the returned value is
assigned to `result`. Since `cf(N) = N*(N+1)/2` **syntactically**, the final store is
`result |-> N*(N+1)/2` — exactly the spec. ∎

> **A structural payoff of counting down.** Because the loop is entered at the *top*
> counter `I = N`, the loop's closed form `cf(N)` *is* the target `N*(N+1)/2` with no
> reconciliation. The up-counting example needed an extra VC (`cfA(1,N) = N*(N+1)/2`)
> precisely because it entered at `I = 1` with a differently-parameterized closed
> form. Down-counting makes the function postcondition fall out of the loop invariant
> for free.

---

## 4. Machine-detailed proof sketch (for `kprove`)

Each step cites a rule of [`mini-python.k`](mini-python.k); VCs are discharged by Z3
plus the `[simplification]` lemmas in [`sum-down-spec.k`](sum-down-spec.k).

**PART A — (LOOP) by circularity.** Reuse (LOOP) only after ≥ 1 genuine rewrite.
- **A1 progress:** `(while)` → `(i >= 1) ~> #whileLoop(i >= 1, Bdy)`. This `=>⁺`
  transition discharges guardedness.
- **A2 guard:** `>=` is `seqstrict` → `(lookup)` `i ⇒ I`; literal `1`; `(geq)` →
  `I >=Int 1`.
- **A3 split** (`#Or` on `I >=Int 1` under `I >=Int 0`):
  - **true / `(while-t)`:** rebuild the `while` (never an `if`); `(augasgn +=)`
    desugars `total += i` to `total = total + i`, then `(add)`+`(asgn)` give
    `total ↦ T +Int I`; `(augasgn -=)` desugars `i -= 1` to `i = i - 1`, then
    `(sub)`+`(asgn)` give `i ↦ I -Int 1`; **reuse (LOOP)** at
    `{T := T +Int I, I := I -Int 1}`. Closes via **VC1**.
  - **false / `(while-f)`:** `notBool (I >=Int 1)` with `I >=Int 0` ⇒ `I = 0`; store
    unchanged. Closes via **VC2** (`cf(0) = 0`).

**PART B — (SUM) over the real call layer.**
`(def)` files the body (witnesses `?_:Map`) → arg eval + `(call)` pushes
`state(CONT, STORE)` and resets `<store>` to `.Map` → `#makeBindings((n),(N))` binds
`n ↦ N` → `(asgn)` `total ↦ 0` → `(lookup)`+`(asgn)` `i ↦ N` → **apply (LOOP) at
`{T := 0, I := N}`** (precondition `N >=Int 0` is the contract precondition itself),
`total ↦ 0 +Int cf(N)` → `0 +Int _` collapses → `(return)` pops the frame, restores
the caller store, delivers the `Int` → `(asgn)` `result ↦ N*(N+1)/2`.
Map-extensionality `[simplification]` reduces the post-store `#Equals` to the scalar,
which is then the **syntactic identity** `cf(N) = N*(N+1)/2` — *no VC3*.

**Verification conditions** (every numerator is `X*(X+1)`, a product of consecutive
integers, hence even, so each `/Int 2` is exact):

| VC | Statement | Discharged by |
|---|---|---|
| **VC1** | `I + cf(I−1) = cf(I)`, i.e. `I + (I−1)·I/2 = I·(I+1)/2` | exact-halving `[simplification]` + Z3 |
| **VC2** | `I = 0 ⇒ cf(I) = 0` | Z3 (zero factor) |
| (fn) | `cf(N) = N*(N+1)/2`; `0 +Int x = x` | syntactic identity + Z3 (after map-extensionality) |
| sides | `N≥0 ⇒ N≥0` (entry); `I≥1 ⇒ I−1≥0` (step) | Z3 (linear, trivial) |

**Two simplifications over the up-counting template, both real:**

1. **Only the *first* exact-halving lemma is exercised.** Every halved product here
   is in the consecutive-integer shape `X*(X+1)` (VC1 uses `X = I−1` and `X = I`), so
   `(X *Int (X +Int 1)) /Int 2 *Int 2 => X *Int (X +Int 1)` suffices. The template's
   second lemma — the general `((A+B)*C)/2 *2` form with the `modInt 2 == 0` guard —
   was needed only because the up-counting `cfA = (I+N)*(N−I+1)/2` is a product of two
   *distinct* linear forms. It is **dead for this program** and could be dropped from
   [`sum-down-spec.k`](sum-down-spec.k) (kept defensively; a never-firing
   `[simplification]` is harmless).
2. **No VC3.** As noted in §3, entering the loop at `I = N` makes `cf(N)` the target
   term-for-term; the function level needs only map-extensionality and `0 +Int x = x`.

---

## 5. FINDINGS — a hidden subtle bug (benefit 2)

> **Formalizing surfaced a missing precondition.** Difficulty writing a clean spec is
> itself a bug signal — here it forced the `requires N >=Int 0` guard, and the loop's
> load-bearing `I >= 0`. Full detail in [`FINDINGS.md`](FINDINGS.md).

**The `n < 0` case is wrong** (specifically `n ≤ −2`). The verified contract only
holds for `n ≥ 0`. For negative `n` the loop never runs (it starts at `i = n < 1`),
so the code returns `total = 0` — but the intended "sum from 1 to n" closed form
`n*(n+1)/2` is **not** `0` there.

| input `n` | code returns (observed) | `n*(n+1)/2` (expected) | agree? |
|---|---|---|---|
| `-3` | `0` | `3`  | ✗ |
| `-2` | `0` | `1`  | ✗ |
| `-1` | `0` | `0`  | ✓ (coincidence) |
| `0`  | `0` | `0`  | ✓ |

So for `n = -3` the code yields `0` but the formula yields `3` — they disagree.
**This proof does not launder that**: it proves correctness *only* on `n ≥ 0`, the
side of the fence the finding drew. The other side is left explicitly unverified.
**Recommendation:** enforce `n ≥ 0` (option C), or split the contract on the sign of
`n` and prove the as-built behavior over all integers (option B).

> **Deployment caveat.** `sum.py`'s `__main__` does `int(input(...))`, which parses
> negative inputs and passes them straight to `sum_to_n` — so the program's *own*
> entry point can violate the precondition this proof assumes. A green `#Top` on
> (SUM) means "correct *given* `n ≥ 0`," not "correct for every CLI input."

---

## 6. TEST REDUNDANCY — fewer tests, faster CI (benefit 1)

> **A verified function is proven correct for all inputs in its domain**, so unit
> tests that only re-check points inside that domain become redundant.

Once `(SUM)` is machine-checked, it proves `sum_to_n(n) = n*(n+1)/2` for **every**
`n ≥ 0`. Any unit test asserting a single in-domain point is subsumed:

- `sum_to_n(10) == 55` → subsumed (`10*11/2 = 55`, and `10 ≥ 0`). **Redundant.**
  *(This is exactly the check run earlier — `echo 10 | python3 sum.py` → 55.)*
- `sum_to_n(5)  == 15` → subsumed (`5*6/2 = 15`,  and `5 ≥ 0`). **Redundant.**
- `sum_to_n(0)  == 0`  → subsumed (`0*1/2 = 0`,   and `0 ≥ 0`). **Redundant.**

**Keep the out-of-domain boundary test.** A test like `sum_to_n(-2) == 0` is
**outside** the verified domain `n ≥ 0` and is exactly where the §5 finding lives —
**keep it** (it pins behavior the proof does not cover, and would catch a regression
if the sign split is later added).

**No test suite exists yet.** `sum.py` currently ships no unit tests, so the above is
advisory for any tests you add: under contract (A), point-tests on `n ≥ 0` are
redundant the moment `kprove` returns `#Top`; negative-`n` tests are not.

**Conditioned on machine-checking.** Recommendation-only and conservative. The K
toolchain was **not run** here — this proof is "constructed, not machine-checked." Do
**not** delete any test until the claims actually discharge (`kprove` → `#Top`).

---

## Reproduce the machine check

```sh
kompile mini-python.k --backend haskell      # compile the fragment semantics
kast    --backend haskell sum-down-spec.k # (optional) confirm claims parse
kprove  sum-down-spec.k                    # expected: #Top  (all claims proved)
```

`kprove` inherits the Haskell backend from the `kompile`d definition, so it needs no
`--backend haskell` of its own. A `#Top` upgrades everything above from
**constructed** to **machine-verified**, and only then are the §6 test deletions safe.

---

*Imitates the formal-verification-kit `examples/sum/PROOF.md`, adapted for the
down-counting `>=`/`-=` formulation. References: kframework.org;
runtimeverification/k; K Tutorial Lesson 1.22. Roșu, "Matching Logic", LMCS 2017.
Chen & Roșu, "Matching μ-Logic", LICS 2019. Roșu & Ștefănescu, FM 2012 / LICS 2013
(reachability logic & the Circularity rule).*
