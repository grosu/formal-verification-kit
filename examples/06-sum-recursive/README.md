# Example: `sum-recursive` (Python) — the recursive variant

> **Authenticity / repair-loop note.** The source program here is the frozen, no-human-touch `.py` output vibe-coded by **Claude Code Opus 4.8 (`opus-4-8`)** from the prompt in `PROMPTS.md`. This example shows the FVK audit/evidence phase before repair: FVK formalizes, proves or hits escalation boundaries, and reports Findings. In normal use, the coding agent then uses those FVK artifacts to repair the code; this corpus keeps the pre-repair source frozen so the Findings remain visible.


This is the **recursion** member of the `sum-*` cluster: the same contract as
[`../02-sum-up/`](../02-sum-up/) and [`../03-sum-down/`](../03-sum-down/)
(`sum(n) = 1 + 2 + … + n = n*(n+1)/2`), but implemented by a **recursive call**
instead of a loop. There is **no loop here**, so there is **no loop invariant** —
the circularity is on the **recursive call's contract** `(REC)`:
`sum_recursive(N) ⇒ N*(N+1)/2` discharges its own inner call `sum_recursive(N-1)`,
bottoming out at the base case `n == 0`.

## Provenance — how this example was produced

The `/formalize` artifacts ([`SPEC.md`](SPEC.md), [`FINDINGS.md`](FINDINGS.md),
[`mini-python.k`](mini-python.k), [`mini-python-spec.k`](mini-python-spec.k)) were
produced by an **isolated-newcomer** agent that learned the kit and ran `/formalize`
on independently-written code; the `/verify` proof ([`PROOF.md`](PROOF.md)) was
constructed when the example was brought into the kit. That two-stage split — a
newcomer formalizes, then `/verify` proves — is the kit's standard "how examples are
produced" methodology (see the [examples catalog](../README.md)).

## The files

| File | What it is | Stage |
|---|---|---|
| [`sum_recursive.py`](sum_recursive.py) | **The program** — `if n == 0: return 0; return n + sum_recursive(n - 1)`, with `isinstance`/`n < 0` guards. | — |
| [`mini-python.k`](mini-python.k) | **The minimal K semantics** of just the fragment used: integer literals/names, `+`, `-`, `==`, `=`, `if` (no `else`), `def`, `return`, call. **No `while`**, **no `+=`**, **no `<=`/`<`**. | `/formalize` |
| [`mini-python-spec.k`](mini-python-spec.k) | **The claims**: `(REC)` the recursive-call circularity, and `(SUM)` the function contract (pre `n >= 0`, result `n*(n+1)/2`). | `/formalize` |
| [`SPEC.md`](SPEC.md) | Plain-English spec note. | `/formalize` |
| [`FINDINGS.md`](FINDINGS.md) | Plain-language findings (incl. the *positive* `n >= 0` finding and the depth-limit). | `/formalize` |
| [`PROOF.md`](PROOF.md) | **The condensed proof** plus findings and the test-redundancy recommendation. | `/verify` |
| [`README.md`](README.md) | This overview. | — |
| [`PROMPTS.md`](PROMPTS.md) | **The exact prompts** that produced this example, in order — the reproducibility pattern. | — |

## Read the proof

See **[PROOF.md](PROOF.md)** for the condensed reachability-logic proof, the
`kompile`/`kprove` commands, and the human-readable findings. (MVP status:
**constructed, not machine-checked** — PROOF.md emits the exact commands to run it.)

## What recursion changes — the teaching payload

Same contract, but a genuinely different proof shape:

1. **No loop invariant — a call-contract circularity instead.** Where `sum-up`/`sum-down`
   prove a `(LOOP)` claim that re-enters a `while`, here `(REC)` is a claim about the
   *call expression* (`sum_recursive(N) ~> CONT => N*(N+1)/2 ~> CONT`) and K reuses it
   as its own coinductive hypothesis to close the inner call `sum_recursive(N-1)`.
   **Guardedness** is paid by the `call` step that fires before the hypothesis is
   reused; the **back-edge is the recursive call**, and the **base case is the
   non-recursive branch** (`n == 0`).
2. **`if` / `==`, but no new K machinery.** This is the first cluster member to use
   `if` and `==` (sum-up/sum-down use neither). Recursion itself needs **no new
   semantics** — the existing call/return/stack handles self-calls because `<funcs>`
   is framed, so the defined function is visible to its own body.

Plus two sharper **Findings** than the loops have:

- **Finding 1 flips positive.** This version **validates `n < 0`** and raises
  `ValueError`, so its `n >= 0` finding *fixes* the silent bug the loop examples carry
  (where `sum(-3)` quietly returns `0`). The spec's `requires N >= 0` is a guard the
  code already implements.
- **Finding 3 is measured.** Non-tail recursion hits CPython's default limit: the
  **smallest failing input is `n = 998`** (`RecursionError`), so it returns correctly
  only for `0 ≤ n ≤ 997`. The recursion is well-founded; the limit is a stack-depth
  artifact — prefer an iterative loop or the closed form for unbounded `n`.

## The cluster

[`sum-up`](../02-sum-up/) (up-counting) · [`sum-down`](../03-sum-down/) (down-counting) ·
**`sum-recursive`** (recursion, this one). A deliberate set of same-spec variants
showing **more ways to satisfy one specification** — and how the proof obligations
differ even though the contract does not. See the [examples catalog](../README.md)
for the full set.
