# PROOF — `factorial(n)` reachability proof

This is the **recursion + no-closed-form** member of the `sum-*` / recursion cluster:
same shape as the `sum-recursive` sibling (no loop, so **no loop-invariant**; the
circularity is on the **recursive call's contract** `(REC)`), but the postcondition is
**`n!`, which has no polynomial closed form**, so it is stated with a **spec-only
recursive function symbol** `fact` rather than an arithmetic term.

**Status: constructed, not machine-checked.** The artifacts are built to be
`kompile`/`kprove`-checkable but the K toolchain was **not run** here. Treat the result
as "constructed" until §"Reproduce" turns it into "machine-verified."

The program ([`factorial.py`](factorial.py), reduced to its in-domain core — the
`if n < 0: raise ValueError` guard is a no-op on `n >= 0` and becomes Finding 1, not
modeled):

```python
def factorial(n):
    if n == 0:
        return 1
    return n * factorial(n - 1)
```

---

## 1. The reachability spec — the (FACT) function claim

The whole-function contract is one reachability rule `φ_pre ⇒ φ_post`: from a
configuration that *defines* `factorial` and *calls* it on a non-negative `N`,
execution reaches a terminated configuration whose `result` holds `fact(N)` (the
mathematical `N!`).

As the **(FACT)** `claim` in [`factorial-spec.k`](factorial-spec.k):

```k
claim
  <k>
    def factorial ( n ) : INDENT
      if n == 0 : INDENT return 1 DEDENT
      return n * factorial ( n - 1 )
    DEDENT
    result = factorial ( N:Int )
  => .K ... </k>
  <funcs> .Map => ?_:Map </funcs>
  <store> result |-> (_:Int => fact ( N )) </store>
  <stack> .List </stack>
  requires N >=Int 0
  [all-path]
```

`requires N >=Int 0` is the precondition; `<funcs> .Map => ?_:Map` says the function
table now exists; `<stack> .List` says the call stack is balanced again after the
(possibly deep) recursion returns. Partial correctness, `[all-path]` (the fragment is
deterministic, so all-path coincides with one-path).

---

## 2. The recursion circularity — the (REC) claim

With no loop, the coinductive hypothesis is the **function's own contract**:
evaluating a call `factorial(N)` at the head of `<k>` reduces to the value `fact(N)`,
threading the continuation `CONT` unchanged, with `<store>`/`<stack>` net unchanged
(the call pushes a frame and return pops it).

```k
claim
  <k> factorial ( N:Int ) ~> CONT:K
   => fact ( N ) ~> CONT </k>
  <funcs> ... factorial |-> def factorial ( n ) : INDENT
        if n == 0 : INDENT return 1 DEDENT
        return n * factorial ( n - 1 )
      DEDENT ... </funcs>
  <store> STORE </store>
  <stack> STK:List </stack>
  requires N >=Int 0
  [all-path]
```

This is the exact analog of the loops' `(LOOP)` claim — **K uses every claim as its
own coinduction hypothesis**, so `(REC)` discharges its own inner call
`factorial(N-1)`. The **back-edge is the recursive call**, not a loop guard, and
**guardedness** is supplied by the `call` step taken before the hypothesis is reused.

---

## 3. The spec-only `fact` symbol (the no-closed-form move)

`factorial(n) = n!` has **no polynomial / no fixed algebraic closed form**, so the
postcondition cannot be an arithmetic term (contrast `sum-recursive`'s `N*(N+1)/2`).
Following the kit's reachability-and-circularities primer §7 (which names "factorial's
`N!/(I-1)!`" as needing "a recursively-defined symbol and its own simplification
lemmas"), we declare a **spec-only** recursive function in the `VERIFICATION` module:

```k
syntax Int ::= fact(Int) [function, total]
rule fact(0)       => 1
rule fact(N:Int)   => N *Int fact(N -Int 1)   requires N >Int 0
```

`fact` is **spec vocabulary, not a language construct** — `mini-python.k` (the language
the program is written in) never mentions it; the program never names it. It exists
only to *state* `(FACT)`/`(REC)`. Crucially it **mirrors `factorial`'s own recursion**,
which is exactly why the recursive-step VC discharges by unfolding rather than by a
bespoke arithmetic lemma.

---

## 4. Informal proof (English)

**Prove (REC)** by guarded coinduction (assume `(REC)`, reuse only after a real step):

1. **Call step (progress).** `factorial(N)` fires the `(call)` rule: it pushes the
   caller's frame `state(CONT, STORE)` onto `<stack>`, gives the callee a fresh scope
   binding `n = N`, and runs the body. *This `=>⁺` step discharges guardedness.*
2. **Case-split on the base/recursive branch** (the `if n == 0`):
   - **Base case (`N == 0`).** `if true` runs `return 1`; the `(return)` rule pops the
     frame, restores `STORE`, and delivers `1` to `CONT`. The call reduced to
     `1 ~> CONT`. **VC-base:** `N == 0 ⇒ fact(N) = 1` — by `fact`'s base rule
     `fact(0) = 1`. ✓
   - **Recursive case (`N ≠ 0`, i.e. `N ≥ 1`).** `if false` is skipped; control reaches
     `return n * factorial(n − 1)`. Evaluating the argument gives the inner call
     `factorial(N − 1)` — **invoke `(REC)` on it** (its precondition `N − 1 ≥ 0`
     follows from `N ≥ 1`), reducing it to `fact(N−1)`. So the returned value is
     `N * fact(N−1)`; `(return)` pops the frame and delivers it to `CONT`. **VC-step:**
     `N * fact(N−1) = fact(N)` — by `fact`'s defining rule
     `fact(N) = N *Int fact(N−1)` for `N > 0` (definitional unfolding). ✓

Both branches land on `(REC)`'s post-state, and the hypothesis was used only after the
`call` step (and the recursive call's own `call` step), so the circularity discharges:
`A ⊢ (REC)`.

**Prove (FACT)** using `(REC)` as a lemma: `def` files the body into `<funcs>`
(witnessing `?_:Map`); `result = factorial(N)` evaluates its RHS by **`(REC)` at `N`**
(precondition `N ≥ 0`), giving `fact(N)`; the assignment lands `result |-> fact(N)` and
the stack is `.List`. ∎

---

## 5. Machine-detailed proof sketch (for `kprove`)

**PART A — (REC) by circularity.** Reuse `(REC)` only after ≥ 1 genuine rewrite.
- **A1 progress:** `(call)` → pushes `state(CONT, STORE)`, resets `<store>` to a fresh
  scope, `#makeBindings((n),(N))` binds `n ↦ N`, queues `BODY`. This `=>⁺` discharges
  guardedness.
- **A2 guard:** `if n == 0` — `(lookup)` `n ⇒ N`, `(==)` ⇒ `N ==Int 0`.
- **A3 split** (`#Or` on `N ==Int 0`, both under `N >=Int 0`):
  - **base `N == 0` / `if true`:** `return 1` ⇒ `(return)` pops the frame, `1 ~> CONT`.
    Closes via **VC-base** (`fact(0) ⇒ 1`, the base rule).
  - **recursive `N =/=Int 0` / `if false`:** reach `return n * factorial(n−1)`;
    `*`/call are `seqstrict` ⇒ `(lookup)` `n ⇒ N`, `(−)` `n−1 ⇒ N−Int 1`; the inner
    call `factorial(N−Int 1) ~> CONT'` — **reuse (REC)** at `N−Int 1` (precondition
    `N−1 >=Int 0` from `N >=Int 1`) ⇒ `fact(N−Int 1)`; `(*)` ⇒ `N *Int fact(N−Int 1)`;
    `(return)` pops the frame ⇒ `(N *Int fact(N−Int 1)) ~> CONT`. Closes via **VC-step**.

**PART B — (FACT).** `(def)` files the body (witnesses `?_:Map`) → `result =
factorial(N)`: arg already `Int`, **apply (REC) at `N`** ⇒ `fact(N) ~> (result = ☐)`
→ `(asgn)` `result |-> fact(N)`. Map-extensionality `[simplification]` reduces the
post-store `#Equals` to the scalar `fact(N)`.

**Verification conditions** (note: factorial uses **no division** — there is no
truncating `/Int`, hence **no exact-halving lemma**; the nonlinear step is settled by
`fact`'s own rule):

| VC | Statement | Discharged by |
|----|-----------|---------------|
| **VC-base** | `N = 0 ⇒ fact(N) = 1` | `fact`'s base rule `fact(0) => 1` |
| **VC-step** | `N ≥ 1 ⇒ N *Int fact(N−1) = fact(N)` | `fact`'s defining rule `fact(N) => N *Int fact(N−1) requires N >Int 0` — **definitional unfolding** (a syntactic rewrite, RHS→LHS); no arithmetic lemma needed |
| map ext. | `M[K<-V] #Equals M[K<-V'] ⇒ V #Equals V'` | `[simplification]`, then Z3 |

### [ESCALATION BOUNDARY] — honest scope of the constructed proof

The two VCs above and the symbolic-execution skeleton are constructed at the kit's
bundled tier. **One residual obligation is flagged as a boundary, not faked as
`[trusted]`:**

- **Soundness of the `fact` spec symbol as a `[function, total]` definition.** The
  rules `fact(0) => 1` and `fact(N) => N *Int fact(N−1) requires N >Int 0` are *intended*
  to define a **total** function on `N >= 0`. Establishing that they (a) terminate
  / are well-founded (the argument strictly decreases and is bounded below by `0`) and
  (b) are confluent / non-overlapping so `fact` is genuinely a function — i.e. that the
  `[total]` attribute is *earned* — is exactly the **least-fixpoint / inductive-definition**
  reasoning that the bundled fast-path does **not** discharge mechanically. `kprove` will
  *use* the `fact` rules as given (so the `(REC)`/`(FACT)` proof goes through *relative to*
  `fact` being well-defined), but the well-definedness of `fact` itself is an
  **`[ESCALATION BOUNDARY]`** obligation. Route it to the μ-logic line:
  `chen-rosu-2019-lics` (Matching μ-Logic, LICS 2019) and inductive sorts in
  `chen-lucanu-rosu-2020-tr` (see [`sources.md`](../../../formal-verification-kit/knowledge/sources.md)).
  **Do not** read the `(REC)`/`(FACT)` discharge as also certifying `fact`'s
  well-definedness — that is the one piece the constructed proof assumes and flags.

Everything else (the call/return symbolic execution, the base/recursive case split, the
unfolding step VC, the map-extensionality closure) is within the bundled tier — and is
*simpler* than `sum-recursive`'s, since no division / exact-halving arithmetic arises.

---

## 6. FINDINGS — surfaced while formalizing (benefit 2)

Full detail in [`FINDINGS.md`](FINDINGS.md). Highlights:

- **`n >= 0` is *enforced*, not silently assumed (a positive finding).**
  `factorial(-3)` and `factorial(-1)` **raise `ValueError`** — the precondition
  `requires N >=Int 0` is a guard the code already implements, not a latent bug.
- **No `bool` guard (the one real smell).** `factorial.py` has *no* `isinstance`
  check, so `factorial(True) == 1` and `factorial(False) == 1` slip through silently
  (in Python `bool` is a subclass of `int`). Optional hardening; keep a regression
  test pinning the intended behavior.
- **Recursion-depth limit (the one action item):** measured, the smallest failing
  input is **`n = 999`** — `factorial(999)` raises `RecursionError` at CPython's
  default limit. So it returns correctly only for `0 ≤ n ≤ 998`. The recursion *is*
  mathematically well-founded; the limit is a stack-depth artifact. Prefer an
  iterative loop or `math.factorial` for unbounded `n`.
- **No overflow** — Python big integers; `factorial(100)` is exact (158 digits).

---

## 7. TEST REDUNDANCY — fewer tests, faster CI (benefit 1)

> A verified function is proven correct for all inputs in its domain, so unit tests
> that only re-check in-domain points become redundant.

Once `(FACT)` is machine-checked it proves `factorial(n) = n!` for **every** `n` in
`0 ≤ n ≤ 998` (the depth-limited domain). The current suite is
[`test_factorial.py`](test_factorial.py); classify each test:

| test | assertion | verdict |
|---|---|---|
| `test_zero` | `factorial(0) == 1` | **redundant** — subsumed (`fact(0) = 1`, `0 ≥ 0`) |
| `test_one` | `factorial(1) == 1` | **redundant** — subsumed (`fact(1) = 1`) |
| `test_small_values` | `factorial(2..5) == 2,6,24,120` | **redundant** — all in-domain points subsumed |
| `test_larger_value` | `factorial(10) == 3628800` | **redundant** — subsumed (`fact(10) = 3628800`) |
| `test_negative_raises` | `factorial(-1)` raises `ValueError` | **KEEP** — out-of-domain; pins Finding 1 (the enforced negative boundary), which the `N >= 0` contract does *not* cover |

**Also recommended to ADD/KEEP** (the proof covers none of these):
- a **`bool` test** pinning Finding 2 (`factorial(True)` — assert whatever behavior you
  decide is intended);
- a **recursion-depth test** pinning Finding 3 (`factorial(999)` expects
  `RecursionError`) — this pins the real robustness boundary partial correctness says
  nothing about.

**Estimated CI saving:** four in-domain assertions across three test functions become
redundant (the in-domain `==` checks); the structural cost is small here but the
*principle* is the payoff — the verified contract subsumes every in-domain point test.

**Conditioned on machine-checking.** The kit does **not** run `kprove`; this is
constructed, not machine-checked — do **not** delete any test until `kprove` returns
`#Top` (see "Reproduce"), and note the `fact`-well-definedness `[ESCALATION BOUNDARY]`
in §5 must also be settled before the redundancy is fully sound.

---

## Reproduce the machine check

```sh
kompile mini-python.k --backend haskell      # compile the fragment semantics
kast    --backend haskell factorial-spec.k # (optional) confirm claims parse
kprove  factorial-spec.k                    # expected: #Top  (all claims proved)
```

A `#Top` result upgrades everything above from **constructed** to **machine-verified**
*relative to* the `fact` spec symbol — and the §5 `[ESCALATION BOUNDARY]`
(well-definedness of `fact`) must additionally be discharged via the μ-logic sources
before the §7 test deletions are fully safe.

*References: kframework.org; runtimeverification/k; K Tutorial Lesson 1.22. Roșu,
"Matching Logic", LMCS 2017. Chen & Roșu, "Matching μ-Logic", LICS 2019. Roșu &
Ștefănescu, FM 2012 / LICS 2013 (reachability logic & the Circularity rule, including
the recursive-call form). Sibling: [`examples/06-sum-recursive/`](../../../formal-verification-kit/examples/06-sum-recursive/).*
