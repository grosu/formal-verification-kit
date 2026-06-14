# Example: `sum-down` (Python) — the down-counting variant

> **Authenticity / repair-loop note.** The source program here is the frozen, no-human-touch `.py` output vibe-coded by **Claude Code Opus 4.8 (`opus-4-8`)** from the prompt in `PROMPTS.md`. This example shows the FVK audit/evidence phase before repair: FVK formalizes, proves or hits escalation boundaries, and reports Findings. In normal use, the coding agent then uses those FVK artifacts to repair the code; this corpus keeps the pre-repair source frozen so the Findings remain visible.


This is the **down-counting** member of the `sum-*` cluster: the same contract as
[`../02-sum-up/`](../02-sum-up/) (`sum(n) = 1 + 2 + … + n = n*(n+1)/2`), but implemented
by counting the loop **down** from `n` to `1` instead of **up** from `1` to `n`.
It is taken all the way from source code to a constructed correctness proof, file
for file, the same way `sum-up` is.

The point of the cluster is to show, side by side, **more ways to satisfy one
specification** — and how the *proof obligations* differ even though the contract
does not. (See [PROMPTS.md](PROMPTS.md) for *more ways to drive the kit*, the other
half of "instructive.")

## The files

| File | What it is |
|---|---|
| [`sum.py`](sum.py) | **The program** — `sum_to_n(n)` with `i = n; while i >= 1: total += i; i -= 1`. |
| [`mini-python.k`](mini-python.k) | **The minimal K semantics** of just the fragment used (the `>=` / `-=` mirror of `sum-up`: integer literals/names, `+`, `-`, `>=`, `=`, `+=`, `-=`, `while`, `def`, `return`, call — no `if`, no `<=`). |
| [`mini-python-spec.k`](mini-python-spec.k) | **The claims**: `(LOOP)` the down-counting loop circularity, and `(SUM)` the function contract (precondition `n >= 0`, result `n*(n+1)/2`). |
| [`SPEC.md`](SPEC.md) | Plain-English spec note (the `/formalize` stage). |
| [`FINDINGS.md`](FINDINGS.md) | Plain-language findings — the `n >= 0` bug (the `/formalize` stage). |
| [`PROOF.md`](PROOF.md) | **The condensed proof** plus findings and the test-redundancy recommendation (the `/verify` stage). |
| [`PROMPTS.md`](PROMPTS.md) | **The exact prompts** that produced this example, in order — the reproducibility pattern (see [`../02-sum-up`](../02-sum-up)). |

## Read the proof

See **[PROOF.md](PROOF.md)** for the condensed reachability-logic proof, the
`kompile`/`kprove` commands, and the human-readable findings and test-redundancy
notes. (MVP status: **constructed, not machine-checked** — PROOF.md emits the exact
commands to run it.)

## What counting *down* changes — the teaching payload

Same contract, but the proof is genuinely different (and a touch simpler). Three
structural diffs from `sum-up`, all surfaced while constructing the proof:

1. **`n` drops out of the loop spec.** The guard `i >= 1` compares to the constant
   `1`, so `(LOOP)` is independent of `n` (framed out with `...`). `sum-up`'s
   `i <= n` guard forced `n` into its loop claim. *Lesson: when a loop variable is
   not read by the loop, you may frame it out.*
2. **No "init" VC.** Entering the loop at `i = N` makes the loop's closed form
   `cf(N) = N*(N+1)/2` *syntactically* the target, so the function postcondition
   falls out of the loop invariant for free. `sum-up` enters at `i = 1` and owes an
   extra VC (`cfA(1,N) = N*(N+1)/2`). *Lesson: where you anchor the closed form sets
   how much arithmetic you owe.*
3. **One simplification lemma, not two.** Every halved product here is the
   consecutive-integer form `X*(X+1)`, so only the first exact-halving
   `[simplification]` is exercised; `sum-up`'s second `((A+B)*C)/2` lemma is dead
   code for this program. *Lesson: simplification needs are program-specific, not
   boilerplate.*

Plus the **side-condition mirror**: `sum-up` needs `I <= N+1`; `sum-down` needs
`I >= 0` (tight bound `I >= -1`) — the same soundness obligation entering from the
*low* side. And the same `n >= 0` finding appears in both, which is the deeper
point: **the bug is a property of the spec/intent, not of the loop direction.**

## The cluster

`sum-up` (up-counting) · **`sum-down`** (down-counting, this one) · `sum-recursive`
(planned) · … The cluster is a deliberate set of same-spec variants. When you want
a *new shape* (recursion, recursive data, binders, concurrency), escalate via
[`../../knowledge/sources.md`](../../knowledge/sources.md) — and the best way to
extend the kit to a new shape is another worked example.
