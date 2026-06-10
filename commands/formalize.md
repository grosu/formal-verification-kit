# `/formalize` — add formal specs and surface hidden bugs

**What it does, in one line:** reads your code and writes a formal *specification*
for it — a precondition/postcondition contract for each function and an invariant
for each loop — plus a plain-language **Findings report** that flags missing
preconditions, forgotten corner cases, and suspicious behavior. You do **not** need
K installed, and you do **not** need to know what formal verification is to get value:
the Findings report is useful on its own.

**Two benefits this delivers** (both land even if you never read a proof):

1. **Finds hidden, subtle bugs.** Writing a clean spec forces every input to be
   accounted for. Missing cases (empty / zero / negative / overflow / off-by-one),
   undefined behavior, and intent-contradicting code surface as concrete findings.
   *If a clean spec is hard or impossible to write, that itself is a bug signal* —
   and this command says so.
2. **Sets up fewer tests / faster CI.** The specs written here are what
   [`/verify`](verify.md) later proves; once proved, tests already covered by the
   spec become redundant and `/verify` recommends dropping them. `/formalize`
   produces the specs that make that possible.

**Output contract:** formal artifacts (`<mod>.k`, `<mod>-spec.k`, a human-readable
spec note) **plus** a Findings report. The Findings report is **non-blocking**: it
never stops you, never edits your code, and never deletes anything — it is advice.

**Scope / invocation.** Provider-neutral: any coding agent that has read this kit can
follow these steps. **No arguments → operate on the whole current program**, writing a
spec for *each* function and *each* loop in it. (Targeting a single function or block by
argument is a later feature.) Default is **partial correctness** (correct *if* it
terminates); termination is surfaced as a recommendation, not proved unless asked.

---

## The steps (ordered)

### 1. Learn

Read the bundled primers if you have not already internalized them this session — they
are offline, instant, and identical every run:

- [`knowledge/matching-logic.md`](../knowledge/matching-logic.md) — patterns-as-sets,
  the definedness ladder, `μ`, the proof system, and the `#And`/`#Or`/`#Equals`/`#Not`/`#Exists`
  connectives used below.
- [`knowledge/k-framework.md`](../knowledge/k-framework.md) — configuration cells, rules,
  `seqstrict`/heating, `claim`s, `kprove`, simplifications, the Lesson 1.22 pattern, and
  `/Int` (integer division, truncates toward zero; distinct from `divInt`, which floors toward negative infinity).
- [`knowledge/reachability-and-circularities.md`](../knowledge/reachability-and-circularities.md)
  — reachability logic, the **Circularity** rule, coinductive loop invariants, and the
  proof recipe.

These primers are a **fast path for common cases**, not a complete theory. When the
code uses something they don't cover — recursive data structures, binders/closures,
concurrency, the heap, exceptions — escalate **by topic** through
[`knowledge/sources.md`](../knowledge/sources.md), the first-class path back to the
papers and K docs. Running `/formalize --refresh` additionally re-fetches those live
sources before you start.

### 2. Read the target — intent **and** implementation

Enumerate **every function** and **every loop** in the target. For each, infer the
*intended* behavior from all available intent evidence, not from the code alone:

the original user prompt / problem statement, the conversation history that led to
the code, issue or task descriptions, requirements docs, `PROMPTS.md`, an
UltimatePowers transcript, names (functions, parameters, variables), docstrings,
comments, and tests.

Then read the generated/target code as the **implementation being formalized**:
its functions, control flow, loops/recursion, data structures, and language
constructs determine the semantics fragment, the reachability claims, and the
circularities you must write. The formal contract should capture the intended
behavior; the code is checked against that contract. Divergence between intent and
implementation is exactly what becomes a finding in step 7.

Do **not** blindly formalize "whatever the code happens to do" as if it were the
specification. That *as-built* reading is useful as a secondary reverse-engineering
note when intent is unavailable or ambiguous, but the default `/formalize` mode is
**intent-spec mode**: align NL intent ↔ code ↔ formal spec, and report mismatches
plainly.

