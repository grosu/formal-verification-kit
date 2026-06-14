# Reproducibility — the prompts that produce `sum-recursive`

> **Source-program provenance.** The `.py` program in this folder is intentionally preserved as the exact vibe-coded output of **Claude Code Opus 4.8 (`opus-4-8`)** from prompt P1 below, before FVK was introduced. This protocol refresh updates only FVK documentation/provenance artifacts; it does **not** repair, regenerate, or human-edit the source program. In the full FVK loop, a coding agent uses these artifacts to repair the code in a later iteration; this example freezes the pre-repair source so the Findings remain visible.


> **Provenance note (read this first).** This example was produced by an
> **isolated-newcomer agent** — the kit's "how examples are produced" methodology:
> a fresh Claude Code session, dropped into an empty directory, told only to learn
> the kit and to `/formalize` then `/verify` independently-written code. Because that
> cold run was isolated, the **exact prompts were not captured verbatim**. So the
> recipe below is **not** a transcript — it is the reproducibility **pattern**, written
> to be parallel to the sibling examples (`sum-up`, `sum-down`), that recreates this
> artifact. Pasting these prompts in order reproduces the same program, semantics,
> spec, findings, and proof; exact wording will differ run-to-run (see
> *Non-determinism* below).

This entire example — the program, the mini Python semantics, the specification, the
findings, and the constructed proof — comes out of natural-language prompts to **Claude
Code**, driven by the same 7-prompt shape as `sum-down`, adapted to a **recursive**
program (no loop, so no loop invariant; the circularity rides the recursive call's
contract instead).

To reproduce, open Claude Code in an empty working directory **with the
formal-verification-kit available** (point the agent at the repo, or clone it), and
issue the prompts below **in order, in a single session** (context carries between
turns; each builds on the previous). The prompt marked 🌐 needs web/repo access.

## The prompts

```text
[P1]  Let's write a very simple Python program which calculates the sum of numbers
      from 1 to n. Let's call it sum_recursive. It takes an input integer n. Do it
      with recursion, not a loop: the base case is `if n == 0: return 0`, and the
      recursive case is `return n + sum_recursive(n - 1)`. Validate the input: raise
      on n < 0, and reject bool (in Python bool is a subclass of int, so guard it
      explicitly).

[P2]  🌐 Now I'd like to formally verify this program using the formal-verification
      kit (github.com/grosu/formal-verification-kit). First, learn this formal
      verification kit, and then let me know when you are done so we can agree on
      the next step.

[P3]  Let's just discuss the approach first — before generating any artifacts. Note
      there is no loop here, so there is no loop invariant: the circularity is on the
      recursive call's own contract, call it (REC). Walk me through the base case
      (n == 0) and the side condition (N >= 0) on that contract.

[P4]  Run /formalize.

[P5]  If I tell you /verify, what exactly are you going to verify — given the findings
      you just produced?

[P6]  Go ahead and /verify.

[P7]  Add this to the kit's examples as sum-recursive, next to sum-up and sum-down —
      to show one more way to do the same thing (recursion), and one more way to use
      the kit. Follow the same reproducibility/prompt pattern we used in the siblings.
```

## What each prompt produces

- **P1** → [`sum_recursive.py`](sum_recursive.py): the recursive program
  (`if n == 0: return 0` / `return n + sum_recursive(n - 1)`) with the two input
  guards — `raise ValueError` on `n < 0`, and `raise TypeError` on `bool` (because
  `isinstance(True, int)` is `True`).
- **P2** → the agent reads the kit (`AGENTS.md`, the three knowledge primers, the two
  command workflows, and the sibling examples) and reports back the **recursion**
  adaptation it will make — explicitly noting there is no loop invariant to find.
- **P3** → the agreed plan: the `(REC)` contract `sum_recursive(N) → N*(N+1)/2`, its
  base case `N == 0`, and its side condition `N >= 0` — and that **K reuses every claim
  as its own coinduction hypothesis**, so `(REC)` discharges its own inner call. The
  whole-function `(SUM)` contract sits on top. *No files yet.*
- **P4** (`/formalize`) → [`mini-python.k`](mini-python.k) (the mini-X semantics with
  `if`/`==`/`+`/`-` and call/return — **no loop construct**),
  [`mini-python-spec.k`](mini-python-spec.k) (the `(REC)` circularity + the `(SUM)`
  function claim), [`SPEC.md`](SPEC.md), and [`FINDINGS.md`](FINDINGS.md) — including
  the positive finding that **`n >= 0` is *enforced*** (not silently assumed), the
  `bool`-subclass guard, and the **`RecursionError` depth limit** (smallest failing
  input `n = 998`).
- **P5** → the clarification (no files): `/verify` proves the **contract**
  (`N >= 0 → N*(N+1)/2`), **not** bug-freeness; it is **partial correctness** (correct
  *if and when* it returns); and the **recursion-depth limit is out of scope** — the
  proof says nothing about `n >= 998` failing, that's the Finding-3 robustness boundary
  a kept test must pin.
