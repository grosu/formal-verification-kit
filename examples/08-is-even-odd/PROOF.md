# PROOF — `is_even(n)` / `is_odd(n)` mutual-recursion reachability proof

This is the **mutual-recursion** member of the `sum-*`/recursion cluster: like
`sum-recursive` there is **no loop**, so there is **no loop-invariant** — the
circularity is on the **recursive call's contract**. The new shape over
`sum-recursive` is that the recursion is **mutual**, so the circularity **spans two
claims**, `(EVEN)` and `(ODD)`, that **discharge each other's** recursive call.

**Status: constructed, not machine-checked.** The artifacts are built to be
`kompile`/`kprove`-checkable but the toolchain was **not run** here (MVP stopgap).
Treat the result as "constructed" until §"Reproduce" turns it into "machine-verified."

The program ([`even_odd.py`](even_odd.py), in-domain core — there are no guards to
reduce; the `__main__` test block is I/O outside the verified core and not modeled):

```python
def is_even(n):
    if n == 0:
        return True
    return is_odd(n - 1)

def is_odd(n):
    if n == 0:
        return False
    return is_even(n - 1)
```

---

## 1. The reachability specs — the (EVENFN) / (ODDFN) function claims

Each whole-function contract is one reachability rule `φ_pre ⇒ φ_post`: from a
configuration that *defines both* functions and *calls* one on a non-negative `N`,
execution reaches a terminated configuration whose `r` holds the parity boolean.

As the **(EVENFN)** `claim` in [`is-even-odd-spec.k`](is-even-odd-spec.k) (the
`(ODDFN)` claim is symmetric, with `N modInt 2 ==Int 1`):

```k
claim
  <k>
    def is_even ( n ) : INDENT  if n == 0 : INDENT return true  DEDENT
      return is_odd ( n - 1 )  DEDENT
    def is_odd ( n ) : INDENT  if n == 0 : INDENT return false DEDENT
      return is_even ( n - 1 ) DEDENT
    r = is_even ( N:Int )
  => .K ... </k>
  <funcs> .Map => ?_:Map </funcs>
  <store> r |-> (_:Bool => N modInt 2 ==Int 0) </store>
  <stack> .List </stack>
  requires N >=Int 0
  [all-path]
```

`requires N >=Int 0` is the precondition; `<funcs> .Map => ?_:Map` says the function
table (both functions) now exists; `<stack> .List` says the call stack is balanced
again after the (possibly deep) mutual recursion returns. Partial correctness,
`[all-path]` (the fragment is deterministic, so all-path coincides with one-path).
**Both** `def`s appear because the functions are mutually dependent — `is_even`'s
body cannot run without `is_odd` filed, and vice versa.

---

## 2. The mutual-recursion circularities — the (EVEN) / (ODD) claims

With no loop, the coinductive hypotheses are the **functions' own contracts** — and
because the recursion is mutual, there are **two**, each the hypothesis the *other*
needs:

```k
claim  // (EVEN)
  <k> is_even ( N:Int ) ~> CONT:K  =>  ( N modInt 2 ==Int 0 ) ~> CONT </k>
  <funcs> ... is_even |-> def ...  is_odd |-> def ... </funcs>
  <store> STORE </store>  <stack> STK:List </stack>
  requires N >=Int 0
  [all-path]

claim  // (ODD)
  <k> is_odd ( N:Int ) ~> CONT:K   =>  ( N modInt 2 ==Int 1 ) ~> CONT </k>
  <funcs> ... is_even |-> def ...  is_odd |-> def ... </funcs>
  <store> STORE </store>  <stack> STK:List </stack>
  requires N >=Int 0
  [all-path]
```

**K uses every claim in the module as a coinduction hypothesis**, so while proving
`(EVEN)` the hypothesis `(ODD)` is available, and vice versa. `(EVEN)`'s recursive
branch calls `is_odd(N-1)` → **closed by `(ODD)`**; `(ODD)`'s recursive branch calls
`is_even(N-1)` → **closed by `(EVEN)`**. Neither claim discharges its own call —
**each is the other's coinduction hypothesis.** This is the generalization of
`sum-recursive`'s single self-discharging `(REC)` to **mutual** recursion. The
**back-edge is a cross-call**, not a self-call, and **guardedness** is supplied, in
each, by the `(call)` step taken before the *other* hypothesis is reused.

---

## 3. Informal proof (English)

**Prove (EVEN) and (ODD) together** by *mutual* guarded coinduction (each may assume
the *other*, reused only after a real `=>⁺` step):

**(EVEN), `is_even(N)`, `N >= 0`:**
1. **Call step (progress).** `is_even(N)` fires the `(call)` rule: pushes the
   caller's frame `state(CONT, STORE)`, gives a fresh scope binding `n = N`, runs the
   body. *This `=>⁺` step earns the hypothesis.*
