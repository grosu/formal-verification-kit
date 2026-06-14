# PROOF — `tree_height(t)` reachability proof

This is the **recursion-over-a-recursive-datatype** member of the kit's example set.
The **control flow** is the [`sum-recursive`](../../../formal-verification-kit/examples/06-sum-recursive/)
`(REC)` shape (the circularity is on the recursive calls; no loop, no loop-invariant),
but two things are new: the recursion is **branching** (two child calls), and the data
is a **binary tree modeled as a K value sort** — so the proof reaches the kit's
recursive-data-structure boundary. The program is now **self-contained** (it defines
its own `max2`), so there are **TWO function contracts** to prove, plus the circularity.

**Status: constructed, not machine-checked.** The artifacts are built to be
`kompile`/`kprove`-checkable but the toolchain was **not run** here (MVP stopgap). Two
qualifications: (1) constructed, not machine-checked (run §"Reproduce" to upgrade), and
(2) the construction has an open **`[ESCALATION BOUNDARY]`** obligation `(T-IND)` —
structural induction over `Tree` — that the bundled tier cannot close. Everything else
is bundled-tier clean.

The program ([`tree_height.py`](tree_height.py), reduced to its in-domain core — the
exact tuple shape is assumed and becomes Finding 4, not modeled):

```python
def max2(x, y):
    if x > y:
        return x
    else:
        return y

def tree_height(t):
    if t is None:
        return 0
    return 1 + max2(tree_height(t.left), tree_height(t.right))
```

References only its sibling files: [`mini-python.k`](mini-python.k),
[`tree-height-spec.k`](tree-height-spec.k), [`SPEC.md`](SPEC.md),
[`FINDINGS.md`](FINDINGS.md).

---

## 0. The binary tree as a K value sort (the modeling decision)

The Python tree (`None` or `(value, left, right)`) is modeled as a first-class **value
sort**:

```k
syntax Tree ::= "none" | "node" "(" Int "," Tree "," Tree ")"
```

This is the tree-shaped analog of insertion-sort modeling a Python list as K's builtin
`List` value sort. Because `Tree` is a **value** (not a heap reference), Python's
by-value tuple structure and non-aliasing fall out for free. Spec-only abstraction
functions in the `VERIFICATION` module give the proof its vocabulary:

```k
syntax Bool ::= isNone(Tree) [function, total]       // t is None
syntax Tree ::= left(Tree) | right(Tree) [function]  // t[1], t[2]
syntax Int  ::= h(Tree) [function]                   // the height MEASURE:
//   h(none) = 0 ;  h(node(_,L,R)) = 1 + max2Int(h(L), h(R))
syntax Int  ::= max2Int(Int, Int) [function, total]  // the math max used in h
```

`h(T)` is the inductive measure the function computes; `max2Int` is the math max that
`(MAX2)` proves the *program's* `max2` equals.

---

## 1. The reachability specs — THREE claims (two contracts + the circularity)

### (MAX2) — the helper contract (bundled-tier clean)

```k
claim
  <k> max2 ( X:Int , Y:Int ) ~> CONT:K  =>  max2Int(X, Y) ~> CONT </k>
  <funcs> ... max2 |-> def max2 ( x , y ) : INDENT
        if x > y : INDENT return x DEDENT else : INDENT return y DEDENT
      DEDENT ... </funcs>
  <store> STORE </store>  <stack> STK:List </stack>
  [all-path]
```

Non-recursive, no circularity, no induction: a single `if x > y` case-split, each arm
returns a parameter. Closed by Z3 (`X > Y ⇒ max2Int(X,Y) = X`; else `= Y`). This is the
demonstration that a self-contained helper earns its **own** verified contract.

### (HEIGHT) — the user-facing function contract

```k
claim
  <k>
    def max2 ( x , y ) : INDENT
      if x > y : INDENT return x DEDENT else : INDENT return y DEDENT
    DEDENT
    def tree_height ( t ) : INDENT
      if t is None : INDENT return 0 DEDENT
      return 1 + max2 ( tree_height ( t . left ) , tree_height ( t . right ) )
    DEDENT
    result = tree_height ( T:Tree )
  => .K ... </k>
  <funcs> .Map => ?_:Map </funcs>
  <store> result |-> (_:KResult => h(T)) </store>
  <stack> .List </stack>
  [all-path]
```