> Worked example (imitate the **closest** in [`examples/`](../examples/) — the
> reference pair is [`sum-up`](../examples/02-sum-up/) / [`sum-down`](../examples/03-sum-down/)):
> `examples/02-sum-up/sum.py` is one function `sum_to_n(n)` with one
> `while` loop. The original prompt / docstring intent "Return the sum of the
> integers from 1 to n" + the loop `while i <= n: s += i; i += 1` ⇒ intended
> behavior `sum_to_n(n) = 1 + 2 + … + n` on its intended domain. The code's
> behavior on negative inputs then becomes a Finding (missing precondition
> `n >= 0`), not part of the intended spec silently accepted as correct.

### 3. Semantics — build a mini-X K fragment

Build a **minimal K semantics of just the language fragment the code uses** — the
"mini-X" approach (mini-Python, mini-TS, …). Imitate
[`examples/02-sum-up/mini-python.k`](../examples/02-sum-up/mini-python.k): a `*-SYNTAX` module for
the constructs that actually appear (and *nothing else*), and a semantics module with a
`configuration` of cells (e.g. `<k>`, `<store>`, `<funcs>`, `<stack>`) and one rewrite
`rule` per construct. Cover only what the code touches — `sum` needs integer
literals/names, `+`, `<=`, `=`, `+=`, `while`, `def`, `return`, and call; it introduces
**no `if`** (only because the program never uses one — `if` is straightforward to add
when a program needs it; it is in Lesson 1.22's full language). Do not invent K
features; check each against the manual / Lesson 1.22.

> **MVP stopgap.** The fragment is a deliberate placeholder. The long-term design is
> **full per-language K semantics** (a real Python-in-K, TS-in-K, …), so the *literal*
> program is verified against the *real* language. When those are wired in, this step
> goes away. Until then, keep the fragment small, faithful, and commented.

### 4. Specify each function — a reachability rule

For each function write its contract as a **reachability rule** `φ_pre ⇒ φ_post`
(read `⇒` as the reachability arrow "every execution from a `φ_pre` state reaches a
`φ_post` state" — see [`knowledge/reachability-and-circularities.md`](../knowledge/reachability-and-circularities.md)),
expressed as a K `claim` over the mini-X semantics. Imitate the `(SUM)` claim in
[`examples/02-sum-up/mini-python-spec.k`](../examples/02-sum-up/mini-python-spec.k): the
left-hand `<k>` defines the function and calls it on a symbolic argument; `requires`
states the **precondition**; the cells on the right state the **postcondition** (the
result binding it must reach). Use uppercase math variables (`S`, `I`, `N`) for logical
values and lowercase for program variables (`s`, `i`, `n`) so they never clash.

> For `sum`: precondition `N >=Int 0`; postcondition `result |-> N *Int (N +Int 1) /Int 2`.
> A `claim` carries `[all-path]` (or `[one-path]`); use `requires` for the precondition
> and the rewritten cell values for the postcondition, exactly as the template does.

### 5. Specify each loop or recursive function — a circularity

For each loop write a **loop-invariant claim** that is generalized over the
accumulator and counter (not pinned to their initial values), and include the
**soundness side condition** that bounds the counter through the loop. Imitate the
`(LOOP)` claim in the same spec file. K's reachability prover treats **every claim in
the module as a coinduction hypothesis (a circularity)**, so the loop claim discharges
*its own* loop — this is what replaces a classical loop invariant.

**For a recursive function instead of a loop:** write a **function-contract
circularity** — `f(args) ⇒ result`, generalized over the symbolic argument(s), with
the soundness precondition (e.g. `N >= 0`). K uses it as its own hypothesis to
discharge the recursive call; the base case is the non-recursive branch. See the
`(REC)` claim in [`../examples/06-sum-recursive/`](../examples/06-sum-recursive/).

> **Input-validation guards & exceptions (a common real-code pattern).** When code
> begins with guards like `isinstance(...)` / `assert` / `if n < 0: raise ...`, those
> guards are **no-ops on the verified domain** (they pass and fall through). Model the
> **reduced in-domain body** in mini-X — do *not* model `raise`/exceptions (an
> escalation case, out of the fragment) — and turn each guard into a **Finding**.
> Often it's a *positive* finding: the guard **enforces** the precondition the spec
> needs (`if n < 0: raise` enforces `requires N >= 0`). See
> [`../examples/06-sum-recursive/`](../examples/06-sum-recursive/) (its `isinstance` /
> `ValueError` guards become Findings 1–2).

> For `sum`'s loop: generalize over `s = S`, `i = I`, `n = N`; the invariant says
> running the loop adds the running sum `(I +Int N) *Int (N -Int I +Int 1) /Int 2`
> to `s` and leaves `i = N +Int 1`; the soundness side condition is
> `requires I <=Int N +Int 1`. (Equivalent closed forms:
> `(I+N)*(N-I+1)/2 = (N*(N+1) - (I-1)*I)/2`; at `I = 1` both equal `N*(N+1)/2`.)

### 6. Write the artifacts

Write three files **alongside the code** (do not bury them elsewhere):

- **`<mod>.k`** — the mini-X fragment semantics from step 3.
- **`<mod>-spec.k`** — the function and loop `claim`s from steps 4–5, plus any
  `[simplification]` rules the arithmetic needs (e.g. map extensionality, exact
  halving of an even product — see the template).
- **a human-readable spec note** — what each function/loop is specified to do, the
  precondition, the result, and the side conditions, in plain English for a developer
  who will never open the `.k` files.

### 7. Findings report (first-class, plain language)

This is a primary deliverable, not an afterthought. Write it for **any developer**, in
plain language, with each finding as a concrete **`input → observed vs expected`**.
Cover at least:

- **Missing preconditions / side conditions** — inputs the code silently assumes.
- **Forgotten corner cases** — empty, zero, negative, boundary, overflow, off-by-one.
- **Undefined or intent-contradicting behavior** — inputs where the result is
  meaningless or disagrees with the stated/inferred intent.
- **Non-universal postconditions** — claimed behavior that does not hold for *all*
  inputs in the domain.
- **Dead / unreachable code** — branches or statements that can never execute.

**Spec-difficulty = bug signal.** If you cannot write a *clean* spec — no clean
precondition exists, the postcondition needs awkward case splits, or a loop has no
clean invariant — **say so explicitly and explain what looks suspicious.** That
difficulty is usually a real code smell, and naming it is itself a finding. Do not
paper over it to force a tidy claim.

#### Worked example of a Findings report (the `sum` `n >= 0` discovery)

Formalizing `sum.py` surfaced a missing precondition that the docstring and code
never state:

> **Finding — missing precondition `n >= 0`.**
> input: `n = -3` → observed: returns `0` (the loop `while i <= n` with `i = 1` never
> runs, so `s` stays `0`); expected (per the closed form `n*(n+1)/2`): `(-3)*(-3+1)/2 = 3`.
> The function is only correct for `n >= 0`. For negative `n` it silently returns `0`,
> which is neither the sum `1 + … + n` (undefined for negative `n`) nor the closed-form
> value. **Recommendation:** document and/or enforce the precondition `n >= 0`; the
> formal contract `(SUM)` is stated with `requires N >=Int 0` to make this explicit.
> A related soundness obligation appears in the loop spec as the side condition
> `i <= n + 1`, which holds on every reachable iteration.

That one missing-precondition finding is the kind of value `/formalize` delivers even
to a user who never reads the proof: a real input (`n = -3`) where the function does
something other than what its name and docstring promise.

---

## Output contract (summary)

`/formalize` emits, alongside your code:

1. **Artifacts** — `<mod>.k` (mini-X semantics), `<mod>-spec.k` (function + loop
   claims), and a human-readable spec note.
2. **Findings report** — plain-language, `input → observed vs expected`, including any
   spec-difficulty signals. **Non-blocking.**

Then run [`/verify`](verify.md) to construct the proof of these specs, get the
**test-redundancy** recommendation (benefit #1), and emit the exact `kompile`/`kprove`
commands — labeled *constructed, not machine-checked* — to confirm it later.
