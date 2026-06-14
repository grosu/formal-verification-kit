# PROOF — `gcd(a, b)` reachability proof (Euclidean algorithm)

This is the Euclidean `gcd` (loop `a, b = b, a % b` until `b == 0`). Its loop
"invariant" is **not** an accumulator/closed-form (the `sum` shape) — it is a
**preserved RELATION**: the quantity `gcd(a, b)` is held constant across the loop by
the number-theoretic Euclid identity. The companion `sum-up/`/`sum-down/` examples
show the accumulator shape; `insertion-sort/` shows the escalation-boundary
discipline this proof also uses.

**Status: constructed, not machine-checked — AND escalation-bounded.** *Doubly*
short of machine-verified: (1) the MVP does **not** run `kompile`/`kprove`; (2) the
construction has **one open `[ESCALATION BOUNDARY]` obligation** — the Euclid identity
`gcd(a,b) = gcd(b, a mod b)` (VC-EUCLID) — that the bundled tier cannot discharge.
The structural / control-flow proof (symbolic execution + the loop circularity +
composition) is complete; the number-theoretic *content* of one VC is the boundary.

Artifacts referenced (same directory):
[`gcd.py`](gcd.py) | [`mini-python.k`](mini-python.k) (the fragment semantics) |
[`gcd-spec.k`](gcd-spec.k) (the K claims + the spec-only `gcd`
symbol) | [`SPEC.md`](SPEC.md) and [`FINDINGS.md`](FINDINGS.md) (the `/formalize`
outputs).

The program ([`gcd.py`](gcd.py)):

```python
def gcd(a, b):
    while b:
        a, b = b, a % b
    return a
```

---

## 1. The reachability spec — the (GCD) function claim

The whole-function contract is one reachability rule `phi_pre => phi_post`: from a
configuration that *defines* `gcd` and *calls* it on non-negative `A, B`, execution
reaches a terminated configuration whose `result` holds `gcd(A, B)` — where `gcd` is
the **spec-only** symbol declared in `gcd-spec.k`'s `VERIFICATION` module (it
is verification vocabulary, never a program construct).

```
  phi_pre  == < def gcd(a,b): <body>   result = gcd(A,B) >_k  < result |-> _ >_store
              < .Map >_funcs  < .List >_stack    AND   A >= 0 AND B >= 0
  phi_post == < .K >_k  < result |-> gcd(A,B) >_store  < ?_ >_funcs  < .List >_stack
```

As the **(GCD)** `claim` in [`gcd-spec.k`](gcd-spec.k):

```k
claim
  <k>
    def gcd ( a , b ) : INDENT
      while b : INDENT a , b = b , a % b DEDENT
      return a
    DEDENT
    result = gcd ( A:Int , B:Int )
  => .K ... </k>
  <funcs> .Map => ?_:Map </funcs>
  <store> result |-> (_:Int => gcd(A, B)) </store>
  <stack> .List </stack>
  requires A >=Int 0 andBool B >=Int 0
  [all-path]
```

Reading: `requires A >= 0 andBool B >= 0` is the **precondition** (framed on every
step — see FINDINGS Finding 1 for why it is load-bearing). `<k>` rewrites to `.K`
(terminated). The post-`<store>` asserts `result |-> gcd(A,B)`; `<funcs> .Map => ?_`
says *some* function table now exists (witnessed by the `gcd` entry); `<stack> .List`
says the call stack is balanced again. `[all-path]` demands *every* terminating path
hit the target — sound here because mini-Python is deterministic. This is **partial
correctness**: it constrains terminating runs and (by default) says nothing about
halting (termination is clean for `gcd` — FINDINGS "Note").

---

## 2. The loop circularity — the (LOOP) claim (a PRESERVED RELATION)

The proof turns on one auxiliary claim about the loop, generalized over **both** `a`
and `b` (no accumulator to generalize — the "invariant" is the equation
`gcd(a,b) = gcd(A,B)`):

```
  (LOOP)   < while b: (a,b = b, a%b) | a|->A, b|->B >  AND  A >= 0 AND B >= 0
       =>  < .K | a |-> gcd(A,B),  b |-> 0 >
```