From a configuration that *defines* both functions and *calls* `tree_height` on a
well-formed tree `T`, execution reaches a terminated configuration whose `result` holds
the measure `h(T)`. `<funcs> .Map => ?_:Map` says the table now exists; `<stack> .List`
says the (possibly deep, branching) recursion returns balanced. Partial correctness,
`[all-path]` (the fragment is deterministic, so all-path coincides with one-path).

### (REC) — the recursion circularity (the distinctive claim)

```k
claim
  <k> tree_height ( T:Tree ) ~> CONT:K  =>  h(T) ~> CONT </k>
  <funcs> ... max2 |-> def max2 (...) ...
          tree_height |-> def tree_height ( t ) : INDENT
            if t is None : INDENT return 0 DEDENT
            return 1 + max2 ( tree_height ( t . left ) , tree_height ( t . right ) )
          DEDENT ... </funcs>
  <store> STORE </store>  <stack> STK:List </stack>
  [all-path]
```

With no loop, the coinductive hypothesis is the **function's own contract**. K uses
every claim as its own hypothesis, so `(REC)` discharges **BOTH** recursive child calls
`tree_height(left(T))` and `tree_height(right(T))` — **branching recursion**, two
back-edges, each earned by its own `call` step (guardedness). The measure `h(T)` plays
the role the classical loop invariant used to.

---

## 2. Informal proof (English)

**Prove (MAX2)** directly (no circularity): the `call` rule binds `x = X, y = Y`;
`if x > y` evaluates the guard `X > Y` and case-splits — `true` arm returns `X`, `false`
arm returns `Y`; `return` pops the frame. Both arms land on `max2Int(X, Y)` by the math
`max2Int` definition. ∎ (discharged by Z3)

**Prove (REC)** by guarded coinduction (assume `(REC)`, reuse only after a real step)
— this is the **per-node** argument; lifting it to *all* trees is `(T-IND)`, §5:

1. **Call step (progress).** `tree_height(T)` fires the `call` rule: pushes the caller's
   frame `state(CONT, STORE)` onto `<stack>`, gives the callee a fresh scope binding
   `t = T`, runs the body. *This `=>⁺` step discharges guardedness.*
2. **Case-split on `t is None`** (the structural match on `T`):
   - **Base case (`T = none`).** `if true` runs `return 0`; the `return` rule pops the
     frame and delivers `0`. **VC-BASE:** `h(none) = 0`. ✓
   - **Node case (`T = node(V, L, R)`).** `t is None` is `false`; control reaches
     `return 1 + max2(tree_height(t.left), tree_height(t.right))`. The field reads
     `t.left → L`, `t.right → R`. The two inner calls `tree_height(L)`,
     `tree_height(R)` — **invoke `(REC)` on each** (the two back-edges), reducing them
     to `h(L)` and `h(R)`. Then `max2(h(L), h(R))` — **invoke `(MAX2)`** — gives
     `max2Int(h(L), h(R))`; `1 + …` makes `1 + max2Int(h(L), h(R))`; `return` pops the
     frame and delivers it. **VC-STEP:** `1 + max2Int(h(L), h(R)) = h(node(V,L,R))`,
     which is the measure equation itself. ✓
