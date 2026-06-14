# Reproducibility — the kit-based prompts that reproduce `sum-up`

> **Source-program provenance.** The `.py` program in this folder is intentionally preserved as the exact vibe-coded output of **Claude Code Opus 4.8 (`opus-4-8`)** from prompt P1 below, before FVK was introduced. This protocol refresh updates only FVK documentation/provenance artifacts; it does **not** repair, regenerate, or human-edit the source program. In the full FVK loop, a coding agent uses these artifacts to repair the code in a later iteration; this example freezes the pre-repair source so the Findings remain visible.


This entire example — the program, the mini Python semantics, the specification,
the findings, and the constructed proof — was produced interactively with **Claude
Code**, driven solely by natural-language prompts. This file is a forward-looking
recipe: the kit-based prompts that (re)produce this artifact, in order. It follows
the same pattern as the companion [`sum-down`](../03-sum-down/PROMPTS.md) example, adapted
to the count-**up** loop.

To reproduce, open Claude Code in an empty working directory **with the
formal-verification-kit available** (point the agent at the repo, or clone it), and
issue the prompts below **in order, in a single session** (context carries between
turns; each builds on the previous). The prompt marked 🌐 needs web/repo access.

## The prompts

```text
[P1]  Write a simple Python program that sums the numbers from 1 to n. Call it sum.
      Take an integer n. Use a while loop counting UP from 1 to n.

[P2]  🌐 Now formally verify this with the formal-verification-kit
      (github.com/grosu/formal-verification-kit). First learn the kit, then tell me
      when you are done so we can agree on the next step.

[P3]  Let's discuss the approach first — walk through the planned count-up loop
      invariant and its side condition (I <= N+1) together, before generating
      artifacts.

[P4]  Run /formalize.

[P5]  If I tell you /verify, what exactly are you going to verify — given you have
      already found bugs in the program?

[P6]  Go ahead and /verify.

[P7]  Add this to the kit's examples as sum-up (the count-up member of the sum-*
      cluster), following the same reproducibility/prompt pattern.
```

## What each prompt produces

- **P1** → [`sum.py`](sum.py): the count-up program (`s = 0; i = 1; while i <= n:
  s += i; i += 1`).
- **P2** → the agent reads the kit (`AGENTS.md`, the three knowledge primers, the
  two command workflows, and the sibling examples) and reports back the count-up
  adaptation it will make.
- **P3** → the agreed plan: the `(LOOP)` invariant `cfA(I,N) = (I+N)*(N-I+1)/2`
  with side condition `I <= N+1`, and the `(SUM)` contract — *no files yet*.
- **P4** (`/formalize`) → [`mini-python.k`](mini-python.k) (the `<=`/`+`/`+=` mini-X
  semantics), [`sum-up-spec.k`](sum-up-spec.k) (`(LOOP)` + `(SUM)`),
  [`SPEC.md`](SPEC.md), and [`FINDINGS.md`](FINDINGS.md) (the `n >= 0` finding).
- **P5** → the clarification (no files): `/verify` proves the *contract*
  (`n >= 0 → n*(n+1)/2`), **not** bug-freeness; the precondition *quarantines* the
  `n <= -2` bug rather than fixing it; options A (verify as written) / B (verify the
  as-built behavior over all ℤ) / C (fix then verify).
- **P6** (`/verify`) → [`PROOF.md`](PROOF.md) (the constructed proof, the
  `kompile`/`kprove` commands, the test-redundancy recommendation), labeled
  *constructed, not machine-checked*.
- **P7** → this example package: [`README.md`](README.md), this `PROMPTS.md`, and
  the `examples/02-sum-up/` layout.

## Notes for reproducers

- **Environment.** Claude Code with the formal-verification-kit available, plus
  Python 3 for the program. The K toolchain (`kompile`/`kprove`) is **not** needed
  to reproduce this document, but **is** needed to machine-check the claims (see
  [`PROOF.md`](PROOF.md) → "Reproduce the machine check").

- **The kit collapses the prompt sequence (the instructive part).** Without the
  kit — from scratch — an agent needs *two* explicit "go learn the foundations"
  prompts — *"go learn matching logic"* and *"go read the K framework"* — because
  it learns from primary sources. Here a **single** *"learn this kit"* (P2)
  replaces both: the kit *is* the pre-distilled matching logic + K + proof recipe.
  Likewise, the from-scratch *"write the spec / infer the circularity / prove it"*
  sequence collapses into **two commands**, `/formalize` and `/verify`. The kit is,
  in miniature, the "baked-in knowledge" a fine-tuned model will eventually provide.

- **The two highest-value turns are detours.** P3 (*discuss first*) and P5 (*what
  are you actually verifying?*) are not strictly required to produce the artifacts —
  but they are the most pedagogically useful turns. P5 in particular surfaces the
  central idea that **verification certifies conformance to a contract, not the
  absence of bugs** — directly relevant because `/formalize` had already found the
  `n <= -2` bug. Keep them.

- **Non-determinism.** LLM outputs vary run-to-run. The structure, the semantics,
  the claims, the findings, and the proof results should reproduce; exact wording
  will differ. Treat every generated semantics and proof as something to **review**,
  not trust blindly — append *"be exhaustive and adversarially verify this"* (or, if
  enabled, the *"ultracode"* / *"use a workflow"* trigger) to the `/formalize` and
  `/verify` prompts to fan out and cross-check.

- **Faithfulness.** The prompts above are the ones actually used in the session that
  built this example, lightly normalized for clarity; they can be pasted verbatim.

## The one-line prompt of the future

As with `sum-down`, the whole artifact should one day come from a single line —

> ### `Implement sum(n) in Python with a while loop counting up from 1 to n, and formally verify it with the kit.`

— with the kit's knowledge built in and the pipeline autonomous, so the program
arrives *together with* its specification, findings, and a machine-checked proof, at
zero extra effort. The multi-prompt sequence above is today's approximation of that
one line — already shorter than the from-scratch sequence, precisely because the kit exists.


> **Protocol refresh note.** Current `/formalize` also emits [`INTENT_SPEC.md`](INTENT_SPEC.md), [`PUBLIC_EVIDENCE_LEDGER.md`](PUBLIC_EVIDENCE_LEDGER.md), [`FORMAL_SPEC_ENGLISH.md`](FORMAL_SPEC_ENGLISH.md), [`SPEC_AUDIT.md`](SPEC_AUDIT.md), and [`PUBLIC_COMPATIBILITY_AUDIT.md`](PUBLIC_COMPATIBILITY_AUDIT.md). The K claims are now named [`sum-up-spec.k`](sum-up-spec.k) to identify the program being specified; [`mini-python.k`](mini-python.k) remains the language-fragment semantics.
