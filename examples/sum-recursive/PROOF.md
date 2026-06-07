# PROOF — `sum_recursive(n)` reachability proof

This is the **recursion** member of the `sum-*` cluster: same contract as the loops
(`sum(n) = n*(n+1)/2`), but there is **no loop**, so there is **no loop-invariant**.
The circularity is on the **recursive call's contract** `(REC)` — the proof's new
shape. (The companions reach the same result with a count-up / count-down loop
invariant — see the [examples catalog](../README.md).)

**Status: constructed, not machine-checked.** The artifacts are built to be
`kompile`/`kprove`-checkable but the toolchain was **not run** here (MVP stopgap).
Treat the result as "constructed" until §"Reproduce" turns it into "machine-verified."

> **Provenance.** The `/formalize` artifacts — [`mini-python.k`](mini-python.k),
> [`mini-python-spec.k`](mini-python-spec.k), [`SPEC.md`](SPEC.md),
> [`FINDINGS.md`](FINDINGS.md) — were produced by an **isolated newcomer** agent that
> learned the kit and ran `/formalize` on independently-written code. This `PROOF.md`
> (the `/verify` stage) was constructed when the example was brought into the kit;
> the spec it proves is the newcomer's, unchanged.

The program ([`sum_recursive.py`](sum_recursive.py), reduced to its in-domain core —
the `isinstance`/`raise` guards are no-ops on `n >= 0` and become Findings, not
modeled):

```python
def sum_recursive(n):
    if n == 0:
        return 0
    return n + sum_recursive(n - 1)
```

---

## 1. The reachability spec — the (SUM) function claim

The whole-function contract is one reachability rule `φ_pre ⇒ φ_post`: from a
configuration that *defines* `sum_recursive` and *calls* it on a non-negative `N`,
execution reaches a terminated configuration whose `result` holds `N*(N+1)/2`.

As the **(SUM)** `claim` in [`mini-python-spec.k`](mini-python-spec.k):

```k
claim
  <k>
    def sum_recursive ( n ) : INDENT
      if n == 0 : INDENT return 0 DEDENT
      return n + sum_recursive ( n - 1 )
    DEDENT
    result = sum_recursive ( N:Int )
  => .K ... </k>
  <funcs> .Map => ?_:Map </funcs>
  <store> result |-> (_:Int => N *Int (N +Int 1) /Int 2) </store>
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
evaluating a call `sum_recursive(N)` at the head of `<k>` reduces to the value
`N*(N+1)/2`, threading the continuation `CONT` unchanged, with `<store>`/`<stack>`
net unchanged (the call pushes a frame and returns pop it).

```k
claim
  <k> sum_recursive ( N:Int ) ~> CONT:K
   => N *Int (N +Int 1) /Int 2 ~> CONT </k>
  <funcs> ... sum_recursive |-> def sum_recursive ( n ) : INDENT
        if n == 0 : INDENT return 0 DEDENT
        return n + sum_recursive ( n - 1 )
      DEDENT ... </funcs>
  <store> STORE </store>
  <stack> STK:List </stack>
  requires N >=Int 0
  [all-path]
```

This is the exact analog of the loops' `(LOOP)` claim — **K uses every claim as its
own coinduction hypothesis**, so `(REC)` discharges its own inner call
`sum_recursive(N−1)`. The **back-edge is the recursive call**, not a loop guard, and
**guardedness** is supplied by the `call` step taken before the hypothesis is reused.

---

## 3. Informal proof (English)

**Prove (REC)** by guarded coinduction (assume `(REC)`, reuse only after a real step):

1. **Call step (progress).** `sum_recursive(N)` fires the `(call)` rule: it pushes the
   caller's frame `state(CONT, STORE)` onto `<stack>`, gives the callee a fresh scope
   binding `n = N`, and runs the body. *This `=>⁺` step discharges guardedness.*
2. **Case-split on the base/recursive branch** (the `if n == 0`):
   - **Base case (`N == 0`).** `if true` runs `return 0`; the `(return)` rule pops the
     frame, restores `STORE`, and delivers `0` to `CONT`. The call reduced to
     `0 ~> CONT`. **VC-base:** `N == 0 ⇒ N*(N+1)/2 = 0`. ✓
   - **Recursive case (`N ≠ 0`, i.e. `N ≥ 1`).** `if false` is skipped; control reaches
     `return n + sum_recursive(n − 1)`. Evaluating the argument gives the inner call
     `sum_recursive(N − 1)` — **invoke `(REC)` on it** (its precondition `N − 1 ≥ 0`
     follows from `N ≥ 1`), reducing it to `(N−1)*N/2`. So the returned value is
     `N + (N−1)*N/2`; `(return)` pops the frame and delivers it to `CONT`. **VC-step:**
     `N + (N−1)*N/2 = N*(N+1)/2`. ✓

Both branches land on `(REC)`'s post-state, and the hypothesis was used only after the
`call` step (and the recursive call's own `call` step), so the circularity discharges:
`A ⊢ (REC)`.

**Prove (SUM)** using `(REC)` as a lemma: `def` files the body into `<funcs>`
(witnessing `?_:Map`); `result = sum_recursive(N)` evaluates its RHS by **`(REC)` at
`N`** (precondition `N ≥ 0`), giving `N*(N+1)/2`; the assignment lands
`result |-> N*(N+1)/2` and the stack is `.List`. ∎

---

## 4. Machine-detailed proof sketch (for `kprove`)

Abbreviation `cf(N) := N *Int (N +Int 1) /Int 2`.

**PART A — (REC) by circularity.** Reuse `(REC)` only after ≥ 1 genuine rewrite.
- **A1 progress:** `(call)` → pushes `state(CONT, STORE)`, resets `<store>` to a fresh
  scope, `#makeBindings((n),(N))` binds `n ↦ N`, queues `BODY`. This `=>⁺` discharges
  guardedness.
