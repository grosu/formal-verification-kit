# K Framework: writing a definition and a `kprove` claim

This is the **fast path** for the K mechanics that `/formalize` and `/verify` need:
how to write a small K semantics for a fragment of code (a "mini-X"), and how to write
a `claim` that `kprove` can discharge. It is distilled for the common case (an
imperative function over integers, maps, and lists). For anything outside that —
recursive/heap data structures, binders/closures, concurrency, a real per-language
semantics — treat this as a starting point and escalate via [`sources.md`](sources.md)
(see [LIMITS + ESCALATION](#limits--escalation)).

Concrete companion to read alongside this file: the worked sum example,
[`../examples/02-sum-up/mini-python.k`](../examples/02-sum-up/mini-python.k) (the semantics) and
[`../examples/02-sum-up/sum-up-spec.k`](../examples/02-sum-up/sum-up-spec.k) (the claims).
Everything below is grounded in those two files and in K Tutorial **Lesson 1.22**
(Tutorial 1, Lesson 22 — "Basics of Deductive Program Verification using K").

---

## 1. What K is

K is a framework for **rewrite-based executable semantics**. You write the syntax and
the operational rules of a language once; K turns that single definition into tools:

- **`kompile def.k --backend haskell`** — compiles the definition. For proofs use the
  **Haskell backend** (the symbolic/reachability backend). The LLVM backend is the fast
  concrete interpreter; the Haskell backend is the one that does verification.
- **`krun program`** — executes a concrete program under the semantics (a step-by-step
  rewriter). Useful to sanity-check the semantics before proving anything.
- **`kprove spec.k`** — proves reachability **claims** against the compiled semantics.
  It runs symbolic execution (rewriting with logical variables) and discharges the
  arithmetic/map side conditions by calling **Z3** for satisfiability/feasibility.
  Output **`#Top`** = all claims proved (the matching-logic "true"); anything else is a
  residual proof obligation it could not close.

A rule `LHS => RHS` is both an execution step and a logical statement; a `claim`
`LHS => RHS` is a *reachability* property "every (or some) execution from `LHS` reaches
`RHS`." That single overlap is why the same semantics both runs and verifies.

> MVP note: the kit **constructs** the definition, the claims, and the exact
> `kompile`/`kprove` commands, but does not run the toolchain — artifacts are labeled
> "constructed, not machine-checked." The mini-X fragment semantics is a deliberate
> stopgap; full per-language K semantics is the roadmap.

---

## 2. Shape of a K definition

A definition is a set of `module`s. The idiomatic split is a `*-SYNTAX` module (BNF) and
a same-named main module (configuration + rules).

### 2a. The `*-SYNTAX` module — BNF with attributes

```
module MINI-PYTHON-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  syntax IExp ::= Id | Int
                | "(" IExp ")"      [bracket]              // parsing only, no node
                > IExp "+" IExp     [seqstrict, left]      // > = lower precedence; left assoc
                | Id "(" IExps ")"  [strict(2)]

  syntax KResult ::= Int | Bool | Ints                     // the "fully evaluated" sorts
endmodule
```

Key attributes:

- **`strict` / `seqstrict`** — declare evaluation order; they generate the small-step
  stepping (Section 3). `strict(2)` = evaluate the 2nd argument (the arg list) before
  applying the rule.
- **`left`** — associativity, to disambiguate parsing of `a + b + c`.
- **`bracket`** — `( )` is grouping only; it produces no AST node.
- **`token`** — makes a literal lex as a terminal of a sort (e.g.
  `syntax Id ::= "$a" [token]` so `$a` is usable as a program variable). In the sum
  example this is **not** needed: program vars are lowercase `Id`s, which never collide
  with K's uppercase/`?`-prefixed logical variables.
- **`syntax KResult ::= ...`** — declares which sorts count as *values*. This is what
  strictness checks against (`isKResult`); get it wrong and evaluation never stops
  heating or stops too early. In the sum example: `syntax KResult ::= Int | Bool | Ints`.

### 2b. The main module — configuration + rules

```
module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports INT     // +Int, -Int, *Int, <=Int, /Int, modInt, ...
  imports BOOL    // andBool, orBool, notBool, ...
  imports MAP     // M[K <- V] update,  K |-> V binding,  .Map empty
  imports LIST    // ListItem(_),  .List empty

  configuration
    <k> $PGM:Stmt </k>        // the computation: a ~>-separated list of work
    <store> .Map  </store>    // program variables   Id |-> Int
    <funcs> .Map  </funcs>    // function table       Id |-> (def ...)
    <stack> .List </stack>    // call stack of saved (continuation, store)

  rule <k> I1:Int + I2:Int => I1 +Int I2 ... </k>          // builtin INT
  rule <k> X:Id => V ... </k>  <store> ... X |-> V ... </store>
endmodule
```

- The **configuration** is a tuple of named **cells**. `<k>` is special: it holds the
  *computation* as a `~>`-separated list, where **`~>` is the cons of the computation
  list** ("do this, then that") and **`.K` is the empty computation**.
- A **rule** rewrites with `=>`. `...` inside a cell means "the rest of this cell is
  unchanged/irrelevant" — `<k> X => V ... </k>` rewrites only the head of `<k>`;
  `<store> ... X |-> V ... </store>` matches `X` anywhere in the map.
- **`requires`** adds a side condition (a `Bool`) that must hold for the rule to fire,
  e.g. `rule <k> I1 / I2 => I1 /Int I2 ... </k> requires I2 =/=Int 0`.
- Builtins you will lean on: **`+Int`, `<=Int`, `/Int`** (integer division that
  **truncates toward zero**; use `divInt` if you need floor), `modInt`; map
  **`M[K <- V]`** (update) and **`K |-> V`** (a single binding); `LIST` with
  `ListItem(_)` and `.List`.

---

## 3. Strictness ⇒ heating / cooling (the small-step engine)

You do not hand-write the stepping for `a + b`. `seqstrict` on `IExp "+" IExp`
**auto-generates** heating `[heat]` and cooling `[cool]` rules that pull a subexpression
out to the front of `<k>`, evaluate it, then plug the value back:

```
rule <k> HOLE +  E2:IExp => HOLE ~>  [] + E2 ... </k> requires notBool isKResult(HOLE) [heat]
rule <k> E1:IExp  + HOLE => HOLE ~> E1 +  [] ... </k> requires isKResult(E1)            [heat]   // seqstrict: left first
rule <k> HOLE ~>  [] + E2:IExp => HOLE +  E2 ... </k>                                   [cool]
rule <k> HOLE ~> E1:IExp +  [] => E1  + HOLE ... </k>                                   [cool]
```

(The sort-annotated siblings `E2:IExp` / `E1:IExp` mirror the form K's strictness
machinery actually generates; these are illustrative, simplified versions of the
compiler-generated `[heat]`/`[cool]` rules.)

The `HOLE` is the term being evaluated; the compiler attaches the
**`isKResult(HOLE)` / `notBool isKResult(HOLE)`** side conditions. `seqstrict`
sequences the arguments (left, then right) by gating the second heat on the first being
a `KResult`; plain `strict` leaves the order nondeterministic. This heating/cooling is
exactly the small-step semantics: a deeply nested expression is reduced one operator at
a time, always at the head of `<k>`. You only write the "value level" rules
(`I1:Int + I2:Int => I1 +Int I2`); strictness supplies the rest.

> Gotcha (from the sum build): the `while` loop must keep an **unevaluated** copy of the
> guard frozen (here inside `#whileLoop(B, S)`) and evaluate a **fresh** copy at the head
> of `<k>`. Heating rewrites only the head, so the frozen copy survives to be re-checked
> next iteration. See the `while`/`#whileLoop` rules in `mini-python.k`.

---

## 4. Claims: the spec module

A spec file `requires` the semantics and defines a `VERIFICATION` module that imports the
semantics plus the symbolic helpers, then a spec module holding the `claim`s.

```
requires "mini-python.k"

module MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON-SYNTAX        // (+ any [token] declarations for program vars)
endmodule

module VERIFICATION
  imports MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON
  imports MAP-SYMBOLIC             // symbolic reasoning over maps (extensionality etc.)
  imports K-EQUAL                  // #Equals and friends
  // ... simplification lemmas go here (Section 6) ...
endmodule

module MINI-PYTHON-SPEC
  imports VERIFICATION
  // ... claims go here ...
endmodule
```

A **claim** has the same shape as a configuration, but cells carry `=>` rewrites and
logical (symbolic) variables:

```
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

Reading it:

- **`<k> LHS => RHS ...`** — start from `LHS`; the claim asserts the program runs to
  `RHS` (`=> .K` means "and terminates", consuming the work).
- **store rewrites `x |-> (OLD => NEW)`** — the variable `x` starts as `OLD` and ends as
  `NEW`. Untouched bindings (`n |-> N`) just constrain the input.
- **`requires`** — the **precondition** (assumptions on the symbolic inputs), e.g. the
  loop side condition `I <=Int N +Int 1`, or the function precondition `N >=Int 0`.
- **`ensures`** — the **postcondition**: extra constraints that must hold *after*
  execution. Use **`?`-prefixed existentials** for "some value exists": write `?C:Int` in
  the configuration and `ensures (?C ==Int A) orBool (?C ==Int B)` (Lesson 1.22 §3.3).
  `<funcs> .Map => ?_:Map` is the idiom for "ends in some unconstrained map."
- **`[all-path]` vs `[one-path]`** — the claim type. `[all-path]`: **every** execution
  path from `LHS` reaches `RHS` (the strong, total-correctness-style claim — what the sum
  proof uses). `[one-path]`: **some** path does. You can also set a module default or
  pass `--default-claim-type`.

---

## 5. Circularities (loops and recursion)

K's reachability prover treats **every claim in the module as a coinduction hypothesis**
(a *circularity*). This is what lets a loop claim **discharge its own loop**: when proving
the loop-invariant claim, after one iteration the proof reaches a state that matches the
same claim, and the coinduction hypothesis closes it. So you state the loop invariant *as
a claim* and it proves itself; other claims (e.g. the function contract) may **reuse that
loop claim as a lemma/circularity**.

Two attributes you may need:

- **`[trusted]`** — assume a claim as already proven (it is added to the list of proven
  circularities without proof). Use sparingly, to stage a proof or to admit an axiom.
- **`[simplification]`** rules — **user lemmas** that the prover applies anywhere their
  LHS matches (they do *not* complete to the top of the configuration). These are how you
  feed K the arithmetic / map facts it needs to discharge a side condition. They are the
  **verification-condition oracle**: a `[simplification]` rule fires only when the current
  side condition *implies* its `requires`, so they are sound to add as needed (you own
  their soundness — they must preserve definedness; see manual §`simplification`).

---

## 6. The Lesson 1.22 pattern (cite)

Lesson 1.22 verifies *this exact* sum function and is the template the mini-Python example
follows. Its ingredients:

- **Configuration** `<k> / <store> / <funcs> / <stack>`: computation, variable store,
  function table, and a call stack of saved `state(continuation, store)` frames.
- **Statements**: assignment `x = e`, `if`, `while`, function `def`, `return`, and `call`.
  (The mini-Python fragment drops `if` entirely — it is not needed for `sum` — and adds
  augmented assignment `x += e`, desugared to `x = x + e`.)
- **Two claims**, both `[all-path]`:
  1. a **loop-invariant claim** over the `while` body (the circularity that proves
     itself), and
  2. a **function claim** (the contract: `def sum` then `result = sum_to_n(N)` stores
     `N*(N+1)/2`), which reuses the loop claim.
  Run `kprove`; success is **`#Top`**.
- **The Bot / Bots shared-`klabel` list trick.** Evaluated arguments (`Int`s, which are
  `KResult`s), parameters (`Id`s), and source expressions (`IExp`s) must all be lists with
  a *shared* spine so the seqstrict argument list can **cool to an `Ints` `KResult`**:

  ```
  syntax Bot
  syntax Bots  ::= List{Bot,  ","} [klabel(exps)]
  syntax Ints  ::= List{Int,  ","} [klabel(exps)] | Bots   // evaluated args, a KResult
  syntax Ids   ::= List{Id,   ","} [klabel(exps)] | Bots   // parameters
  syntax IExps ::= List{IExp, ","} [klabel(exps), seqstrict] | Ints | Ids
  ```

  The shared `[klabel(exps)]` makes `Ints` and `Ids` both subsorts of the strict `IExps`,
  so an evaluated `IS:Ints` is a legal call argument and `.Bots` is the single empty
  terminator usable as both `.Ids` and `.Ints`.

The sum spec needs two `[simplification]` lemmas beyond Lesson 1.22's down-counting loop
(which needed none), because the **up-counting** invariant divides a *symbolic* product
and the inductive step equates two distinct products under truncating integer `/Int`:

```
// map extensionality: closes the post-store implication (result <- V)
rule { M:Map [ K <- V ] #Equals M:Map [ K <- V' ] } => { V #Equals V' } [simplification]

// exact halving of an always-even product of consecutive integers
rule (X:Int *Int (X +Int 1)) /Int 2 *Int 2 => X *Int (X +Int 1) [simplification]
rule ((A:Int +Int B:Int) *Int C:Int) /Int 2 *Int 2 => (A +Int B) *Int C
  requires ((A +Int B) *Int C) modInt 2 ==Int 0 [simplification]
```

---

## 7. Common gotchas (the kind `/formalize` must avoid)

These bit the sum build; surfacing them early is part of the "difficulty writing a clean
spec is itself a bug signal" discipline.

- **List-sort / `KResult` subsorting.** Evaluated argument lists must subsort into a
  `KResult` (the Bot/Bots `[klabel(exps)]` trick, Section 6). Skip it and the seqstrict
  arg list never cools — the call rule can't fire and `kprove` stalls before it even
  reaches the interesting goal.
- **Statement-sequencing parse ambiguity vs. suite priority.** `Stmt Stmt [left]`
  (sequencing) must bind **looser** than suite-headed/leaf statements, and a `Suite`
  (`INDENT Stmt DEDENT`) must be self-delimiting, or the parser cannot tell where a
  `while`/`def` body ends. In mini-Python this is enforced with the `>` precedence block
  putting sequencing last.
- **Map extensionality `[simplification]`.** Post-conditions that pin a result land in the
  store as `STORE [ result <- V ]`; closing the implication needs the extensionality lemma
  `{ M[K<-V] #Equals M[K<-V'] } => { V #Equals V' }`. Without it the `ensures`/store goal
  stays open (Lesson 1.22 §3.3).
- **Exact-halving `[simplification]` when dividing a symbolic product.** `/Int` truncates,
  so Z3 will not on its own equate `(P /Int 2) *Int 2` with `P` for a symbolic product `P`
  — you must supply the "this product is even, so halving is exact" lemma (guarded by a
  `modInt 2 ==Int 0` `requires`).

---

## Lists / arrays & spec-only abstraction functions

To model a Python **list/array**, use K's builtin `List` (a *value* sort): `size(L)`,
element read `L[I]`, functional update `L[I <- V]`, `ListItem(_)` / `.List`. Because
`List` is a value (not a heap reference), Python's copy semantics and **non-aliasing**
fall out for free — `list(L)` is identity, and an index-assign rebinds the variable to a
new `List`. (Generalize the call machinery's evaluated-args list from `Int` to `KResult`
so a `List` value can be passed.)

When a postcondition is **relational** (e.g. *sorted*, *permutation*) rather than an
arithmetic closed form, declare **spec-only abstraction functions** `[function]` in the
`VERIFICATION` module and use them in `ensures` — e.g. `isSorted(List)` (an inductive
`Bool` function) and a multiset `bag(List)` (a value→count `Map`, so `bag(X) ==K bag(Y)`
*is* "X is a permutation of Y"). These are **spec vocabulary, not language constructs**.
**Caveat:** the bundled `[simplification]` tier does *not* discharge inductive-predicate
or multiset VCs — state those as `[ESCALATION BOUNDARY]` obligations and route to the
papers; do **not** fake them as `[trusted]`. Worked example:
[`../examples/12-insertion-sort/`](../examples/12-insertion-sort/).

## LIMITS + ESCALATION

This file is the **fast path**: an imperative function over ints/maps/lists, with a
loop-invariant claim and a function contract, in the Lesson 1.22 style. It is enough for
the common case and for the bundled sum example — but it is deliberately narrow.

You will need more than this primer for, among others:

- **recursive / heap-allocated data structures** (lists, trees, separation-style heaps),
- **binders, closures, scope** (anything where variable capture matters),
- **concurrency / nondeterminism**, exceptions, I/O,
- a **real per-language semantics** instead of a mini-X fragment (the roadmap; mature K
  semantics for C, Java, JavaScript, EVM, etc. exist in the K ecosystem).

When the recipe here does not cover your case, **escalate via
[`sources.md`](sources.md)** — the first-class path to the K manual, the K tutorial
(Lesson 1.22 and neighbors), and matching-logic references — and re-derive from there
(an optional `--refresh` pulls current upstream docs). Do not invent K features to force
a fit; if you cannot write a clean definition or claim with the constructs above, say so
and route to the deeper sources. Worked examples are the growth lever: prefer extending
the example library over stretching this primer.
