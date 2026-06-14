# PROOF — `fib(n)` reachability proof

This is the **iterative-loop-over-a-recursively-defined-quantity** member of the
example cluster: like the `sum-up` / `sum-down` loops it is verified by a
**loop-invariant circularity** `(LOOP)` (NOT a recursive-call contract — the program
has no recursion; it is an explicit `while` counter loop). What is new versus those
examples is the **postcondition vocabulary**: the value computed is defined by a
**recurrence**, so the spec introduces a **spec-only recursive symbol**
`fib(Int) [function]`, and the inductive step is discharged **definitionally** by
unfolding `fib`'s defining equation rather than by an arithmetic (exact-halving)
lemma.

**Status: constructed, not machine-checked.** The artifacts are built to be
`kompile`/`kprove`-checkable but the toolchain was **not run** in this environment
(MVP stopgap). Treat the result as "constructed" until §"Reproduce" turns it into
"machine-verified."

Artifacts referenced (same directory):
[`fib.py`](fib.py) · [`mini-python.k`](mini-python.k) (the fragment semantics) ·
[`fibonacci-spec.k`](fibonacci-spec.k) (the K claims + the spec-only `fib`) ·
[`SPEC.md`](SPEC.md) and [`FINDINGS.md`](FINDINGS.md) (the `/formalize` outputs).

The program ([`fib.py`](fib.py)):

```python
def fib(n):
    prev = 0
    curr = 1
    i = 0
    while i < n:
        prev, curr = curr, prev + curr
        i = i + 1
    return prev
```

---

## 0. The spec-only symbol `fib` (the new vocabulary)

The quantity computed has no polynomial closed form; it is defined by a recurrence.
So the `VERIFICATION` module declares a **spec-only** symbol (never a language
construct — it is absent from `mini-python.k`, and the program never calls it):

```k
syntax Int ::= fib(Int) [function, total, smtlib(fib)]

rule fib(0) => 0                                    [simplification]
rule fib(1) => 1                                    [simplification]
rule fib(N:Int) => fib(N -Int 1) +Int fib(N -Int 2)
  requires N >Int 1                                 [simplification]
```

These three defining equations are the **only** facts about `fib` the proof uses.
This is the "spec-only abstraction function" idiom from
`knowledge/k-framework.md` (there `isSorted`/`bag`; here a recursively-defined
*number*).

> **`[ESCALATION BOUNDARY]` — `fib`'s totality / well-definedness.** `fib` is
> declared `[function, total]`, but the bundled VC tier does **not** machine-prove
> that this recurrence is well-defined (terminating, single-valued) for every
> `N >= 0`. That is a well-founded-recursion / `mu`-logic fact (least fixpoint of the
> defining functor, Knaster–Tarski). It is named here as an **open obligation** and
> routed to the papers (`chen-rosu-2019-lics`, Matching mu-Logic; inductive sorts in
> `chen-lucanu-rosu-2020-tr`). It is **NOT** admitted as `[trusted]` — doing so would
> fake confidence the kit does not have. Every *other* step below is within the
> fast-path recipe; this single boundary is the only escalation.

---

## 1. The reachability spec — the (FIB) function claim

The whole-function contract is one reachability rule `phi_pre => phi_post`: from a
configuration that *defines* `fib` and *calls* it on a non-negative `N`, execution
reaches a terminated configuration whose `result` holds `fib(N)`.

```
  phi_pre  == < def fib(n): <body>   result = fib(N) >_k  < result |-> _ >_store
              < .Map >_funcs  < .List >_stack    /\   N >= 0
  phi_post == < .K >_k  < result |-> fib(N) >_store  < ?_ >_funcs  < .List >_stack
```

As the **(FIB)** `claim` in [`fibonacci-spec.k`](fibonacci-spec.k):

```k
claim
  <k>
    def fib ( n ) : INDENT
      prev = 0
      curr = 1
      i = 0
      while i < n : INDENT prev , curr = curr , prev + curr  i = i + 1 DEDENT
      return prev
    DEDENT
    result = fib ( N:Int )
  => .K ... </k>
  <funcs> .Map => ?_:Map </funcs>
  <store> result |-> (_:Int => fib(N)) </store>
  <stack> .List </stack>
  requires N >=Int 0
  [all-path]
```

