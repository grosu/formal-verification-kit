# PROOF — `sum(n)` reachability proof (imitation template)

This is the **condensed, copy-me** version of the full write-up. Use it as the
shape every `/verify` proof should take: a function claim, a loop circularity, a
short English proof, a machine-detailed sketch, and the two plain-language
benefit payoffs (§5 hidden bug = benefit 2, §6 test redundancy = benefit 1).

**Status: constructed, not machine-checked.** The artifacts are built to be
`kompile`/`kprove`-checkable but the toolchain was **not run** in this
environment (MVP stopgap). Treat the result as "constructed" until §"Reproduce"
turns it into "machine-verified."

Artifacts referenced (same directory):
[`summation.py`](summation.py) · [`mini-python.k`](mini-python.k) (the fragment
semantics) · [`mini-python-spec.k`](mini-python-spec.k) (the K claims). The full
upstream write-up with the hand proof, adversarial review, and reproducibility
prompts lives in the **formally-verified-sum** repo
(<https://github.com/grosu/formally-verified-sum>), files
`sum-verification.md` and `sum-correctness-proof.md`.

The program ([`summation.py`](summation.py)):

```python
def sum(n):
    s = 0
    i = 1
    while i <= n:
        s += i
        i += 1
    return s
```

---

## 1. The reachability spec — the (SUM) function claim

The whole-function contract is one reachability rule `φ_pre ⇒ φ_post`: from a
configuration that *defines* `sum` and *calls* it on a non-negative `N`,
execution reaches a terminated configuration whose `result` holds `N*(N+1)/2`.

```
  φ_pre  ≡  ⟨ def sum(n): <body>   result = sum(N) ⟩_k  ⟨ result ↦ _ ⟩_store
            ⟨ .Map ⟩_funcs  ⟨ .List ⟩_stack    ∧   N ≥ 0
  φ_post ≡  ⟨ .K ⟩_k  ⟨ result ↦ N*(N+1)/2 ⟩_store  ⟨ ?_ ⟩_funcs  ⟨ .List ⟩_stack
```

As the **(SUM)** `claim` in [`mini-python-spec.k`](mini-python-spec.k):

```k
claim
  <k>
    def sum ( n ) : INDENT
      s = 0
      i = 1
      while i <= n : INDENT s += i  i += 1 DEDENT
      return s
    DEDENT
    result = sum ( N:Int )
  => .K ... </k>
  <funcs> .Map => ?_:Map </funcs>
  <store> result |-> (_:Int => N *Int (N +Int 1) /Int 2) </store>
  <stack> .List </stack>
  requires N >=Int 0
  [all-path]
```

Reading: `requires N >=Int 0` is the **precondition** (framed on every step).
The `<k>` cell rewrites the program to `.K` (terminated). The post-`<store>`
asserts `result |-> N*(N+1)/2`; `<funcs> .Map => ?_:Map` says *some* function
table now exists (the `?_` existential is witnessed by the `sum` entry);
`<stack> .List` says the call stack is balanced again. `[all-path]` demands
*every* terminating path hit the target — sound here because mini Python is
deterministic, so all-path coincides with one-path here. This is **partial
correctness**: it constrains terminating runs
and says nothing about whether the loop halts.

---

## 2. The loop circularity — the (LOOP) claim

The proof turns on one auxiliary claim about the loop, generalized over the
accumulator `S` and the counter `I`, with side condition `I ≤ N+1` and the
running closed form `(I+N)*(N−I+1)/2`:

```
  (LOOP)   ⟨ while i<=n: (s+=i; i+=1) | s↦S, i↦I, n↦N ⟩  ∧  I ≤ N+1
       ⇒   ⟨ .K | s ↦ S + (I+N)·(N−I+1)/2,  i ↦ N+1,  n ↦ N ⟩
```

As the **(LOOP)** `claim` in [`mini-python-spec.k`](mini-python-spec.k):

```k
claim
  <k> while i <= n : INDENT s += i  i += 1 DEDENT => .K ... </k>
  <store>
    s |-> (S:Int => S +Int (I +Int N) *Int (N -Int I +Int 1) /Int 2)
    i |-> (I:Int => N +Int 1)
    n |-> N:Int
  </store>
  requires I <=Int N +Int 1
  [all-path]
```

It reads: *running the loop from counter `i = I` (with `I ≤ N+1`) adds
`Σ_{k=I}^{N} k = (I+N)*(N−I+1)/2` to `s` and leaves `i = N+1`.* Equal "difference"
form: `(N*(N+1) − (I−1)*I)/2`. At `I = 1` it gives the whole sum `N*(N+1)/2`.

---

## 3. Informal proof (English)

Reachability logic replaces the hand-chosen *loop invariant* with
**coinduction**: K adds every claim in the module to its hypotheses, so **(LOOP)
may assume itself** while proving itself — *provided* it first makes one genuine
step (guardedness). The running-sum formula plays the role the invariant used to.

**Prove (LOOP).** Run the loop one step. `(while)` evaluates the guard `i <= n`
— that genuine first step earns the right to reuse the hypothesis — then case
split on the guard:

- **Guard true (`I ≤ N`):** the body runs. `s += i` makes `s = S + I`;
  `i += 1` makes `i = I + 1`; control returns to the same `while`. **Invoke
  (LOOP) itself** at `S := S+I, I := I+1` (its precondition `I+1 ≤ N+1` follows
  from `I ≤ N`). The one arithmetic fact to check is that peeling the first term
  is consistent: `I + Σ_{k=I+1}^{N} k = Σ_{k=I}^{N} k`. ✓
- **Guard false (`I > N`, and `I ≤ N+1` from the precondition):** then `I = N+1`,
  the body never runs, `s` is unchanged, and the formula gives the empty sum `0`.
  So `s = S + 0` and `i = N+1`. ✓

Both branches land on (LOOP)'s post-state, and the hypothesis was used only after
a real step, so the circularity discharges. The side condition **`I ≤ N+1` is
necessary**: drop it and for `I ≥ N+2` the body still never runs but the formula
is non-zero — false.

**Prove (SUM).** Execute the program against the semantics: `def sum` files the
body into `<funcs>`; `result = sum(N)` evaluates the argument, and `(call)`
pushes the caller's frame, gives the callee a fresh scope, and binds `n = N`. The
body runs `s = 0`, `i = 1`, then the loop — and here we **use (LOOP) as a lemma**
at `S = 0, I = 1` (its precondition `1 ≤ N+1` follows from `N ≥ 0`), making
`s = 0 + N*(N+1)/2`. Then `return s` pops the frame, restores the caller store,
and the returned value is assigned to `result`. Final store:
`result |-> N*(N+1)/2` — exactly the spec. ∎

---

## 4. Machine-detailed proof sketch (for `kprove`)

The symbolic-execution skeleton each step cites a rule of
[`mini-python.k`](mini-python.k); the VCs are discharged by Z3 plus the
`[simplification]` lemmas in [`mini-python-spec.k`](mini-python-spec.k).
Abbreviation: `cfA(I,N) := (I +Int N) *Int (N -Int I +Int 1) /Int 2 = Σ_{k=I}^{N} k`,
so `cfA(1,N) = N*(N+1)/2`.

**PART A — (LOOP) by circularity.** Reuse (LOOP) only after ≥ 1 genuine rewrite.
- **A1 progress:** `(while)` → `(i<=n) ~> #whileLoop(i<=n, Bdy)`. This `=>+`
  transition discharges guardedness.
- **A2 guard:** `<=` is `seqstrict` → `(lookup)` `i⇒I`, `n⇒N`; `(leq)` →
  `I <=Int N`.
- **A3 split** (`#Or` on `I <=Int N` under `I <=Int N+1`):
  - **true / `(while-t)`:** rebuild the `while` (never an `if`); `(augasgn)`+
    `(add)`+`(asgn)` give `s ↦ S +Int I`, `i ↦ I +Int 1`; **reuse (LOOP)** at
    `{S:=S+Int I, I:=I+Int 1}`. Closes via **VC1**.
  - **false / `(while-f)`:** antisymmetry ⇒ `I = N+1`; store unchanged. Closes
    via **VC2** (`cfA(N+1,N)=0`).

**PART B — (SUM) over the real call layer.**
`(def)` files the body (witnesses `?_:Map`) → arg eval + `(call)` pushes
`state(CONT, STORE)` and resets `<store>` to `.Map` → `#makeBindings((n),(N))`
binds `n ↦ N` → `(asgn)` `s ↦ 0`, `i ↦ 1` → **apply (LOOP) at `{S:=0, I:=1}`**
(precondition `1 <=Int N+1` from `N >=Int 0`), `s ↦ cfA(1,N)` (**VC3**) →
`(return)` pops the frame, restores caller store, delivers the `Int` → `(asgn)`
`result ↦ N*(N+1)/2`. Map-extensionality `[simplification]` reduces the
post-store `#Equals` to the scalar VC3.

**Verification conditions** (every numerator is a product of consecutive
integers, hence even, so each `/Int 2` is exact):

| VC | Statement | Discharged by |
|---|---|---|
| **VC1** | `I + cfA(I+1,N) = cfA(I,N)` | exact-halving `[simplification]` + Z3 |
| **VC2** | `I = N+1 ⇒ cfA(I,N) = 0` | Z3 (zero factor) |
| **VC3** | `cfA(1,N) = N*(N+1)/2` | Z3 (after map-extensionality) |
| sides | `N≥0 ⇒ 1≤N+1`; `I≤N ⇒ I+1≤N+1` | Z3 (linear) |

The exact-halving `[simplification]` lemma (a `*2`-then-`/2` cancellation) carries
an evenness `modInt` side condition; that obligation is *exactly* the "every
numerator is a product of consecutive integers, hence even" fact stated above the
table, which is what discharges the `modInt` guard in
[`mini-python-spec.k`](mini-python-spec.k).

---

## 5. FINDINGS — a hidden subtle bug (benefit 2)

> **Formalizing surfaced a missing precondition.** Difficulty writing a clean
> spec is itself a bug signal — here it forced the `requires N >=Int 0` guard.

**The `n < 0` case is wrong.** The verified contract only holds for `n ≥ 0`. For
negative `n` the loop never runs, so the code returns `s = 0` — but the intended
"sum from 1 to n" closed form `N*(N+1)/2` is **not** `0` there.

Plainly, input → observed vs expected:

| input `n` | code returns (observed) | `n*(n+1)/2` (expected) |
|---|---|---|
| `-3` | `0` | `3` |
| `-1` | `0` | `0` |
| `-5` | `0` | `10` |

So for `n = -3` the code yields `0` but the formula yields `3` — they disagree.
**Recommendation:** either add a precondition `n ≥ 0` (the function is only
defined on non-negative inputs — what `(SUM)`'s `requires N >=Int 0` encodes), or
split the contract on the sign of `n` (loop never runs ⇒ `sum(n) = 0` for `n ≤ 0`;
`N*(N+1)/2` for `n ≥ 0`). This was invisible to a quick read; the spec made it
explicit.

---

## 6. TEST REDUNDANCY — fewer tests, faster CI (benefit 1)

> **A verified function is proven correct for all inputs in its domain**, so unit
> tests that only re-check points inside that domain become redundant.

Once `(SUM)` is machine-checked, it proves `sum(n) = n*(n+1)/2` for **every**
`n ≥ 0`. Any unit test asserting a single in-domain point is subsumed:

- `sum(5) == 15` → subsumed (`5*6/2 = 15`, and `5 ≥ 0`). **Redundant.**
- `sum(1) == 1`  → subsumed (`1*2/2 = 1`,  and `1 ≥ 0`). **Redundant.**
- `sum(0) == 0`  → subsumed (`0*1/2 = 0`,  and `0 ≥ 0`). **Redundant.**

**Keep the out-of-domain boundary test.** A test like `sum(-1) == 0` (or any
`n ≤ 0` boundary check) is **outside** the verified domain `n ≥ 0` and is exactly
where the §5 finding lives — **keep it** (it pins behavior the proof does not
cover, and guards against a regression if the sign split is later added).

**Conditioned on machine-checking.** This recommendation is conservative and
recommendation-only. The MVP **does not run `kprove`** — the proof here is
"constructed, not machine-checked." Do **not** delete any test until the claims
actually discharge (`kprove` returns `#Top`); see "Reproduce" below.

---

## Reproduce the machine check

```sh
kompile mini-python.k --backend haskell      # compile the fragment semantics
kast    --backend haskell mini-python-spec.k # (optional) confirm claims parse
kprove  mini-python-spec.k                    # expected: #Top  (all claims proved)
```

`kprove` inherits the Haskell backend from the `kompile`d definition above, so it
needs no `--backend haskell` of its own.

A `#Top` result upgrades everything above from **constructed** to
**machine-verified**, and only then are the §6 test deletions safe.

---

*Upstream full write-up (hand proof, adversarial review, reproducibility
prompts): the **formally-verified-sum** repo
(<https://github.com/grosu/formally-verified-sum>) —
`sum-verification.md`, `sum-correctness-proof.md`.
References: kframework.org; runtimeverification/k; K Tutorial Lesson 1.22.
Roșu, "Matching Logic", LMCS 2017. Chen & Roșu, "Matching μ-Logic", LICS 2019.
Roșu & Ștefănescu, FM 2012 / LICS 2013 (reachability logic & Circularity).*
