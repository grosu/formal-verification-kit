# Reachability & Circularities — the proof technique and the recipe

This file is the engine room of the kit. It explains the one proof idea that makes
everything else work — **reachability rules** and the **Circularity rule** — and
then gives the concrete, numbered **recipe** that `/formalize` and `/verify`
follow. Read [`matching-logic.md`](matching-logic.md) for the logic underneath
(patterns-as-sets, the connectives) and [`k-framework.md`](k-framework.md) for how
this is written as K `claim`s, `kompile`/`kprove`, `seqstrict`/heating, and
`[simplification]`. The fully worked instance lives in
[`../examples/sum-up/`](../examples/sum-up/).

> **Fast-path disclaimer.** This is a *distilled* recipe tuned for the common
> case: imperative functions with simple, counting `while`/`for` loops over
> integers and maps. It covers those well. For recursion, recursive data
> structures (lists/trees/heaps), binders, or concurrency, it is a *starting
> point only* — escalate to the source papers (see the LIMITS section and
> [`sources.md`](sources.md)). Worked examples are the best teacher; the example
> library will grow.

---

## 1. A reachability rule generalizes a Hoare triple

A **reachability rule** is a pair of configuration patterns

```
    φ  ⇒  φ'
```

read operationally as: *every (terminating) execution starting from a state that
matches `φ` reaches a state that matches `φ'`.* Each `φ` is a *matching-logic
pattern* — a symbolic configuration `⟨…⟩` (the K cells: `<k>`, `<store>`, …)
conjoined with a first-order side constraint (`#And` a `requires`).

This is exactly a Hoare triple `{Pre} code {Post}`, but recast so that **the code
itself lives inside the pattern** (in the `<k>` cell) instead of being a separate
syntactic object. The win is unification:

- **One operational semantics serves both execution and proof.** The same rewrite
  rules that *run* a program (`krun`) are the axioms you reason with (`kprove`).
  There is no separate axiomatic/Hoare semantics to write, keep in sync, and trust
  — a classic source of soundness bugs. `φ ⇒ φ'` *is* "the semantics, run
  symbolically, from `φ`, lands in `φ'`."
- Pre/postconditions, frame conditions, and the program text are all just parts of
  one pattern, manipulated by one set of rules.

A K `claim` *is* a reachability rule; the worked
[`../examples/sum-up/mini-python-spec.k`](../examples/sum-up/mini-python-spec.k) is two
of them — the function contract `(SUM)` and the loop circularity `(LOOP)`.

---

## 2. The reachability proof system

You prove `A ⊢ φ ⇒ φ'` (the semantics `A` entails the rule) with these rules. The
first six are routine "symbolic execution + glue"; the seventh, **Circularity**,
is the whole point.

| Rule | What it does |
|---|---|
| **Reflexivity** | `A ⊢ φ ⇒ φ`. The empty (zero-step) execution. This is precisely where guardedness bites: the circularity hypothesis is **forbidden** from closing a goal via Reflexivity alone, since that would discharge the claim with zero progress — see §3. The hypothesis becomes available only on a goal that has already strictly advanced. |
| **Axiom** (+ framing) | Apply one semantic rule `φ_l ⇒ φ_r ∈ A` (with a substitution). **Framing** carries the untouched parts — the rest of the `<k>` computation, unmentioned store bindings, the side constraint — unchanged around the step. In K this is the automatic `...` cell-completion. |
| **Transitivity** | From `A ⊢ φ ⇒ φ₁` and `A ⊢ φ₁ ⇒ φ'`, get `A ⊢ φ ⇒ φ'`. Chains steps. |
| **Consequence** | Strengthen the pre / weaken the post via a **first-order implication** discharged by an SMT oracle (Z3) or `[simplification]` lemmas: if `φ → φ₀`, `A ⊢ φ₀ ⇒ φ₀'`, `φ₀' → φ'`, then `A ⊢ φ ⇒ φ'`. This is where arithmetic VCs are dispatched. |
| **Case Analysis** | Split a goal whose precondition is a disjunction `φ ≡ φ₁ #Or φ₂` and prove each branch. In K this is the prover's `#Or` split — e.g. the loop guard being `true` vs `false`. |
| **Abstraction** | Existentially quantify away variables that occur in the precondition but **not** in the postcondition (e.g. the overwritten initial values `∃S₀,I₀` — gone from the post once the loop has run). |
| **Circularity** | Use a rule as its own hypothesis — see §3. |