Reading: `requires N >=Int 0` is the **precondition** (framed on every step). The
`<k>` cell rewrites the program to `.K` (terminated). The post-`<store>` asserts
`result |-> fib(N)`; `<funcs> .Map => ?_:Map` says *some* function table now exists
(the `?_` existential witnessed by the `fib` entry); `<stack> .List` says the call
stack is balanced again. `[all-path]` demands every terminating path hit the target
— sound here because mini Python is deterministic, so all-path coincides with
one-path. This is **partial correctness**: it constrains terminating runs and says
nothing about whether the loop halts.

---

## 2. The loop circularity — the (LOOP) claim

The proof turns on one auxiliary claim about the loop, generalized over the counter
`I`, with side condition `0 <= I <= N`, and the **coupled** invariant pinning the two
running values to consecutive Fibonacci numbers:

```
  (LOOP)   < while i<n: (prev,curr=curr,prev+curr; i=i+1)
              | prev |-> fib(I), curr |-> fib(I+1), i |-> I, n |-> N >  /\  0 <= I <= N
       =>   < .K | prev |-> fib(N), curr |-> fib(N+1), i |-> N, n |-> N >
```

As the **(LOOP)** `claim` in [`fibonacci-spec.k`](fibonacci-spec.k):

```k
claim
  <k>
    while i < n : INDENT prev , curr = curr , prev + curr  i = i + 1 DEDENT => .K ...
  </k>
  <store>
    prev |-> (fib(I) => fib(N))
    curr |-> (fib(I +Int 1) => fib(N +Int 1))
    i    |-> (I:Int => N)
    n    |-> N:Int
  </store>
  requires 0 <=Int I andBool I <=Int N
  [all-path]
```

It reads: *running the loop from counter `i = I`, with `prev = fib(I)` and
`curr = fib(I+1)` and `0 <= I <= N`, reaches `prev = fib(N)`, `curr = fib(N+1)`,
`i = N`.* The coupling `(prev, curr) = (fib(I), fib(I+1))` IS the invariant — it is
stated in the LHS store values.

---

## 3. Informal proof (English)

Reachability logic replaces the hand-chosen *loop invariant* with **coinduction**: K
adds every claim in the module to its hypotheses, so **(LOOP) may assume itself**
while proving itself — *provided* it first makes one genuine step (guardedness). The
coupled pair `(fib(I), fib(I+1))` plays the role the invariant used to.

**Prove (LOOP).** Run the loop one step. `(while)` evaluates the guard `i < n` — that
genuine first step earns the right to reuse the hypothesis — then case-split on the
guard:

- **Guard true (`I < N`):** the body runs.
  - The **simultaneous** assignment `prev, curr = curr, prev + curr` evaluates the
    WHOLE right tuple first (reading the old store: `curr = fib(I+1)`,
    `prev + curr = fib(I) + fib(I+1)`), then binds both targets at once. So
    `prev := fib(I+1)` and `curr := fib(I) + fib(I+1)`.
  - `i = i + 1` makes `i := I + 1`; control returns to the same `while`.
  - **Invoke (LOOP) itself** at `I := I+1` (its side condition `0 <= I+1 <= N`
    follows from `0 <= I` and `I < N`). For the invocation to type-check, the new
    state must match `prev = fib(I+1)`, `curr = fib((I+1)+1)`. The first is immediate.
    The second is the one VC: `fib(I) + fib(I+1) = fib(I+2)` — exactly `fib`'s third
    defining rule at index `I+2` (legal since `I+2 > 1`, from `I >= 0`). DEFINITIONAL.
- **Guard false (`I >= N`, and `I <= N` from the precondition):** then `I = N`, the
  body never runs, the store is unchanged, so `prev = fib(I) = fib(N)`,
  `curr = fib(I+1) = fib(N+1)`, `i = N`. Matches the post-state directly.

Both branches land on (LOOP)'s post-state, and the hypothesis was used only after a
real step, so the circularity discharges. The side condition **`0 <= I <= N` is
necessary**: drop the upper bound and the exit branch no longer pins `i = N`; drop
the lower bound and the inductive unfold `fib(I+2) = fib(I) + fib(I+1)` is no longer
justified (it needs `I >= 0`).