3. Both branches land on `(REC)`'s post-state, and the hypothesis was used only after
   the `call` step (and each child call's own `call` step). **Per node, the circularity
   discharges.** The lift to every finite `T` is `(T-IND)` — §5. 

**Prove (HEIGHT)** using `(REC)` as a lemma: the two `def`s file both bodies into
`<funcs>` (witnessing `?_:Map`); `result = tree_height(T)` evaluates its RHS by **`(REC)`
at `T`**, giving `h(T)`; the assignment lands `result |-> h(T)` and the stack is `.List`.
∎ (modulo `(T-IND)`)

---

## 3. Machine-detailed proof sketch (for `kprove`)

Abbreviation `cf(T) := h(T)` (the measure).

**PART A — (MAX2)** (finite, no hypothesis).
- `(call)` binds `x ↦ X, y ↦ Y`; `(lookup)`×2 + `(>)` ⇒ guard `X >Int Y`.
- `#Or` split: `true` ⇒ `return X` ⇒ `(return)` ⇒ `X`, closes via `X >Int Y ⇒
  max2Int(X,Y) = X`; `false` ⇒ `return Y` ⇒ `Y`, closes via the dual. **Z3 only.**

**PART B — (REC) by circularity** (reuse `(REC)` only after ≥ 1 genuine rewrite).
- **B1 progress:** `(call)` → pushes `state(CONT, STORE)`, resets `<store>`, binds
  `t ↦ T`, queues `BODY`. This `=>⁺` discharges guardedness.
- **B2 guard:** `if t is None` — `(lookup)` `t ⇒ T`, `(is None)` ⇒ `isNone(T)`.
- **B3 split** (`#Or` on `isNone(T)`):
  - **base `T = none` / `if true`:** `return 0` ⇒ `(return)` ⇒ `0 ~> CONT`. Closes via
    **VC-BASE** (`h(none) = 0`).
  - **node `T = node(V,L,R)` / `if false`:** reach
    `return 1 + max2(tree_height(t.left), tree_height(t.right))`. `+`/`max2`/calls are
    `seqstrict` ⇒ `(.left)` `t.left ⇒ L`, `(.right)` `t.right ⇒ R`; inner call
    `tree_height(L) ~> …` — **reuse (REC)** at `L` ⇒ `h(L)`; likewise `tree_height(R)`
    — **reuse (REC)** at `R` ⇒ `h(R)`; the call `max2(h(L), h(R))` — **apply (MAX2)**
    ⇒ `max2Int(h(L), h(R))`; `(+)` ⇒ `1 +Int max2Int(h(L), h(R))`; `(return)` pops the
    frame ⇒ `(1 +Int max2Int(h(L), h(R))) ~> CONT`. Closes via **VC-STEP**.

**PART C — (HEIGHT).** `(def)`×2 file the bodies (witness `?_:Map`) → `result =
tree_height(T)`: arg already a `Tree`, **apply (REC) at `T`** ⇒ `h(T) ~> (result = ☐)`
→ `(asgn)` `result |-> h(T)`. Map-extensionality `[simplification]` reduces the
post-store `#Equals` to the scalar `h(T)`.

**Verification conditions.**

| VC | Statement | Discharged by |
|----|-----------|---------------|
| **VC-MAX2** | `X > Y ⇒ max2Int(X,Y) = X`; `¬(X>Y) ⇒ = Y` | Z3 (linear case-split) |
| **VC-BASE** | `h(none) = 0` | Z3 + `h`-defn `[simplification]` |
| **VC-STEP** | `1 + max2Int(h(L), h(R)) = h(node(V,L,R))` | the `h`-defn `[simplification]` (the measure equation, *literally*) — linear, **no division-by-even needed** (unlike sum-*) |
| map ext. | `M[K<-V] #Equals M[K<-V'] ⇒ V #Equals V'` | `[simplification]`, then Z3 |
| **(T-IND)** | lift base + step ⇒ `(REC)` holds for **every finite tree** | **`[ESCALATION BOUNDARY]`** — Tree structural induction (LICS'19 / OOPSLA'20) ✗ |

Note the contrast with the `sum-*` cluster: there the step needed an **exact-halving**
`[simplification]` because `/Int` truncates a symbolic product. Here the combine is
`1 + max`, purely **linear**, so the per-node VC is trivial for Z3 — the *only* open
piece is the structural-induction lift, which is a **capability** boundary, not a code
defect.

---

## 4. FINDINGS — surfaced while verifying (benefit 2)

Full detail in [`FINDINGS.md`](FINDINGS.md). Highlights:

- **`max2` is correct, ties included** — `max2(4,4) = 4` via the `else` branch (returns
  the 2nd arg). `(MAX2)` proves `max2 = math-max` on all pairs (Finding 1).
- **`tree_height` correct on every well-formed tree** — `h(t) = 1 + max(h(L), h(R))`,
  base `h(None)=0` (Finding 2).
- **Recursion-depth limit (the one action item):** measured, the smallest failing
  **degenerate chain depth is 999** — a left chain of depth 999 raises `RecursionError`
  at CPython's default limit, so it returns correctly only for depth `0 ≤ d ≤ 998`. The
  recursion *is* well-founded (each child tree is structurally smaller); the limit is a
  stack-depth artifact. Prefer an explicit-stack iterative traversal for deep/unbalanced
  trees (Finding 3).
- **Exact tuple shape is assumed** — malformed tuples (`(1, None)`, `(1, 7, None)`,
  `()`) raise `IndexError`/`TypeError`, i.e. *defined* rejections, out of domain
  (Finding 4).

---

## 5. ESCALATION BOUNDARY — `(T-IND)`, structural induction over `Tree`

This is the **honest open obligation**, not a code bug. The per-node argument of §2/§3
proves:

- **base:** `(REC)` holds at `T = none`, and
- **step:** `(REC)` holds at `T = node(V,L,R)` *given* it already holds at `L` and `R`.

Concluding **`(REC)` holds for every finite tree** requires the **structural-induction
principle for the inductive sort `Tree`** — the least-fixpoint / initial-algebra
reasoning of **Matching μ-Logic**. The kit's bundled tier (Z3 linear arithmetic + the
`[simplification]` lemmas) discharges the base and the step but does **not** supply this
lift. Per kit policy it is **stated** (in [`tree-height-spec.k`](tree-height-spec.k) as
`(T-IND)`) and **routed to the papers** — **never** admitted as `[trusted]`, which would
manufacture confidence the kit does not have.