(See [`k-framework.md`](k-framework.md) for which K/`kprove` mechanism realizes
each: `seqstrict` heating ↔ the operand micro-steps of Axiom, `#Or` ↔ Case
Analysis, the SMT/`[simplification]` oracle ↔ Consequence, `...` ↔ framing. Note
the `seqstrict` heating/cooling rules are themselves auto-generated semantic rules,
so they are applied *via* Axiom — not a separate proof rule.)

---

## 3. The Circularity rule — the key idea

```
    A ∪ {φ ⇒ φ'}  ⊢  φ ⇒ φ'
    ─────────────────────────
        A  ⊢  φ ⇒ φ'
```

You are allowed to **assume the very rule you are trying to prove** while proving
it — *provided* you only ever use that hypothesis **after at least one genuine
`=>⁺` step** (one real semantic transition). This proviso is **guardedness**, and
it is what makes the otherwise-circular argument a sound **guarded coinduction**:
every appeal to the hypothesis is "paid for" by real progress, so you can never
discharge the goal with zero work. Concretely, guardedness is enforced by
**forbidding the hypothesis from closing a goal via Reflexivity alone** (zero
steps): the hypothesis is available only on a goal that has *strictly advanced* by
at least one genuine step. That single side condition is the whole soundness story.

**It replaces the loop invariant.** Classically you invent an invariant `Inv`,
prove it is established, preserved by the body, and implies the postcondition on
exit. Here, instead:

- The loop's **own reachability claim is the coinductive hypothesis.** Run the
  loop one step (evaluate the guard — that is the genuine `=>⁺` that earns the
  hypothesis), case-split on the guard, and in the *body-taken* branch you reach
  the same loop in a shifted state, where you **invoke the claim on itself**.
- The role the invariant used to play is now played by the **closed-form
  expression in the claim's postcondition**, generalized over the
  accumulator/counter (e.g. the running sum `S + (I+N)·(N−I+1)/2`).

In [`../examples/sum-up/`](../examples/sum-up/) this is the `(LOOP)` claim: running the
loop from counter `i = I` (with side condition `I ≤ N+1`) adds
`Σ_{k=I}^{N} k = (I+N)·(N−I+1)/2` to `s` and leaves `i = N+1`. Proving it, the
guard-evaluation step discharges guardedness; the *guard-true* branch invokes
`(LOOP)` at `{S := S+I, I := I+1}`; the *guard-false* branch (`I = N+1`) gives the
empty sum `0`. K realizes this without ceremony: **every `claim` in the module is
automatically a circularity available as a hypothesis.**

**The same principle covers recursion.** A recursive function has no loop, but it
has a *back-edge*: the recursive call. So the **function's own contract is the
coinductive hypothesis** — `f(N) ⇒ result(N)` discharges its inner call `f(N−1)`.
Guardedness comes from the **`call` step** (entering the body) taken before the
hypothesis is reused, exactly as guard-evaluation does for a loop; the **base case**
is the *exit* branch. See [`../examples/sum-recursive/`](../examples/sum-recursive/):
the `(REC)` claim `sum_recursive(N) ⇒ N*(N+1)/2` (side condition `N ≥ 0`) discharges
`sum_recursive(N−1)` on the recursive branch, with `n == 0` as the base case.

---

## 4. THE RECIPE

This is what `/formalize` then `/verify` actually do, step by step.

1. **Get a K semantics of the fragment (mini-X).** Build (or obtain) a minimal K
   semantics covering *only* the constructs the target code uses — the "mini-X"
   stopgap, exactly as the example builds *mini Python*. Syntax + configuration
   cells + rewrite rules. See [`k-framework.md`](k-framework.md) for how, and
   [`../examples/sum-up/mini-python.k`](../examples/sum-up/mini-python.k) for a complete
   one. *(Roadmap: full per-language K semantics replaces this step.)*

