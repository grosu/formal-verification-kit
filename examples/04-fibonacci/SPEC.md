# Specification note — `fib.py`

## Public intent ledger (protocol refresh)

This section makes the example conform to the current `/formalize` protocol: the
claim provenance is explicit before the formal claims, and the original source program
remains unchanged. The program under audit is `fib.py`, preserved as the
exact Claude Code Opus 4.8 (`opus-4-8`) vibe-coded output from `PROMPTS.md`; FVK's
role in this example is to expose obligations and Findings before the repair iteration. In the full FVK loop, the coding agent uses this evidence to repair the code; this corpus preserves the pre-repair source so the issue remains visible.

- **I1 — prompt / public task statement**
  - Evidence: P1 in `PROMPTS.md`: "Write `fib(n)` returning the n-th Fibonacci number (fib(0)=0, fib(1)=1) with an iterative `while` loop and two running values. Self-contained — no `range`/builtins."
  - Obligation: `fib(n)` should return the nth Fibonacci number for `n >= 0`, with `fib(0)=0` and `fib(1)=1`.
  - Status: encoded in the function contract(s) and, where needed, the loop/recursion circularity.
- **I2 — implementation shape being audited**
  - Evidence: `fib.py`: The code uses coupled accumulators `prev` and `curr` and advances them in a `while i < n` loop.
  - Obligation: the mini-Python semantics and proof obligations model this control/data-flow shape.
  - Status: encoded in `mini-python.k` and `mini-python-spec.k`; the source program is intentionally not rewritten.
- **I3 — FVK finding / conflict signal**
  - Evidence: `FINDINGS.md`: For negative inputs the loop does not run and the implementation returns `0`, so FVK records the missing `n >= 0` precondition.
  - Obligation: keep the issue visible as next-iteration feedback instead of weakening the spec or silently fixing the code during the provenance refresh.
  - Status: reported in `FINDINGS.md` / `PROOF.md`; source repair is deferred to the next explicit FVK-guided coding iteration, while this example refresh preserves the original source.
- **I4 — proof-scope / escalation evidence**
  - Evidence: `PROOF.md` and `[ESCALATION BOUNDARY]` notes where present.
  - Obligation: The spec-only recursive symbol `fib` captures the mathematical sequence; its totality is an explicit escalation boundary.
  - Status: constructed, not machine-checked; escalation boundaries are stated honestly rather than trusted.


Plain-English companion to the formal artifacts, for a developer who will never
open the `.k` files. Produced by the formal-verification-kit `/formalize` step.

- **Program:** [`fib.py`](fib.py) — `fib(n)` returns the `n`-th Fibonacci number
  with an **iterative count-up loop** carrying two running values
  (`prev = 0; curr = 1; i = 0; while i < n: prev, curr = curr, prev + curr; i = i + 1; return prev`).
- **Artifacts:** [`mini-python.k`](mini-python.k) (the mini-X fragment semantics),
  [`mini-python-spec.k`](mini-python-spec.k) (the two K `claim`s plus the spec-only
  `fib` symbol).
- **Status:** specs **constructed, not machine-checked** (the MVP does not run
  `kompile`/`kprove`). The Findings (see [`FINDINGS.md`](FINDINGS.md)) hold today
  regardless of machine-checking.
- **Default scope:** **partial correctness** — the contract constrains terminating
  runs; termination itself is a recommendation (see Findings), not proved.

## The spec-only symbol `fib`

The quantity the program computes is defined by a **recurrence**, not a polynomial
closed form. So the spec introduces a **spec-only recursive symbol**
`fib(Int) [function]` — pure spec *vocabulary*, never a language construct (it does
not appear in `mini-python.k`, and the program never calls it):

> `fib(0) = 0`,  `fib(1) = 1`,  `fib(N) = fib(N-1) + fib(N-2)` for `N > 1`.

This is the same "spec-only abstraction function" idea used for relational
postconditions (e.g. `isSorted`, `bag`) in `knowledge/k-framework.md`, here applied
to name a recursively-defined *number*. The three defining equations above are the
**only** facts about `fib` the proof uses.

## What is specified

### Function contract — `(FIB)`

