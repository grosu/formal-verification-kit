# `/verify` — construct the correctness proof and emit the artifacts

`/verify` takes the formal specs produced by [`formalize.md`](formalize.md) and
**constructs a correctness proof** of them — symbolic execution against the K
semantics, the loop circularity discharged by coinduction, and the arithmetic
verification conditions checked — then writes out the proof, the `.k` files, and
the exact `kompile`/`kprove` commands so a human can machine-check it later.

Just as importantly, `/verify` is a **feedback generator** for the next code
iteration. Any proof obstacle — a side condition, a failed VC, a non-universal
postcondition, a termination gap, or an escalation boundary — must be accumulated
as a proof-derived Finding and translated into actionable guidance for the next
prompt / code-generation pass.

It is agent-agnostic: any coding agent honors `/verify` after reading the kit.
With no arguments it operates on the whole current program / each function in it.

**Two benefits it delivers — even to a user who never reads the proof:**

1. **Fewer tests, faster CI.** A verified function is proven correct for *all*
   inputs in its specified domain, so unit tests that merely re-check in-domain
   input/output points become redundant. `/verify` reports exactly which tests
   are subsumed and the CI time saved — **as a recommendation, never an auto-delete**
   (see the Honesty gate).
2. **Finds hidden, subtle bugs.** If constructing the proof **fails or gets
   stuck** — a VC won't discharge, a side condition has to be invented, a
   postcondition doesn't hold universally — that is a *strong bug signal*. It is
   surfaced in plain language and fed to the Findings report, valuable even to a
   user who doesn't know what formal verification is. The point is not to stop at
   "proof failed"; the point is to say what the next code generator or
   UltimatePowers-style intent pass should ask, change, or test.

> **MVP scope.** `/verify` **constructs** the proof and emits the artifacts and
> the run-commands; it **does NOT run `kompile`/`kprove`** in this version. Every
> result is labeled **"constructed, not machine-checked."** Running the toolchain
> (which also enables *confident* test removal) is on the roadmap.

> **Read first if not already internalized:** the knowledge primers, especially
> [`../knowledge/reachability-and-circularities.md`](../knowledge/reachability-and-circularities.md)
> (the proof technique + the numbered recipe `/verify` follows),
> [`../knowledge/k-framework.md`](../knowledge/k-framework.md) (claims, `kprove`,
> `seqstrict`/heating, `[simplification]`, `/Int`), and
> [`../knowledge/matching-logic.md`](../knowledge/matching-logic.md) (the
> connectives), plus [`../knowledge/intent-evidence.md`](../knowledge/intent-evidence.md)
> (public intent ledger and spec provenance). The fully worked target shapes are in
> [`../examples/`](../examples/) — pick the **closest by shape** (the reference pair
> is [`sum-up`](../examples/02-sum-up/PROOF.md) / [`sum-down`](../examples/03-sum-down/PROOF.md)).
> These distilled primers
> are a **fast path for the common case** (imperative functions, simple counting
> loops); for recursion, recursive data structures, binders, or concurrency they
> are a starting point only — escalate by topic via
> [`../knowledge/sources.md`](../knowledge/sources.md) (optionally `--refresh`).

---

## The workflow — ordered steps

### Step 1 — Ensure the specs exist

`/verify` proves what `/formalize` wrote. If the spec artifacts are missing —
the fragment semantics `<mod>.k`, the claims `<mod>-spec.k` (the function
contract + each loop circularity), and the spec note — **run
[`/formalize`](formalize.md) first**, then continue. Do not invent specs here;
`/verify`'s job is to *prove* a stated contract, not to choose it.

If, after `/formalize`, there is still no `<mod>.k` or no `<mod>-spec.k` with real
K `claim` blocks, stop: the FVK run is **invalid/unresolved**. A Markdown-only
proof discussion is not `/verify` and must not be presented as FVK success.

Confirm each function has a reachability-rule `claim` (`φ_pre ⇒ φ_post`, with the
`requires` precondition) and each loop has its circularity `claim` (generalized
over accumulator/counter, with the soundness side condition). The worked pair is
[`../examples/02-sum-up/mini-python-spec.k`](../examples/02-sum-up/mini-python-spec.k):
`(SUM)` (function contract, `requires N >=Int 0`, result `N*(N+1)/2`) and
`(LOOP)` (loop circularity, side condition `I <=Int N +Int 1`).