2. **Case-split on `if n == 0`:**
   - **Base (`N == 0`).** `if true` runs `return True`; `(return)` pops the frame and
     delivers `true` to `CONT`. **VC-EVEN-BASE:** `N == 0 ⇒ (N modInt 2 ==Int 0) = true`.
     ✓ (`0 mod 2 = 0`).
   - **Recursive (`N >= 1`).** `if false` is skipped; control reaches
     `return is_odd(n - 1)`. Evaluating the argument gives the inner call
     `is_odd(N - 1)` — **invoke `(ODD)` on it** (its precondition `N - 1 >= 0` follows
     from `N >= 1`), reducing it to `(N-1) modInt 2 ==Int 1`; `(return)` delivers that
     to `CONT`. **VC-EVEN-STEP:** `((N-1) modInt 2 ==Int 1) = (N modInt 2 ==Int 0)`
     for `N >= 1`. ✓

**(ODD), `is_odd(N)`, `N >= 0`:** symmetric.
   - **Base (`N == 0`).** `return False`; **VC-ODD-BASE:** `(0 modInt 2 ==Int 1) = false`. ✓
   - **Recursive (`N >= 1`).** `return is_even(n - 1)`; the inner call
     `is_even(N - 1)` is **closed by `(EVEN)` on `N - 1`** giving
     `(N-1) modInt 2 ==Int 0`. **VC-ODD-STEP:**
     `((N-1) modInt 2 ==Int 0) = (N modInt 2 ==Int 1)` for `N >= 1`. ✓