> **Precondition:** `n >= 0`.
> **Postcondition:** `fib(n) = fib(N)` (the n-th Fibonacci number).

For every non-negative `n`, the function returns `fib(n)`. Encoded as a reachability
claim: from a configuration that *defines* `fib` and *calls* it on a symbolic
`N >= 0`, execution terminates with `result |-> fib(N)`.

### Loop invariant — `(LOOP)` (the circularity)

> From any state with `prev = fib(I)`, `curr = fib(I+1)`, `i = I`, `n = N`, and the
> **soundness side condition `0 <= I <= N`**, running the loop reaches
> `prev = fib(N)`, `curr = fib(N+1)`, `i = N`.

This is a **coupled two-variable invariant**: the two running program values are
pinned to **consecutive Fibonacci numbers**. Generalized over the counter `I` (not
pinned to its entry value `0`), it is the loop's reachability claim; K's prover uses
it as its own coinduction hypothesis, so it **discharges its own loop** — replacing
a hand-written invariant. The pair `(fib(I), fib(I+1))` plays the role the classical
invariant used to.

**The inductive step is definitional.** One loop iteration does
`prev, curr = curr, prev + curr` (a *simultaneous* assignment — the whole RHS tuple
is evaluated before either target is bound), then `i = i + 1`. Under the invariant
that sends `(fib(I), fib(I+1))` to `(fib(I+1), fib(I) + fib(I+1))`. By `fib`'s **own
third defining equation** `fib(I+2) = fib(I) + fib(I+1)` (valid because `I+2 > 1`,
i.e. `I >= 0`), the new pair is exactly `(fib(I+1), fib((I+1)+1))` — the invariant at
`I+1`. So the step verification condition discharges by **unfolding `fib`'s
definition**: no nonlinear arithmetic, no division-by-even lemma (contrast `sum-up`,
whose step needed exact-halving). The `0 <= I` half of the side condition is exactly
what keeps that unfold legal.

## How the function proof composes (for `/verify`)

`def fib` files the body → `call` binds `n = N` in a fresh scope →
`prev = 0` (`= fib(0)`), `curr = 1` (`= fib(1)`), `i = 0` →
**apply `(LOOP)` at `I := 0`** (side condition `0 <= 0 <= N` follows from `N >= 0`)
→ `prev = fib(N)` → `return prev` delivers it → `result |-> fib(N)`.

## Arithmetic the proof will need

- **`fib`'s three defining `[simplification]` rules** — the only `fib` facts used;
  the inductive-step VC is `fib(I) + fib(I+1) = fib(I+2)`, an instance of the third
  rule.
- **Map extensionality** `{M[K<-V] #Equals M[K<-V']} => {V #Equals V'}` — to close
  the post-store implication that pins `result`.
- No exact-halving / nonlinear lemma is needed (the Fibonacci recurrence is additive,
  not multiplicative), so the arithmetic VC tier here is *lighter* than `sum-up`'s.

## Mini-X semantics scope (only what the code touches)

Integer literals/names, `+`, `<` (strict), assignment `x = e`, **simultaneous
assignment `x, y = e1, e2`**, `while`, `def`, `return`, call. **No `if`**, **no
`<=`**, **no `-`**, **no `+=`** (this program uses none of them). The one real
modeling decision is the simultaneous assignment, modeled value-faithfully (the
whole RHS tuple evaluates before either target is bound — see the note in
[`mini-python.k`](mini-python.k)).

`fib.py`'s `__main__` block is a self-test (asserts + a print); it is outside the
verified core (it only *checks* the function) and is not modeled.

## Escalation status

`fib`'s **totality / well-definedness** is the one open obligation: the symbol is
declared `[function, total]`, but the recipe's bundled tier does *not* machine-prove
that the recurrence terminates / is well-defined for every `N >= 0` (a `μ`-logic /
well-founded-recursion fact). It is marked an **`[ESCALATION BOUNDARY]`** in
[`PROOF.md`](PROOF.md) — **not** faked as `[trusted]` — and routed to the papers.
Everything else (the loop circularity, the function composition, the additive VC) is
within the fast-path recipe.

## Next step

Run the kit's **`/verify`** to construct the proof of these claims, emit the
`kompile`/`kprove` commands, and get the test-redundancy recommendation.