**Prove (FIB).** Execute the program against the semantics: `def fib` files the body
into `<funcs>`; `result = fib(N)` evaluates the argument, and `(call)` pushes the
caller's frame, gives the callee a fresh scope, and binds `n = N`. The body runs
`prev = 0` (`= fib(0)`), `curr = 1` (`= fib(1)`), `i = 0` — and here we **use (LOOP)
as a lemma** at `I = 0` (its side condition `0 <= 0 <= N` follows from `N >= 0`),
making `prev = fib(N)`. Then `return prev` pops the frame, restores the caller store,
and the returned value is assigned to `result`. Final store: `result |-> fib(N)` —
exactly the spec. QED

---

## 4. Machine-detailed proof sketch (for `kprove`)

The symbolic-execution skeleton; each step cites a rule of
[`mini-python.k`](mini-python.k); the VCs are discharged by Z3 plus the
`[simplification]` rules in [`fibonacci-spec.k`](fibonacci-spec.k).

**PART A — (LOOP) by circularity.** Reuse (LOOP) only after >= 1 genuine rewrite.
- **A1 progress:** `(while)` => `(i < n) ~> #whileLoop(i < n, Bdy)`. This `=>+`
  transition discharges guardedness.
- **A2 guard:** `<` is `seqstrict` => `(lookup)` `i => I`, `n => N`; `(lt)` =>
  `I <Int N`.
- **A3 split** (`#Or` on `I <Int N` under `0 <=Int I andBool I <=Int N`):
  - **true / `(while-t)`:** rebuild the `while` (never an `if`). The simultaneous
    assignment is `strict(3,4)`: `(lookup)` `curr => fib(I+1)`, then `(lookup)+(add)`
    `prev + curr => fib(I) +Int fib(I+1)`; the binding rule sets
    `prev |-> fib(I+1)`, `curr |-> fib(I) +Int fib(I+1)` in ONE step. Then
    `(asgn)` for `i = i + 1` gives `i |-> I +Int 1`. **Reuse (LOOP)** at `I := I+Int 1`.
    Closes via **VC1**.
  - **false / `(while-f)`:** antisymmetry (`I >=Int N` and `I <=Int N`) => `I = N`;
    store unchanged. Closes via **VC2** (trivial, both sides syntactically `fib(N)` /
    `fib(N+1)` / `N`).

**PART B — (FIB) over the real call layer.**
`(def)` files the body (witnesses `?_:Map`) => arg eval + `(call)` pushes
`state(CONT, STORE)` and resets `<store>` to `.Map` => `#makeBindings((n),(N))`
binds `n |-> N` => `(asgn)x3` `prev |-> 0`, `curr |-> 1`, `i |-> 0` => **apply (LOOP)
at `I := 0`** (precondition `0 <=Int 0 andBool 0 <=Int N` from `N >=Int 0`), needs
**VC3** to match the entry coupling, then `prev |-> fib(N)` => `(return)` pops the
frame, restores caller store, delivers the `Int` => `(asgn)` `result |-> fib(N)`.
Map-extensionality `[simplification]` reduces the post-store `#Equals` to a scalar
identity (both `fib(N)`), which is `#Top`.

**Verification conditions:**

| VC | Statement | Discharged by |
|---|---|---|
| **VC1** | `fib(I) + fib(I+1) = fib(I+2)` (the inductive step) | `fib`'s 3rd defining `[simplification]` rule (DEFINITIONAL), under `I >= 0` => `I+2 > 1` |
| **VC2** | exit at `I = N`: `fib(I)=fib(N)`, `fib(I+1)=fib(N+1)` | Z3 (substitute `I = N`; syntactic) |
| **VC3** | entry coupling `0 = fib(0)`, `1 = fib(1)` | `fib`'s 1st & 2nd defining `[simplification]` rules |
| sides | `N>=0 => 0<=0<=N`; `0<=I /\ I<N => 0<=I+1<=N` | Z3 (linear) |

Note what is **absent** vs. `sum-up`: there is **no** exact-halving / division-by-even
lemma, because the Fibonacci recurrence is **additive**, not multiplicative — the
step VC is a single unfold of `fib`'s definition, not a nonlinear `/Int` fact. The
arithmetic tier here is strictly lighter.

---

## 5. FINDINGS — surfaced by formalizing (benefit 2)

See [`FINDINGS.md`](FINDINGS.md) for the full report. Headline items:

- **Finding 1 (real, `n < 0`).** The verified contract only holds for `n >= 0`. For
  negative `n` the guard `i < n` is false on entry, the loop never runs, and the code
  returns `prev = 0` — but `fib(n)` is **undefined** for negative `n`, so that `0` is
  **meaningless** (not merely a wrong value vs. a defined formula, as in `sum-up`).
  Input -> observed vs expected: `n = -3` -> returns `0`, expected = undefined.
  **Recommendation:** enforce / document `n >= 0`.
- **Finding 2 (positive, performance).** The iterative two-variable loop is **O(n)**;
  a naive recursive transcription of the `fib(n)=fib(n-1)+fib(n-2)` definition would
  be **exponential**. This code computes `fib(n)` in exactly `n` constant-work steps —
  the right design. Recorded as a positive finding.
- **Finding 3 (spec-difficulty signal).** The load-bearing side condition
  `0 <= I <= N` — the lower bound `0 <= I` is *required by the recurrence* (so the
  unfold `fib(I+2)=fib(I)+fib(I+1)` is legal), pointing back at the same `n >= 0`
  domain boundary as Finding 1.

---

## 6. TEST REDUNDANCY — fewer tests, faster CI (benefit 1)

> **A verified function is proven correct for all inputs in its domain**, so unit
> tests that only re-check points inside that domain become redundant.

`fib.py`'s `__main__` block asserts these in-domain points. Once `(FIB)` is
machine-checked, it proves `fib(n) = fib(n)` (the n-th Fibonacci number) for **every**
`n >= 0`, so each single-point assertion is subsumed:

- `fib(0) == 0`  -> subsumed (`fib(0) = 0`,  `0 >= 0`). **Redundant.**
- `fib(1) == 1`  -> subsumed (`fib(1) = 1`,  `1 >= 0`). **Redundant.**
- `fib(2) == 1`, `fib(3) == 2`, `fib(4) == 3`, `fib(5) == 5`, `fib(6) == 8`,
  `fib(7) == 13`, `fib(10) == 55`, `fib(20) == 6765` -> each subsumed (all in-domain
  `n >= 0`). **Redundant.**

**CI saving.** These 10 in-domain unit asserts only re-check points the single proof
already covers for *all* `n >= 0`, so dropping them removes 10 assertions from every
run — one proof replaces an unbounded family of point-checks. (As a self-test inside
`__main__`, they also exercise the print/wiring; if you keep that smoke check, keep at
most one representative assertion, not all ten.)

**Keep any out-of-domain test.** A test pinning negative-input behavior (e.g.
`fib(-1) == 0`) is **outside** the verified domain `n >= 0` and is exactly where the
§5 Finding 1 lives — **keep it** (it pins behavior the proof does not cover, and
guards against a regression if a sign guard is later added). `fib.py` currently has no
such test; adding one is advisable per Finding 1.

**Conditioned on machine-checking.** This recommendation is conservative and
recommendation-only. The MVP **does not run `kprove`** — the proof here is
"constructed, not machine-checked." Do **not** delete any test until the claims
actually discharge (`kprove` returns `#Top`); see "Reproduce" below.

---

## Reproduce the machine check

```sh
kompile mini-python.k --backend haskell      # compile the fragment semantics
kast    --backend haskell fibonacci-spec.k # (optional) confirm claims parse
kprove  fibonacci-spec.k                    # expected: #Top  (all claims proved)
```

`kprove` inherits the Haskell backend from the `kompile`d definition above, so it
needs no `--backend haskell` of its own.

A `#Top` result upgrades everything above from **constructed** to **machine-verified**
— *except* the `[ESCALATION BOUNDARY]` of §0 (`fib`'s totality/well-definedness),
which is a separate `mu`-logic obligation routed to the papers, not something `kprove`
discharges from these `[simplification]` rules alone. Only after `#Top` are the §6
test deletions safe.

---

*References: kframework.org; runtimeverification/k; K Tutorial Lesson 1.22.
Rosu, "Matching Logic", LMCS 2017. Chen & Rosu, "Matching mu-Logic", LICS 2019
(the totality/well-definedness escalation target). Rosu & Stefanescu, FM 2012 /
LICS 2013 (reachability logic & the Circularity rule). Sibling artifacts:
[`fib.py`](fib.py), [`mini-python.k`](mini-python.k),
[`fibonacci-spec.k`](fibonacci-spec.k), [`SPEC.md`](SPEC.md),
[`FINDINGS.md`](FINDINGS.md).*