**Route (see [`sources.md`](../../../formal-verification-kit/knowledge/sources.md)):**
recursive / inductive data structures and least-fixpoint `μ` reasoning →
**Chen & Roșu, *Matching μ-Logic* (LICS 2019)** and **Chen, Peña, Rodrigues, Roșu,
Trinh, *Unified fixpoint reasoning* (OOPSLA 2020)**; inductive-sort semantics in
*Initial Algebra Semantics in Matching Logic* (TR). The reachability/circularity
machinery itself (used per-node here) is **Roșu & Ștefănescu, FM 2012 / LICS 2013**.

This is the same discipline as [`insertion-sort`](../../../formal-verification-kit/examples/12-insertion-sort/),
whose multiset/sortedness facts (L1/L2) are likewise stated, not faked.

---

## 6. TEST REDUNDANCY — fewer tests, faster CI (benefit 1)

> A verified function is proven correct for all inputs in its domain, so unit tests
> that only re-check in-domain points become redundant.

The program's `__main__` asserts map cleanly onto the two contracts. **Conditioned on
machine-checking** (and, for the tree contract, on closing `(T-IND)`):

**`max2` tests — subsumed by `(MAX2)` (fully bundled-tier clean, no escalation):**

- `max2(2, 5) == 5`  → subsumed (`5 > 2`). **Redundant.**
- `max2(7, 3) == 7`  → subsumed (`7 > 3`). **Redundant.**
- `max2(4, 4) == 4`  → subsumed (tie → `else` → `y`). **Redundant.**

**`tree_height` tests — subsumed by `(HEIGHT)`, *conditioned additionally on `(T-IND)`*:**

- `tree_height(None) == 0`                 → subsumed (`h(none)=0`).        **Redundant\***
- `tree_height((5, None, None)) == 1`      → subsumed (`h=1+max(0,0)=1`).   **Redundant\***
- left/right chains `== 3`, balanced `== 2`, unbalanced `== 3` → subsumed by `h`.
  **Redundant\***

\* The `tree_height` deletions are **double-conditioned**: on `kprove` returning `#Top`
*and* on the `(T-IND)` escalation obligation being discharged via the papers. The
`max2` deletions need only `#Top`.

**Keep** the tests the proof does *not* cover (Findings 3–4), and add them if absent:
- a **deep/degenerate tree** test (e.g. a chain of depth ≥ 999 expects `RecursionError`)
  — pins the real robustness boundary partial correctness says nothing about;
- a **malformed-tuple** test (e.g. `(1, None)` expects `IndexError`; `(1, 7, None)`
  expects `TypeError`) — pins out-of-domain behavior.

**Conditioned on machine-checking.** The MVP does **not** run `kprove`; this is
constructed, not machine-checked — do **not** delete any test until `kprove` returns
`#Top` (and, for the tree tests, `(T-IND)` is closed). See "Reproduce".

---

## Reproduce the machine check

```sh
kompile mini-python.k --backend haskell      # compile the fragment semantics (Haskell backend)
kast    --backend haskell tree-height-spec.k # (optional) confirm claims parse to one AST
kprove  tree-height-spec.k                    # discharge the claims; expected: #Top for
                                              #   (MAX2) and the base+step of (REC)/(HEIGHT);
                                              #   (T-IND) remains an open [ESCALATION BOUNDARY]
```

A `#Top` upgrades `(MAX2)` and the per-node parts from **constructed** to
**machine-verified**; the `(REC)`/`(HEIGHT)` *lift* additionally needs the `(T-IND)`
structural-induction obligation closed via the papers before the §6 tree-test deletions
are safe.

*References: kframework.org; runtimeverification/k; K Tutorial Lesson 1.22. Roșu,
"Matching Logic", LMCS 2017. Chen & Roșu, "Matching μ-Logic", LICS 2019. Chen, Peña,
Rodrigues, Roșu, Trinh, "Unified fixpoint reasoning", OOPSLA 2020. Roșu & Ștefănescu,
FM 2012 / LICS 2013 (reachability logic & the Circularity rule).*