As the **(LOOP)** `claim` in [`gcd-spec.k`](gcd-spec.k):

```k
claim
  <k> while b : INDENT a , b = b , a % b DEDENT => .K ... </k>
  <store>
    a |-> (A:Int => gcd(A, B))
    b |-> (B:Int => 0)
  </store>
  requires A >=Int 0 andBool B >=Int 0
  [all-path]
```

It reads: *running the loop from `(a,b) = (A,B)` reaches `a = gcd(A,B)`, `b = 0`.*
The post-value `gcd(A,B)` plays the role the classical invariant used to — but where
`sum`'s post-value was a polynomial *built up*, here it is a relation *preserved*.

---

## 3. Informal proof (English)

Reachability logic replaces the hand-chosen *loop invariant* with **coinduction**: K
adds every claim in the module to its hypotheses, so **(LOOP) may assume itself**
while proving itself — *provided* it first makes one genuine step (guardedness). The
expression `gcd(a,b)` plays the role the invariant used to.

**Prove (LOOP).** Run the loop one step. `(while)` evaluates the truthiness guard `b`
— that genuine first step earns the right to reuse the hypothesis — then case-split
on the guard (a bare Int `B` coerces to `B =/= 0`):

- **Guard true (`B != 0`):** the body runs. The tuple swap `a, b = b, a % b`
  desugars (via the temp `t`, see `mini-python.k`) to `t = a; a = b; b = t % b`,
  giving `a = B`, `b = A mod B`. Control returns to the same `while`. **Invoke (LOOP)
  itself** at `{A := B, B := A mod B}` (its precondition `B >= 0 AND A mod B >= 0`
  follows: `A mod B >= 0` because `modInt` is non-negative for `B > 0`). The one fact
  to check is that the post-value is unchanged: `gcd(B, A mod B) = gcd(A, B)` — this
  is **VC-EUCLID**, the [ESCALATION BOUNDARY] obligation.
- **Guard false (`B == 0`):** the body never runs, `a` stays `A`, and the post-value
  is `gcd(A, 0) = A` — this is **VC-BASE**, the clean bundled `[simplification]`. So
  `a = gcd(A, B)` (since `gcd(A,0) = A` and `B = 0` makes `gcd(A,B) = gcd(A,0)`) and
  `b = 0`. OK.

Both branches land on (LOOP)'s post-state, and the hypothesis was used only after a
real step, so the circularity discharges — **modulo VC-EUCLID**, which is exactly the
number-theoretic identity that makes the relation preserved.

**Prove (GCD).** Execute the program: `def gcd` files the body into `<funcs>`;
`result = gcd(A, B)` evaluates the arguments, and `(call)` pushes the caller's frame,
gives the callee a fresh scope, and binds `a = A`, `b = B`. Then the loop — and here
we **use (LOOP) as a lemma** at `{A, B}` (its precondition `A, B >= 0` is exactly the
function precondition), making `a = gcd(A, B)`, `b = 0`. Then `return a` pops the
frame, restores the caller store, and the returned value is assigned to `result`.
Final store: `result |-> gcd(A, B)` — exactly the spec. (QED modulo VC-EUCLID.)

---

## 4. Machine-detailed proof sketch (for `kprove`)

Each step cites a rule of [`mini-python.k`](mini-python.k); VCs are discharged by Z3
plus the bundled `[simplification]` lemmas — *except* VC-EUCLID, which is routed out.

**PART A — (LOOP) by circularity.** Reuse (LOOP) only after >= 1 genuine rewrite.
- **A1 progress:** `(while)` -> `b ~> #whileLoop(b, Bdy)`. This `=>+` discharges
  guardedness.
- **A2 guard:** the guard `b` is `strict` -> `(lookup)` `b => B`; the truthiness
  rule coerces `B => B =/=Int 0`.
