# Specification note — `average.py`

## Public intent ledger (protocol refresh)

This section makes the example conform to the current `/formalize` protocol: the
claim provenance is explicit before the formal claims, and the original source program
remains unchanged. The program under audit is `average.py`, preserved as the
exact Claude Code Opus 4.8 (`opus-4-8`) vibe-coded output from `PROMPTS.md`; FVK's
role in this example is to expose obligations and Findings before the repair iteration. In the full FVK loop, the coding agent uses this evidence to repair the code; this corpus preserves the pre-repair source so the issue remains visible.

- **I1 — prompt / public task statement**
  - Evidence: P1 in `PROMPTS.md`: "Write `average(nums)` returning the arithmetic mean of a non-empty list of numbers. Self-contained: sum with your own `while` loop and divide by `len` — no `sum()` or other builtins."
  - Obligation: `average(nums)` should compute the arithmetic mean on the intended non-empty numeric-list domain; the loop should sum all elements and divide by the length.
  - Status: encoded in the function contract(s) and, where needed, the loop/recursion circularity.
- **I2 — implementation shape being audited**
  - Evidence: `average.py`: The code initializes `total = 0`, iterates `while i < len(nums)`, accumulates `total += nums[i]`, and returns `total / len(nums)`.
  - Obligation: the mini-Python semantics and proof obligations model this control/data-flow shape.
  - Status: encoded in `mini-python.k` and `average-spec.k`; the source program is intentionally not rewritten.
- **I3 — FVK finding / conflict signal**
  - Evidence: `FINDINGS.md`: `average([])` raises `ZeroDivisionError`; the K model uses `/Int` while Python `/` is true division, so the float/int gap is reported rather than hidden.
  - Obligation: keep the issue visible as next-iteration feedback instead of weakening the spec or silently fixing the code during the provenance refresh.
  - Status: reported in `FINDINGS.md` / `PROOF.md`; source repair is deferred to the next explicit FVK-guided coding iteration, while this example refresh preserves the original source.
- **I4 — proof-scope / escalation evidence**
  - Evidence: `PROOF.md` and `[ESCALATION BOUNDARY]` notes where present.
  - Obligation: The running-sum loop is the clean proof payload; totality of the spec-only `listsum` fold remains an explicit escalation boundary.
  - Status: constructed, not machine-checked; escalation boundaries are stated honestly rather than trusted.


Plain-English companion to the formal artifacts, for a developer who will never
open the `.k` files. Produced by the formal-verification-kit `/formalize` step.

- **Program:** [`average.py`](average.py) — `average(nums)` returns the arithmetic
  mean of a non-empty list of numbers. It is now **self-contained**: it sums the
  elements with an explicit `while` loop (`total = total + nums[i]`, `i = i + 1`),
  then divides the running total by `len(nums)`.
- **Artifacts:** [`mini-python.k`](mini-python.k) (the mini-X fragment semantics,
  over **lists**, with a loop), [`average-spec.k`](average-spec.k) (**two**
  K `claim`s: the function contract `(AVG)` and the loop circularity `(LOOP)`).
- **Status:** specs **constructed, not machine-checked** (the MVP does not run
  `kompile`/`kprove`). The Findings (see [`FINDINGS.md`](FINDINGS.md)) hold today
  regardless of machine-checking — in particular, the empty-list bug was **executed
  against the real code**, not merely conjectured.
- **Default scope:** **partial correctness** — the contract constrains terminating
  runs; termination is a recommendation (see Findings), not proved. (The loop here
  obviously terminates: `n - i` strictly decreases from `n` to `0`.)

## What is specified

### Function contract — `(AVG)`

> **Precondition:** `len(nums) >= 1` (the list is non-empty).
> **Postcondition:** `result = listsum(nums, 0, len(nums)) // len(nums)`
> — i.e. `result` is the integer mean: the whole-list sum divided (truncating) by
> the length.

For every **non-empty** integer list `nums`, the function returns the mean of its
elements. Encoded as a reachability claim: from a configuration that *defines*
`average` and *calls* it on a symbolic list `NUMS` with `size(NUMS) >= 1`, execution
terminates with `result |-> listsum(NUMS, 0, size(NUMS)) /Int size(NUMS)`.

`listsum(L, lo, hi)` is a **spec-only abstraction function** — a clean inductive
**range fold** giving the sum of `L[lo], …, L[hi-1]` (the half-open range `L[lo:hi)`).
It is *spec vocabulary*, never a language construct (Python sums via the explicit
loop). It is the list analogue of the `sum-up` example's polynomial closed form, and
of `isSorted`/`bag` in `insertion-sort`. It is defined in
[`average-spec.k`](average-spec.k) by two equations: empty range → `0`, and
peel-the-last → `listsum(L,lo,hi) = listsum(L,lo,hi-1) + L[hi-1]`.

### Loop circularity — `(LOOP)` (the new, key part vs the builtin-`sum()` version)

> At the head of `while i < n` (with `n = len(nums)` and `0 <= i <= n`): the
> invariant is **`total = listsum(nums, 0, i)`** — the running total equals the sum
> of the prefix `nums[0:i)`. Running the loop to exit (`i = n`) leaves
> `total = listsum(nums, 0, n)` (the whole-list sum) and `i = n`.

Generalized over the accumulator `total = T` and the counter `i = I` (not pinned to
their entry values `0, 0`), with the load-bearing side condition `0 <= I <= N`
(`N = size(nums)`). K's reachability prover uses this claim as its **own coinduction
hypothesis**, so it **discharges its own loop** — the "running prefix-sum" plays the
role a hand-written invariant used to (exactly the `sum-up` shape).