2. **State the function spec as a reachability rule** `φ_pre ⇒ φ_post`. A K
   `claim` whose `<k>` cell rewrites the program to `.K` (terminated), whose
   `<store>`/output cells assert the postcondition, and whose `requires` is the
   precondition (e.g. `N >= 0`). Cf. the `(SUM)` claim and its function contract
   `result ↦ N*(N+1)/2`.

3. **For each loop (or recursive function), state the circularity claim.** Write a second
   `claim` for the loop alone, **generalized over the accumulator and counter**
   (don't pin them to their entry values — make them symbolic `S`, `I`), with the
   loop's closed form in the postcondition. **Include the soundness side
   condition** that bounds the counter, e.g. `I ≤ N+1`. This side condition is not
   cosmetic: without it the claim is *false* (for `I ≥ N+2` the body never runs, so
   the true sum is `0`, but the closed form `(I+N)·(N−I+1)/2` goes **negative** —
   e.g. `N=0, I=2` gives `−1`, `N=1, I=3` gives `−2`).

   **For a recursive function** (no loop), state the **function-contract circularity**
   instead: `f(args) ⇒ result`, generalized over the symbolic argument(s), with the
   soundness precondition (e.g. `N ≥ 0`). K uses it as its own hypothesis to discharge
   the recursive call; the *base case* is the non-recursive branch. See `(REC)` in
   [`../examples/sum-recursive/`](../examples/sum-recursive/).

4. **Prove it** by symbolic execution against the semantics:
   - Drive the `<k>` cell with the rules: `seqstrict` **heating/cooling** evaluates
     subexpressions, then the matching rule fires (these micro-steps *are* the
     manual "lookup/add/leq" steps of a paper proof).
   - **Case-split** on the loop guard (`#Or` between the body-taken and exit
     branches) — or, for a recursive function, on the **base vs. recursive branch**
     (the `if`).
   - After the loop body's step (or the recursive **`call`** step), **invoke the
     circularity** on the shifted state / the recursive call (this is the coinductive
     appeal; it is legal because that genuine step already provided guardedness).
   - **Discharge the arithmetic VCs** by Consequence — Z3 for linear facts,
     `[simplification]` lemmas for the rest.

5. **Compose the function-level proof via Transitivity.** Chain the pieces:
   `def` files the function → `call` binds parameters in a fresh scope → body init
   → **loop via the circularity used as a lemma** (instantiated at its entry state,
   e.g. `{S := 0, I := 1}`, precondition discharged) → `return` pops the frame and
   delivers the value. The result is `A ⊢ φ_pre ⇒ φ_post`.

`/verify` then emits the artifacts and the exact `kompile`/`kprove` commands,
labeled **"constructed, not machine-checked"** (the MVP does not run the
toolchain), plus the test-redundancy and Findings reports.

---

## 5. Partial vs total correctness

Circularity gives **partial correctness**: *if and when the loop terminates*, the
postcondition holds. Guardedness yields coinductive **soundness without a
variant** — it never asserts the loop *halts*. There is no decreasing measure in
the proof, so termination is simply not established.

**Total correctness** additionally requires a **decreasing measure** (a
well-founded measure, e.g. `N − i`, bounded below (`≥ 0`) and strictly decreasing
each iteration) to rule out infinite looping. The kit's default is partial correctness; **flag total
correctness as a recommendation in the report and do not attempt it unless the
user asks.** When asked, the move is: add the variant to the loop claim and
discharge "strictly decreases, bounded below" alongside the existing VCs.

---

## 6. Discharging the verification conditions

The Consequence steps generate first-order **verification conditions (VCs)**. Two
tiers:

- **Linear facts → Z3.** Side conditions like `N ≥ 0 ⇒ 1 ≤ N+1`, `I ≤ N ⇒
  I+1 ≤ N+1`, and zero-factor simplifications are pure linear arithmetic; the SMT
  oracle handles them directly.
- **Nonlinear / division-by-even → `[simplification]` lemmas.** When a VC equates
  two distinct **symbolic products** under truncating `/Int` (which is *not* linear
  without an evenness justification), Z3 needs help. Supply `[simplification]`
  lemmas — e.g. **VC-EXACT**: a product of two consecutive integers is even, so
  every `/Int 2` here is *exact* and `(A − B)/2 = A/2 − B/2` on the even subgroup.
  The example's **VC1** (loop step: `I + cf(I+1,N) = cf(I,N)`) is exactly this
  case; **VC2** (exit, zero factor) and **VC3** (init, `cf(1,N) = N*(N+1)/2`) fall
  to Z3 once the map-extensionality `[simplification]` reduces the cell equality to
  a scalar one. See [`k-framework.md`](k-framework.md) for writing
  `[simplification]` rules and the map-extensionality lemma
  `M[K<-V] #Equals M[K<-V'] ⇒ V #Equals V'`.

> **Spec-difficulty is a bug signal.** If you *cannot* find a clean closed form, a
> clean precondition, or a clean side condition — or the VCs refuse to discharge —
> do not paper over it. Surface it: that difficulty is usually a real missing
> case, off-by-one, or undefined behavior, and naming it is itself a deliverable
> (benefit #2). A side condition you are *forced* to add (like `I ≤ N+1`, or a
> function precondition like `N ≥ 0`) is often a precondition the code silently
> assumed and never checked.

---

## 7. Limits & escalation

The recipe handles **simple counting loops** *and* **simple recursion** (one
accumulator/argument, integer/map state, a polynomial closed form) well — that is
its sweet spot. **Recursion control flow is now covered** — see
[`../examples/sum-recursive/`](../examples/sum-recursive/), where the circularity is on
the recursive call's contract `(REC)`. It starts to strain, and you should
**escalate**, when the code involves:

- **Non-polynomial / multiplicative VCs** — e.g. factorial's `N! / (I−1)!`. The VC
  tier in §6 discharges *polynomial* facts and division-by-even; an arbitrary
  multiplicative recurrence needs a recursively-defined symbol and its own
  `[simplification]` lemmas, which the recipe does not yet supply.
- **Recursive data structures** — lists, trees, heaps — which need separation /
  heap abstractions and inductively defined predicates (often `μ`, the least
  fixpoint from Matching μ-Logic).
- **Binders** (`λ`, quantifiers, local scoping captured semantically).
- **Concurrency / nondeterminism**, where `[all-path]` vs one-path reachability
  genuinely diverge and the determinism shortcut no longer applies.

**Escalation path (first-class).** When the recipe doesn't cover your case, go to
[`sources.md`](sources.md) — route **by topic** to the matching-logic papers:
reachability logic and the Circularity rule are **Roșu & Ștefănescu, *From Hoare
Logic to Matching Logic Reachability* (FM 2012)** and **Roșu, Ștefănescu,
Ciobâcă & Moore, *One-Path Reachability Logic* (LICS 2013)**; fixpoint/inductive
reasoning is the μ-logic line (LICS 2019, OOPSLA 2020); binders have their own
paper (ICFP 2020). `--refresh` re-fetches these live. And remember: the most
reliable way to extend the kit to a new shape of problem is **another worked
example** — the example library is the growth lever and will grow.

---

### Cross-references

- [`../examples/`](../examples/) — the worked instances: [`sum-up`](../examples/sum-up/)
  / [`sum-down`](../examples/sum-down/) (loop circularities, `I ≤ N+1` / `I ≥ 0`) and
  [`sum-recursive`](../examples/sum-recursive/) (the **recursion** circularity `(REC)`).
- [`matching-logic.md`](matching-logic.md) — the underlying logic and connectives.
- [`k-framework.md`](k-framework.md) — `claim` syntax, `kprove`, heating,
  `[simplification]`, `/Int`.
- [`sources.md`](sources.md) — papers (FM 2012, LICS 2013, …) and the `--refresh`
  escalation path.