Also confirm that `SPEC.md` contains a public intent ledger and that nontrivial
claims/circularities in `<mod>-spec.k` include provenance comments. If provenance is
missing, incomplete, or contradicted by the proof, record that as a proof-derived
Finding and ask for `/formalize` to be repaired before relying on the proof.

### Step 2 — Construct the proof

Build the proof by **symbolic execution against the K semantics**, faithful to
the actual rewrite rules of `<mod>.k` (the recipe in
[`../knowledge/reachability-and-circularities.md`](../knowledge/reachability-and-circularities.md) §4).
Three moving parts:

- **Symbolic execution.** Drive the `<k>` cell with the semantic rules. `seqstrict`
  **heating/cooling** evaluates sub-expressions left-to-right (these micro-steps
  *are* the manual `(lookup)`/`(add)`/`(leq)` steps of a paper proof); then the
  matching rule fires. Chain steps by **Transitivity**; carry untouched cells /
  bindings / the side constraint by **framing** (K's automatic `...`
  cell-completion).

- **Circularity discharge (the loop — or the recursive call).** Prove each loop's
  (or recursive function's) circularity claim by
  **guarded coinduction**: K adds every `claim` in the module to its hypotheses,
  so the claim **may assume itself** — but only **after ≥ 1 genuine `=>⁺`
  step** (evaluating the guard — or, for recursion, the `call` step — is that step;
  this is *guardedness*). Then
  **case-split on the guard** (`#Or`): in the body-taken branch run the body and
  **invoke the circularity on the shifted state** (e.g. `{S := S+I, I := I+1}`,
  its precondition re-checked); in the exit branch the counter is pinned (e.g.
  `I = N+1`) and the closed form collapses (empty sum `0`). Both branches must
  land on the claimed post-state. *(For a recursive function it is the same move:
  the genuine step is the `call`, the case-split is base vs. recursive branch, and
  you invoke the contract on the recursive call — see
  [`../examples/06-sum-recursive/`](../examples/06-sum-recursive/).)* The closed-form expression in the postcondition
  (e.g. the running sum `(I+N)*(N−I+1)/2`) plays the role the classical loop
  invariant used to.

- **Arithmetic VCs.** The **Consequence** steps generate first-order
  verification conditions. Discharge **linear facts with Z3** (side conditions
  like `N ≥ 0 ⇒ 1 ≤ N+1`, `I ≤ N ⇒ I+1 ≤ N+1`, zero-factor exits); for VCs that
  equate two **symbolic products** under truncating `/Int`, supply
  `[simplification]` lemmas (e.g. **VC-EXACT**: a product of two consecutive
  integers is even, so each `/Int 2` is exact and `(A−B)/2 = A/2 − B/2` on the
  even subgroup), plus the map-extensionality `[simplification]` lemma
  `{M[K<-V] #Equals M[K<-V']} => {V #Equals V'}` (the definedness-braced form
  defined verbatim in [`../knowledge/k-framework.md`](../knowledge/k-framework.md) §6)
  to reduce a cell `#Equals` to a scalar one.

- **Compose the function proof** by Transitivity: `def` files the function →
  `call` binds parameters in a fresh scope → body init → **the loop via its
  circularity used as a lemma** (instantiated at its entry state, precondition
  discharged) → `return` pops the frame and delivers the value. Result:
  `A ⊢ φ_pre ⇒ φ_post`.

Default scope is **partial correctness** (if/when the loop terminates, the
postcondition holds). **Termination is a recommendation, not proved** unless the
user asks; when asked, add a decreasing measure (e.g. `N − i`, bounded below by
`0` and strictly decreasing per iteration) to the loop claim and discharge it
alongside the VCs.

> **If construction fails or gets stuck — that is a finding, not a dead end.**
> A VC that won't discharge, a side condition you are *forced* to invent, a
> postcondition that doesn't hold for all in-domain inputs, a loop with no clean
> closed form — surface each one (Step 5). Difficulty proving a clean contract is
> itself a strong bug signal (benefit 2).
>
> But distinguish *correctness* gaps from **capability** gaps. When a VC is beyond
> the bundled tier (an inductive-predicate or multiset fact — e.g. sortedness /
> permutation), that is **not** a code bug: state it as an explicit `[ESCALATION
> BOUNDARY]` obligation, discharge everything the bundled tier *can*, and route the
> rest to the papers — **never admit it as `[trusted]`** (that fakes confidence the
> kit does not have). See [`../examples/12-insertion-sort/`](../examples/12-insertion-sort/).

### Step 3 — Accumulate proof-derived findings for the next generation

Treat `/verify` as a critic for the whole generate→formalize→verify loop, not just
as a proof writer. After constructing the proof (or after getting stuck), append or
update `FINDINGS.md` with a dedicated **Proof-derived findings from `/verify`**
section, and summarize the same points in `PROOF.md`.

For every proof obstacle or proof-discovered fact, write an actionable entry:

- **Evidence** — the exact claim, branch, VC, circularity side condition, or proof
  step where the issue appeared, plus the public intent-ledger entry it supports or
  contradicts.
- **Classification** — one of: code bug, missing precondition, underspecified
  intent, needed code guard, termination/performance gap, test gap, or proof
  capability gap / `[ESCALATION BOUNDARY]`.
- **UltimatePowers question** — the next question the intent-elicitation layer
  should ask the user (for example: "Should negative `n` raise, return `0`, or be
  outside the domain?" / "For duplicates, do you want any match or the leftmost
  match?").
- **Recommended next code/spec change** — the concrete guard, contract change,
  algorithm change, or spec refinement to feed back into the code generator.
- **Tests** — tests to add, keep, or conditionally remove after machine-checking.

Stop with the accumulated findings and feedback. Do **not** silently regenerate or
patch the code during `/verify` unless the user explicitly asks for a repair pass;
the default output is the evidence package that a conventional code generator can
use to produce a better next iteration.

Examples:

- `sum_to_n`: proof needs `N >= 0` ⇒ missing precondition / needed guard;
  UltimatePowers question: reject negatives, return `0`, or define a signed sum?
- `binary_search`: proof needs sorted, totally ordered inputs and only proves
  "some matching index" ⇒ clarify sortedness, NaN/mixed-type policy, and duplicate
  semantics.
- `insertion_sort`: sortedness/permutation VCs hit list/multiset induction ⇒ mark
  `[ESCALATION BOUNDARY]` and keep tests until the inductive theory and `kprove`
  close the obligations.

### Step 4 — Test-redundancy report (benefit 1)

Map the project's existing tests onto the verified spec and classify each:

- **Flag as redundant** any test whose assertion is **entailed by what was proved,
  *within the verified domain***. Once the function contract is machine-checked it
  holds for *every* input in its domain, so a unit test asserting a single
  in-domain input/output point is subsumed. For each, show the one-line reason
  (`sum_to_n(5) == 15` → `5*6/2 = 15`, `5 ≥ 0` → subsumed) and recommend removal
  (**conditioned on machine-checking** — see the Honesty gate), with an estimate
  of **CI time saved**.

- **Keep** — explicitly — every test the proof does *not* cover:
  - **Out-of-domain** inputs (e.g. `n < 0` when the precondition is `n ≥ 0`) —
    these pin behavior outside the verified contract and are often exactly where a
    Findings bug lives.
  - **Termination / performance** tests (partial correctness says nothing about
    halting or speed).
  - **Integration / end-to-end** tests (the proof covers the unit, not the wiring).

- **Recommendation-only. NEVER auto-delete.** This step proposes removals and
  explains them; it does not touch the test files. (An opt-in `--apply` is a
  later option.)

The worked instance is the test-redundancy snippet in
[`../examples/02-sum-up/PROOF.md`](../examples/02-sum-up/PROOF.md) §6 — `sum_to_n(5)==15`,
`sum_to_n(1)==1`, `sum_to_n(0)==0` flagged redundant; the out-of-domain `sum_to_n(-1)==0`
boundary test **kept**. Imitate that shape.

### Step 5 — Emit artifacts

Write out, alongside the code, everything needed to machine-check the proof later:

- the **proof write-up** (condensed, in the shape of
  [`../examples/02-sum-up/PROOF.md`](../examples/02-sum-up/PROOF.md): function claim, loop
  circularity, short English proof, machine-detailed sketch, and the two
  plain-language benefit payoffs);
- the **updated Findings report** — including the proof-derived entries from Step 3,
  so the evidence package can be passed to the next code-generation pass;
- the **`.k` files** — the fragment semantics `<mod>.k` and the claims
  `<mod>-spec.k`;
- the **exact run-commands**:

  ```sh
  kompile <mod>.k --backend haskell        # compile the fragment semantics (Haskell backend, required to prove)
  kast    --backend haskell <mod>-spec.k   # (optional) confirm the claim program parses to one AST
  kprove  <mod>-spec.k                      # discharge the claims; expected: #Top  (all proved)
  ```

**Label everything "constructed, not machine-checked."** The MVP does not run the
toolchain; a `#Top` from `kprove` is what would upgrade the result from
*constructed* to *machine-verified*.

### Step 6 — Report

Produce the human-readable report:

- **What's proved** — the function contract(s) and loop circularity(ies), in plain
  language (e.g. "for every `n ≥ 0`, `sum_to_n(n) = n*(n+1)/2`, if and when it
  terminates").
- **Residual risk** — **partial vs total correctness** (termination not proved
  unless asked); the **trusted base** (adequacy of the mini-X fragment semantics;
  the reachability proof-system metatheory and `kprove`; the SMT/`[simplification]`
  oracle); and the **"constructed, not machine-checked"** caveat with the
  run-commands.
- **The test-redundancy recommendation** from Step 3 (with the conditioning below).
- **The Findings entries** — and if verification **failed or got stuck**, surface
  that **prominently as a strong bug signal**, feeding it into the Findings report
  (benefit 2). A side condition you were forced to add (like `I ≤ N+1`, or a
  precondition like `N ≥ 0`) is usually a precondition the code silently assumed
  and never checked; report it with a concrete `input → observed vs expected`
  example, the way [`../examples/02-sum-up/PROOF.md`](../examples/02-sum-up/PROOF.md) §5 does
  for the `n < 0` case.

---

## Honesty gate (must be explicit)

The MVP **constructs** the proof but **does NOT run `kprove`**. Therefore:

- **Test removal is a recommendation *conditioned on machine-checking*.** Advise
  the user to **run the emitted `kompile`/`kprove` commands first**, or to **keep
  the tests until** the claims actually discharge (`kprove` returns `#Top`). Only
  then are the test-redundancy deletions safe.
- **Never auto-delete tests**, and **never claim confidence the un-machine-checked
  proof does not yet have.** Say plainly that the proof is "constructed, not
  machine-checked."
- **The Findings report (benefit 2) does *not* depend on machine-checking** — a
  missing precondition, an off-by-one, a failed VC, undefined behavior is a real
  finding today, independent of whether `kprove` has been run. Report those with
  full confidence; gate only the *proof-derived test removals* on the machine
  check.

See the worked conditioning in
[`../examples/02-sum-up/PROOF.md`](../examples/02-sum-up/PROOF.md) §6 ("Conditioned on
machine-checking") and its "Reproduce the machine check" section.

---

## Limits & escalation

The recipe `/verify` follows is a **fast path for the common case** — imperative
functions with simple counting `while`/`for` loops over integers and maps. For
**recursion** (the circularity is on the recursive call's contract), **recursive
data structures** (lists/trees/heaps, needing separation/heap abstractions and
inductive `μ` predicates), **binders**, or **concurrency / genuine
nondeterminism** (where `[all-path]` vs one-path actually diverge), treat it as a
starting point and **escalate by topic** via
[`../knowledge/sources.md`](../knowledge/sources.md) (optionally with
`--refresh`, the first-class escalation path). The most reliable way to extend the
kit to a new shape of problem is **another worked example** — the example library
is the growth lever and will grow.

---

### Cross-references

- [`formalize.md`](formalize.md) — produces the specs `/verify` proves; run it first.
- [`../knowledge/reachability-and-circularities.md`](../knowledge/reachability-and-circularities.md)
  — the proof system, the Circularity rule, and the numbered recipe.
- [`../knowledge/k-framework.md`](../knowledge/k-framework.md) — `claim` syntax,
  `kprove`, `seqstrict`/heating, `[simplification]`, `/Int`.
- [`../knowledge/matching-logic.md`](../knowledge/matching-logic.md) — the
  underlying logic and the `#And`/`#Or`/`#Equals`/`#Not`/`#Exists` connectives.
- [`../examples/02-sum-up/PROOF.md`](../examples/02-sum-up/PROOF.md) — the worked target: proof
  shape, Findings (benefit 2), and the test-redundancy snippet (benefit 1).
- [`../knowledge/sources.md`](../knowledge/sources.md) — papers and the `--refresh`
  escalation path.