Each branch lands on its claim's post-state, and the *other* hypothesis was used only
after the `call` step (and the recursive call's own `call` step), so the **mutual**
circularity discharges: `A ⊢ (EVEN)` and `A ⊢ (ODD)`.

**Prove (EVENFN)/(ODDFN)** using `(EVEN)`/`(ODD)` as lemmas: the two `def`s file both
bodies into `<funcs>` (witnessing `?_:Map`); `r = is_even(N)` evaluates its RHS by
**`(EVEN)` at `N`** (precondition `N >= 0`), giving `N modInt 2 ==Int 0`; the
assignment lands `r |-> (N modInt 2 ==Int 0)` and the stack is `.List`. `(ODDFN)`
symmetric via `(ODD)`. ∎

---

## 4. Machine-detailed proof sketch (for `kprove`)

Abbreviation `ev(N) := N modInt 2 ==Int 0`, `od(N) := N modInt 2 ==Int 1`.

**PART A — (EVEN)/(ODD) by mutual circularity.** Reuse the *other* claim only after
≥ 1 genuine rewrite.
- **A1 progress:** `(call)` → pushes `state(CONT, STORE)`, resets `<store>` to a fresh
  scope, `#makeBindings((n),(N))` binds `n ↦ N`, queues `BODY`. This `=>⁺` discharges
  guardedness.
- **A2 guard:** `if n == 0` — `(lookup)` `n ⇒ N`, `(==)` ⇒ `N ==Int 0`.
- **A3 split** (`#Or` on `N ==Int 0`, both under `N >=Int 0`):
  - **(EVEN) base `N == 0` / `if true`:** `return true` ⇒ `(return)` pops the frame,
    `true ~> CONT`. Closes via **VC-EVEN-BASE** (`ev(0) = true`).
  - **(EVEN) recursive `N =/=Int 0` / `if false`:** reach `return is_odd(n−1)`;
    `(lookup)` `n ⇒ N`, `(−)` `n−1 ⇒ N −Int 1`; inner call `is_odd(N −Int 1) ~> CONT'`
    — **reuse (ODD)** at `N −Int 1` (precondition `N−1 >=Int 0` from `N >=Int 1`) ⇒
    `od(N−1)`; `(return)` pops the frame ⇒ `od(N−1) ~> CONT`. Closes via **VC-EVEN-STEP**.
  - **(ODD)** branches mirror this with `return false` (base) and **reuse (EVEN)** on
    `is_even(N−1)` (recursive).

**PART B — (EVENFN)/(ODDFN).** `(def)`×2 file both bodies (witness `?_:Map`) → `r =
is_even(N)`: arg already `Int`, **apply (EVEN) at `N`** ⇒ `ev(N) ~> (r = ☐)` →
`(asgn)` `r |-> ev(N)`. Map-extensionality `[simplification]` reduces the post-store
`#Equals` to the scalar `ev(N)`. (ODDFN) symmetric.

**Verification conditions** (all single-step; the induction is in the circularity,
*not* in any VC — so none is an inductive obligation):

| VC | Statement | Discharged by |
|----|-----------|---------------|
| **VC-EVEN-BASE** | `N = 0 ⇒ ev(N) = true`  | Z3 (concrete `0 mod 2 = 0`) |
| **VC-ODD-BASE**  | `N = 0 ⇒ od(N) = false` | Z3 (concrete `0 mod 2 = 0 ≠ 1`) |
| **VC-EVEN-STEP** | `N ≥ 1 ⇒ ((N−1) mod 2 == 1) = (N mod 2 == 0)` | parity mod-shift `[simplification]` + Z3 |
| **VC-ODD-STEP**  | `N ≥ 1 ⇒ ((N−1) mod 2 == 0) = (N mod 2 == 1)` | parity mod-shift `[simplification]` + Z3 |
| map ext. | `M[K<-V] #Equals M[K<-V'] ⇒ V #Equals V'` | `[simplification]`, then Z3 |

The two parity mod-shift lemmas ("subtracting 1 flips the parity bit", guarded by
`N >= 1`) are **non-inductive single-decrement facts**; the kit's bundled VC tier
discharges them. **No `[ESCALATION BOUNDARY]` obligation arises** — contrast the
insertion-sort example, whose inductive `isSorted`/`bag` VCs do. Nothing is faked as
`[trusted]`.

---

## 5. FINDINGS — a hidden subtle bug (benefit 2)

Full detail in [`FINDINGS.md`](FINDINGS.md). Highlights, surfaced while formalizing:

- **`n < 0` does NOT terminate — `n >= 0` is load-bearing for *termination* (the
  headline).** The only base case is `n == 0`; for negative `n` the descending chain
  never reaches it, so the mutual recursion runs forever. Measured:
  `is_even(-1)` and `is_odd(-2)` both **raise `RecursionError`** (infinite mutual
  recursion). Unlike the loop examples (silent wrong `0`) and unlike `sum-recursive`
  (an enforcing `raise`), this code has **no guard** — bad input neither returns nor
  meaningfully errors; it spins. The precondition `requires N >= 0` is what makes the
  recursion well-founded (measure `n` ↓ to `0`). **Recommendation:** add an explicit
  `if n < 0: raise ValueError(...)` guard.
- **Recursion-depth limit (an action item):** measured, the smallest failing input is
  **`n = 998`** — `is_even(998)` raises `RecursionError` at CPython's default limit
  (1000). So the functions return correctly only for `0 ≤ n ≤ 997`. Distinct from the
  non-termination above: here the recursion *is* well-founded; the limit is a
  stack-depth artifact. Prefer the O(1) closed form `n % 2 == 0` for unbounded `n`.

---

## 6. TEST REDUNDANCY — fewer tests, faster CI (benefit 1)

> A verified function is proven correct for all inputs in its domain, so unit tests
> that only re-check in-domain points become redundant.

The program's inline tests (`even_odd.py`, the `__main__` block) are all **in-domain**
point checks over `n >= 0`. Once `(EVENFN)`/`(ODDFN)` are machine-checked they prove
`is_even(n) = (n mod 2 == 0)` and `is_odd(n) = (n mod 2 == 1)` for **every** `n` in
`0 ≤ n ≤ 997` (the depth-limited domain — Finding 3), so each is subsumed:

- `assert is_even(0) is True`  → subsumed (`0 mod 2 = 0`). **Redundant.**
- `assert is_odd(0) is False`  → subsumed (`0 mod 2 = 0 ≠ 1`). **Redundant.**
- `assert is_even(1) is False`, `assert is_odd(1) is True` → subsumed. **Redundant.**
- `assert is_even(2) is True`, `assert is_odd(3) is True`   → subsumed. **Redundant.**
- `assert is_even(10) is True`, `assert is_odd(7) is True`  → subsumed. **Redundant.**
- The `for n in range(50)` loop — `is_even(n) == (n%2==0)`, `is_odd(n) == (n%2==1)`,
  and `is_even(n) != is_odd(n)` — is **exactly the proved contract** (and its mutual
  exclusivity is a corollary: `ev(n)` and `od(n)` are negations on `n >= 0`).
  **Redundant** for every `n` in `[0, 49] ⊂ [0, 997]`.

Estimated CI saving: the whole `__main__` block (8 asserts + a 50-iteration loop of 3
asserts = 158 in-domain assertions) collapses to the two machine-checked contracts.

**Keep** the tests the proof does *not* cover (Findings 1, 3) — currently the program
has **none** of these, so they are tests to **ADD**, not drop:

- an `n < 0` test asserting **`RecursionError`** (or, after the recommended fix, a
  `ValueError`) — pins the non-termination of Finding 1, the real bug boundary;
- a **recursion-depth** test (`n = 998` expects `RecursionError`) — pins the
  robustness boundary partial correctness says nothing about.

**Conditioned on machine-checking.** The MVP does **not** run `kprove`; this is
constructed, not machine-checked — do **not** delete any test until `kprove` returns
`#Top` (see "Reproduce").

---

## Reproduce the machine check

```sh
kompile mini-python.k --backend haskell      # compile the fragment semantics
kast    --backend haskell is-even-odd-spec.k # (optional) confirm claims parse
kprove  is-even-odd-spec.k                    # expected: #Top  (all 4 claims proved)
```

A `#Top` result upgrades everything above from **constructed** to **machine-verified**,
and only then are the §6 test deletions safe.

*References: kframework.org; runtimeverification/k; K Tutorial Lesson 1.22. Roșu,
"Matching Logic", LMCS 2017. Chen & Roșu, "Matching μ-Logic", LICS 2019. Roșu &
Ștefănescu, FM 2012 / LICS 2013 (reachability logic & the Circularity rule, including
the recursive-call form generalized here to MUTUAL recursion across two claims).*