- **A2 guard:** `if n == 0` — `(lookup)` `n ⇒ N`, `(==)` ⇒ `N ==Int 0`.
- **A3 split** (`#Or` on `N ==Int 0`, both under `N >=Int 0`):
  - **base `N == 0` / `if true`:** `return 0` ⇒ `(return)` pops the frame, `0 ~> CONT`.
    Closes via **VC-base** (`cf(0) = 0`).
  - **recursive `N =/=Int 0` / `if false`:** reach `return n + sum_recursive(n−1)`;
    `+`/call are `seqstrict` ⇒ `(lookup)` `n ⇒ N`, `(−)` `n−1 ⇒ N−Int 1`; the inner call
    `sum_recursive(N−Int 1) ~> CONT'` — **reuse (REC)** at `N−Int 1` (precondition
    `N−1 >=Int 0` from `N >=Int 1`) ⇒ `cf(N−1)`; `(+)` ⇒ `N +Int cf(N−1)`; `(return)`
    pops the frame ⇒ `(N +Int cf(N−1)) ~> CONT`. Closes via **VC-step**.

**PART B — (SUM).** `(def)` files the body (witnesses `?_:Map`) → `result =
sum_recursive(N)`: arg already `Int`, **apply (REC) at `N`** ⇒ `cf(N) ~> (result = ☐)`
→ `(asgn)` `result |-> cf(N)`. Map-extensionality `[simplification]` reduces the
post-store `#Equals` to the scalar `cf(N)`.

**Verification conditions** (`/Int` truncates; numerators are products of consecutive
integers, hence even ⇒ each `/Int 2` is **exact**):

| VC | Statement | Discharged by |
|----|-----------|---------------|
| **VC-base** | `N = 0 ⇒ cf(N) = 0` | Z3 (zero factor) |
| **VC-step** | `N + (N−1)*N/2 = cf(N)`  ⇔ (×2) `2N + (N−1)N = N(N+1)`, both sides `= N² + N` | exact-halving `[simplification]` (`(N−1)*N` even, `= X*(X+1)` at `X = N−1`) + Z3 |
| map ext. | `M[K<-V] #Equals M[K<-V'] ⇒ V #Equals V'` | `[simplification]`, then Z3 |

---

## 5. FINDINGS — a hidden subtle bug (benefit 2)

Full detail in [`FINDINGS.md`](FINDINGS.md). Highlights, surfaced while formalizing:

- **`n >= 0` is *enforced*, not silently assumed (a positive finding).** Unlike the
  loop examples — where `sum(-3)` *silently* returns `0` — `sum_recursive(-3)` **raises
  `ValueError`**. The precondition `requires N >=Int 0` is a guard the code already
  implements, not a latent bug.
- **`isinstance(n, bool)` exclusion** correctly rejects `True`/`False` (in Python
  `bool` is a subclass of `int`) — keep a regression test.
- **Recursion-depth limit (the one action item):** measured, the smallest failing input
  is **`n = 998`** — `sum_recursive(998)` raises `RecursionError` at CPython's default
  limit. So it returns correctly only for `0 ≤ n ≤ 997`. The recursion *is*
  mathematically well-founded (`n` decreases by 1, bounded below by `0`); the limit is a
  stack-depth artifact. Prefer an iterative loop or the closed form for unbounded `n`.

---

## 6. TEST REDUNDANCY — fewer tests, faster CI (benefit 1)

> A verified function is proven correct for all inputs in its domain, so unit tests
> that only re-check in-domain points become redundant.

Once `(SUM)` is machine-checked it proves `sum_recursive(n) = n*(n+1)/2` for **every**
`n` in `0 ≤ n ≤ 997` (the depth-limited domain). In-domain point tests are subsumed:

- `sum_recursive(5) == 15` → subsumed (`5*6/2 = 15`). **Redundant.**
- `sum_recursive(0) == 0`  → subsumed (`0*1/2 = 0`).  **Redundant.**

**Keep** the out-of-domain tests the proof does *not* cover (Findings 1–3): a `n < 0`
test (expects `ValueError`), a `bool` test (expects `TypeError`), and a
**recursion-depth** test (`n = 998` expects `RecursionError`) — that last one pins the
real robustness boundary partial correctness says nothing about.

**Conditioned on machine-checking.** The MVP does **not** run `kprove`; this is
constructed, not machine-checked — do **not** delete any test until `kprove` returns
`#Top` (see "Reproduce").

---

## Reproduce the machine check

```sh
kompile mini-python.k --backend haskell      # compile the fragment semantics
kast    --backend haskell mini-python-spec.k # (optional) confirm claims parse
kprove  mini-python-spec.k                    # expected: #Top  (all claims proved)
```

A `#Top` result upgrades everything above from **constructed** to **machine-verified**,
and only then are the §6 test deletions safe.

*References: kframework.org; runtimeverification/k; K Tutorial Lesson 1.22. Roșu,
"Matching Logic", LMCS 2017. Chen & Roșu, "Matching μ-Logic", LICS 2019. Roșu &
Ștefănescu, FM 2012 / LICS 2013 (reachability logic & the Circularity rule, including
the recursive-call form).*