- **A3 split** (`#Or` on `B =/=Int 0`):
  - **true / `(while-t)`:** rebuild the `while` (never an `if`); the swap desugars
    `t = a; a = b; b = subst(a % b, a, t) = t % b`; `(asgn)`x3 + `(mod)` give
    `a |-> B`, `b |-> A modInt B`; **reuse (LOOP)** at `{A := B, B := A modInt B}`.
    Closes via **VC-EUCLID** (+ the linear in-range side conditions).
  - **false / `(while-f)`:** `B = 0`; store unchanged. Closes via **VC-BASE**
    (`gcd(A,0) = A`), a bundled `[simplification]`.

**PART B — (GCD) over the real call layer.**
`(def)` files the body (witnesses `?_:Map`) -> arg eval + `(call)` pushes
`state(CONT, STORE)` and resets `<store>` to `.Map` -> `#makeBindings((a,b),(A,B))`
binds `a |-> A`, `b |-> B` -> **apply (LOOP) at `{A, B}`** (precondition `A,B >= 0`
from the function precondition), `a |-> gcd(A,B)`, `b |-> 0` -> `(return)` pops the
frame, restores caller store, delivers the `Int` -> `(asgn)` `result |-> gcd(A,B)`.
Map-extensionality `[simplification]` reduces the post-store `#Equals` to the scalar
`gcd(A,B)` obligation.

**Verification conditions.**

| VC | Statement | Discharged by |
|---|---|---|
| **VC-modpos** | `B > 0 => 0 <= A modInt B < B` (non-negativity + range of `modInt`) | **Z3** (property of floor mod) OK |
| **VC-pre** | `A,B >= 0 AND B > 0 => B >= 0 AND (A modInt B) >= 0` (LOOP precondition survives the step) | **Z3** (linear + VC-modpos) OK |
| **VC-ext** | post-store cell `#Equals` => value `gcd(A,B)` | **map-extensionality `[simplification]`** OK |
| **VC-BASE** | `gcd(A, 0) = A` (loop-exit value) | bundled `gcd(A,0) => A` **`[simplification]`** OK |
| **VC-EUCLID** | `gcd(B, A mod B) = gcd(A, B)` for `B != 0` (loop-PRESERVATION crux) | **`[ESCALATION BOUNDARY]`** — inductive number theory (divisibility lattice / Bezout); NOT linear, NOT division-by-even. Routed to LICS'19 / OOPSLA'20. NOT faked `[trusted]`. NO |

So **VC-modpos**, **VC-pre**, **VC-ext** and **VC-BASE** discharge with the bundled
tier; **VC-EUCLID** is the single open inductive obligation. The structural proof
(symbolic execution + the loop circularity + the call/return composition) is
complete; the *number-theoretic identity* is the boundary. This is exactly the kit's
documented escalation case (its primers route number-theoretic / inductive facts to
the mu-logic papers).

> **Why VC-EUCLID is not faked.** Writing it as a `[simplification]` rule
> `gcd(A,B) => gcd(B, A modInt B) requires B =/=Int 0` and/or marking it `[trusted]`
> would *manufacture* confidence the kit does not have — the bundled tier genuinely
> cannot derive it. The honest deliverable **names it as an open obligation** (it is
> commented-but-disabled in `gcd-spec.k`) and routes it. See FINDINGS #3.

---

## 5. FINDINGS — hidden subtle behavior (benefit 2; does NOT depend on machine-checking)

Full detail in [`FINDINGS.md`](FINDINGS.md). The two the formal lens makes sharp:

> **A missing precondition — non-negative inputs (Finding 1).** Python's `%` is
> *floor* modulo (sign of the divisor), so the clean contract forced `a, b >= 0`.
> Executed:
>
> | input | observed | expected (math gcd) |
> |---|---|---|
> | `(12, -8)` | `-4` | `4` |
>
> The result is **negative**. Recommendation: document/enforce `a, b >= 0`, or
> `abs()`-normalize. This is the verified domain — what `(GCD)`'s `requires` encodes.

> **The `gcd(0,0)` edge (Finding 2).** Returns `0` — the *conventional* value
> (`math.gcd(0,0) == 0`), even though "greatest" common divisor is undefined there
> (every integer divides `0`). Falls straight out of the base case `gcd(a,0) = a`.
> Correct by convention; flagged because it is the one input with no literal meaning.