- **P6** (`/verify`) → [`PROOF.md`](PROOF.md): the constructed proof of `(REC)` by
  guarded coinduction (call step for guardedness, base/recursive case split, the two
  verification conditions `cf(0)=0` and `N + (N−1)N/2 = N(N+1)/2`) and of `(SUM)` using
  `(REC)` as a lemma, plus the `kompile`/`kprove` commands and the test-redundancy
  recommendation — labeled **constructed, not machine-checked**.
- **P7** → this example package: the `examples/06-sum-recursive/` layout, this `PROMPTS.md`,
  and the entry next to `sum-up`/`sum-down`.

## Notes for reproducers

- **Environment.** Claude Code with the formal-verification-kit available, plus Python 3
  for the program. The K toolchain (`kompile`/`kprove`) is **not** needed to reproduce
  this document, but **is** needed to machine-check the claims (see
  [`PROOF.md`](PROOF.md) → "Reproduce the machine check").

- **The kit collapses the prompt sequence (the instructive part).** From scratch —
  without the kit — an agent needs *two* explicit "go learn the foundations" prompts:
  *"go learn matching logic"* and *"go read the K framework"* — because it has to learn
  from primary sources. Here a **single** *"learn this kit"* (P2) replaces **both**: the
  kit *is* the pre-distilled matching logic + K + proof recipe. Likewise the
  from-scratch *"write the spec / infer the circularity / prove it"* sequence collapses
  into **two commands**, `/formalize` and `/verify`. The kit is, in miniature, the
  "baked-in knowledge" a fine-tuned model will eventually provide.

- **Recursion needed no new K machinery.** This is the headline methodology point of
  the recursive variant: moving from a loop to recursion changed **what the circularity
  is stated on** — the recursive call's contract `(REC)` instead of a loop invariant
  `(LOOP)` — but it required **no new K machinery**. Same `[all-path]` reachability
  claims, same coinduction (K reuses each claim as its own hypothesis), same
  guardedness mechanism (a genuine `call` step taken before the hypothesis is reused).
  The semantics in [`mini-python.k`](mini-python.k) drops the loop construct and adds
  `if`/`==`/call/return; nothing about the proof engine changed.

- **Input-validation guards are modeled as the reduced in-domain body.** The two guards
  in P1 — `if not isinstance(n, int) or isinstance(n, bool): raise TypeError` and
  `if n < 0: raise ValueError` — are **no-ops on the verified domain** (`n` a
  non-negative `int`): on that domain neither `raise` ever fires. So `/formalize`
  models the program **reduced to its in-domain core** —

  ```python
  def sum_recursive(n):
      if n == 0:
          return 0
      return n + sum_recursive(n - 1)
  ```

  — and turns the guards into **Findings** rather than semantics: the `n >= 0` guard
  becomes the positive Finding 1 (the precondition `requires N >=Int 0` is something
  the code *already enforces*, contrast the loops' silent `0`), and the `bool` guard
  becomes Finding 2 (a genuine safeguard, worth a kept regression test). This is the
  right division of labor: the proof covers the in-domain math; the Findings cover the
  out-of-domain behavior the proof deliberately does not.

- **The two highest-value turns are detours.** P3 (*discuss first*) and P5 (*what are
  you actually verifying?*) are not strictly required to produce the artifacts — but
  they are the most pedagogically useful turns. P3 is where the **no-loop / recursive-
  contract** shift gets named out loud; P5 surfaces that **verification certifies
  conformance to a contract, not the absence of bugs**, and draws the line that the
  `RecursionError` depth limit is *out of scope* for the partial-correctness proof.
  Keep them.

- **Non-determinism.** LLM outputs vary run-to-run. The structure, the semantics, the
  claims, the findings, and the proof results should reproduce; exact wording will
  differ. Treat every generated semantics and proof as something to **review**, not
  trust blindly — append *"be exhaustive and adversarially verify this"* (or, if
  enabled, the *"ultracode"* / *"use a workflow"* trigger) to the `/formalize` and
  `/verify` prompts to fan out and cross-check. The recursion circularity — a
  call-into-continuation claim that discharges its own inner call — is the one piece a
  reviewer should scrutinize first when `kprove` is eventually run.

- **Faithfulness.** Unlike the siblings, the prompts above were **not** captured from
  the originating session (it was an isolated cold run; see the provenance note). They
  are reconstructed to be parallel to `sum-up`/`sum-down` and to regenerate the same
  artifacts; they can be pasted verbatim.

## The one-line prompt of the future

As with the siblings, the whole artifact should one day come from a single line —

> ### `Implement sum(n) in Python with recursion (base case n == 0, recursive case n + sum(n-1)), validate the input, and formally verify it with the kit.`

— with the kit's knowledge built in and the pipeline autonomous, so the program arrives
*together with* its specification, findings, and a machine-checked proof, at zero extra
effort. The multi-prompt sequence above is today's approximation of that one line —
already shorter than the from-scratch sequence, precisely because the kit exists.