**The step is definitional/clean.** Because the program now *literally adds the list
element* each iteration, the step verification condition is

> `total_new = total + nums[i]`,  i.e.  `listsum(nums,0,i) + nums[i] = listsum(nums,0,i+1)`

which is **exactly the unfold (defining) equation of `listsum`** — a single fold
step, no division, no truncation, no nonlinear arithmetic. **This is the headline
difference from the previous `return sum(nums) / len(nums)` version**, whose only VC
entangled the fold with a **truncating `/Int` divisibility** fact (a genuine
`[ESCALATION BOUNDARY]`). Here that escalation is **gone**: the loop is
**escalation-FREE** (see "Escalation status" below).

## The load-bearing precondition (the headline finding)

The precondition `len(nums) >= 1` is **not cosmetic** — it is the missing
precondition the code never states. On the empty list, the loop never runs (so
`total = 0`), `n = len([]) = 0`, and the final expression is `total / n = 0 / 0`,
which Python raises as **`ZeroDivisionError`**. In the semantics this surfaces as the
division rule's `requires I2 =/=Int 0`: on `n = 0` the rule cannot fire and the
configuration is **stuck** — the formal mirror of the runtime exception. See
[`FINDINGS.md`](FINDINGS.md) Finding 1 (executed against the code).

## How the function proof composes (for `/verify`)

`def average` files the body into `<funcs>` → `result = average(NUMS)` evaluates the
argument (the list value) and `(call)` pushes the caller frame, gives a fresh scope,
binds `nums = NUMS` → body init `total = 0`, `i = 0`, `n = len(nums) = size(NUMS)` →
**apply `(LOOP)` as a lemma at `{T := 0, I := 0}`** (its precondition `0 <= 0 <= N`
holds since `N = size(NUMS) >= 1 > 0`), giving `total = listsum(NUMS, 0, size(NUMS))`
and `i = n` → `return total / n` fires the **division rule** **because
`size(NUMS) >= 1` makes the divisor non-zero** → `result |-> listsum(NUMS, 0,
size(NUMS)) /Int size(NUMS)`.

So the lemma chain is `(AVG)` reuses `(LOOP)` — the **same one-level** depth as
`sum-up`'s `(SUM)` reuses `(LOOP)` (not the two-level nesting of `insertion-sort`).

## Arithmetic / data the proof will need

- **Division non-zero side condition** `size(NUMS) =/=Int 0` — discharged by **Z3**
  from the precondition `size(NUMS) >= 1` (linear). This is the formal content of
  the missing precondition.
- **The loop step VC** `listsum(nums,0,i) + nums[i] = listsum(nums,0,i+1)` —
  discharged by the **fold's own defining equation** (a `[simplification]` unfold in
  [`average-spec.k`](average-spec.k)). **Clean / definitional — not an
  escalation.**
- **The loop exit VC** `listsum(nums,n,n) = 0` (empty range, `i = n`) — the fold's
  base equation; **Z3 + the base rule**.
- **Map extensionality** `{M[K<-V] #Equals M[K<-V']} => {V #Equals V'}` — bundled
  tier, to close the post-store implication pinning `result`/`total`.
- **The lone residual:** the `[function, total]` **totality of `listsum`** (that the
  range fold is well-defined on every `(L, lo, hi)` — a structural induction on
  `hi - lo`). This is a *mild spec-symbol-totality* obligation, the only
  `[ESCALATION BOUNDARY]` here — **stated, not admitted as `[trusted]`**. It is
  **far milder** than the previous version's divisibility-under-truncation boundary.

## Escalation status — **the loop is escalation-FREE**

| Version | Sum computed by | Loop claim? | Hardest VC | Escalation |
|---|---|---|---|---|
| **previous** (`return sum(nums)/len(nums)`) | builtin `sum()` | none | `sum /Int len * len = sum` (divisibility under truncating `/Int`, over a symbolic fold) | **genuine** `[ESCALATION BOUNDARY]` |
| **this** (explicit `while` loop) | explicit loop | **`(LOOP)` circularity** | `listsum(nums,0,i) + nums[i] = listsum(nums,0,i+1)` (a single fold **unfold**) | **none** — clean/definitional |

The self-contained loop version is **escalation-free at the proof level**: every
verification condition (loop step, loop exit, division side condition, post-store) is
discharged by the bundled tier (Z3 + the fold's defining equations + map
extensionality). The **only** obligation routed to the papers is the *totality* of
the spec-only fold symbol `listsum` — a mild structural-induction housekeeping fact,
not an entanglement of the sum with truncating division. See
[`PROOF.md`](PROOF.md) §4 and [`FINDINGS.md`](FINDINGS.md) #5.

## Mini-X semantics scope (only what the code touches)

Integer literals/names, `len(e)`, index read `e[e]`, `+`, `<` (the loop guard), `/`
(modeled as integer `/Int`), assignment `x = e`, `while`, `def`, `return`, function
call. **No `if`, no `-`/`*`, no list mutation / index-assign, no `list()`, no slices,
no exceptions** — `average` uses none of them. Elements are restricted to `Int`
(genericity gap = Finding 4); `/` is modeled as integer division (int-vs-float gap =
Finding 3) — both surfaced as Findings, not silently erased.

> `average.py` carries inline `__main__` tests, but the verified core is the **pure
> function** `average(nums)`; the test wrapper is outside the contract.

## Next step

Run the kit's **`/verify`** to construct the proof of `(AVG)`/`(LOOP)`, emit the
`kompile`/`kprove` commands, and get the test-redundancy recommendation.