> **Spec-difficulty = escalation, not a defect (Finding 3).** The proof is complete
> *modulo* VC-EUCLID. That the bundled tier cannot close it is the honest signal that
> the Euclid identity needs inductive number theory — **route:** LICS'19 / OOPSLA'20
> (`knowledge/sources.md`; `/verify --refresh` re-fetches them). The code is right;
> the *automated proof* needs more theory.

---

## 6. TEST REDUNDANCY — fewer tests, faster CI (benefit 1; DOUBLY conditioned)

> A verified function is proven for *all* inputs in its domain, so in-domain unit
> tests that re-check single points become redundant — **once the proof actually
> discharges.** Here that is gated **twice** (machine-check AND VC-EUCLID).

If `(GCD)` were fully discharged, it would prove `gcd(a, b) = gcd(A, B)` for **every**
`a, b >= 0`. The inline `__main__` asserts in [`gcd.py`](gcd.py) map as follows:

| Test | In verified domain (`a,b >= 0`)? | Status |
|---|---|---|
| `gcd(12, 8) == 4`     | yes | *would-be* redundant (`4 = gcd(12,8)`) |
| `gcd(54, 24) == 6`    | yes | *would-be* redundant |
| `gcd(17, 5) == 1`     | yes (coprime) | *would-be* redundant |
| `gcd(0, 5) == 5`      | yes (zero arg, in domain) | *would-be* redundant |
| `gcd(5, 0) == 5`      | yes | *would-be* redundant |
| `gcd(0, 0) == 0`      | yes (edge; Finding 2) | *would-be* redundant — but **KEEP** as the convention pin |
| `gcd(100, 100) == 100`| yes | *would-be* redundant |

- **KEEP `gcd(0, 0) == 0`.** It pins the *convention* (Finding 2) at the one input
  where "greatest common divisor" has no literal maximum. The proof reproduces it via
  `gcd(a,0) = a`, but keeping it guards the convention against a future refactor.
- **ADD an out-of-domain boundary test.** There is currently **no** test for the
  Finding-1 boundary (negative inputs). Add e.g. `gcd(12, -8) == -4` (pin the
  observed sign-of-divisor result) — the analogue of `sum`'s kept `sum_to_n(-1)`.
  It guards behavior the proof does **not** cover.

**Honesty gate — stronger than usual here.** Do **not** drop any test now, for **two**
reasons: (1) the MVP did not run `kprove` ("constructed, not machine-checked"); (2)
the construction has an **open `[ESCALATION BOUNDARY]`** (VC-EUCLID) — so `(GCD)` is
not even fully constructed-to-`#Top` on paper. The "*would-be* redundant" tests become
*actually* redundant only after **both**: VC-EUCLID is supplied (the number-theory
lemma), **and** `kprove` returns `#Top`. Until then they are your only real
correctness coverage — **keep all of them.**

---

## Reproduce the (attempted) machine check

```sh
kompile mini-python.k --backend haskell        # compile the fragment semantics
kast    --backend haskell gcd-spec.k   # (optional) confirm claims parse
kprove  gcd-spec.k                       # EXPECTED HERE: residual goal on
                                                 # VC-EUCLID, NOT #Top — until the
                                                 # Euclid identity gcd(a,b)=gcd(b,a%b)
                                                 # (escalation) is added.
```

`kprove` inherits the Haskell backend from the `kompile`d definition, so it needs no
`--backend haskell` of its own. Reaching `#Top` requires **first** adding the Euclid
identity as a justified lemma (per LICS'19 / OOPSLA'20 number-theory reasoning),
**then** running the toolchain. Only a `#Top` upgrades everything above from
**constructed (escalation-bounded)** to **machine-verified**, and only then are the
S6 test deletions safe.

---

*Everything above is **constructed, not machine-checked**, and references only sibling
files in this directory. References: kframework.org; runtimeverification/k; K Tutorial
Lesson 1.22. Rosu, "Matching Logic", LMCS 2017. Chen & Rosu, "Matching mu-Logic",
LICS 2019. Rosu & Stefanescu, FM 2012 / LICS 2013 (reachability logic & Circularity).
Chen et al., OOPSLA 2020 (inductive/fixpoint reasoning — the route for VC-EUCLID).*
