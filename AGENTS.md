# AGENTS.md — Formal Verification Kit

This is a provider-neutral kit that lets any coding agent add **formal specifications** (K reachability claims + matching-logic conditions) to code and **construct a correctness proof** for them. It exposes two commands: **`/formalize`** (write the specs + a plain-language Findings report) and **`/verify`** (construct the proof, emit the `.k` artifacts and `kompile`/`kprove` commands, accumulate proof-derived Findings, and recommend which tests to add, keep, or conditionally drop).

The intended automatic loop is: problem prompt → conventional code generation → learn this kit → `/formalize` → `/verify` → stop with the accumulated evidence package (`FINDINGS.md`, `SPEC.md`, `PROOF.md`, `.k` artifacts, and next-iteration guidance). Do not silently regenerate or patch code during this loop unless the user explicitly asks for a repair pass; the default goal is to gather feedback that makes the next code-generation pass better.

## NON-NEGOTIABLE ARTIFACT CONTRACT

FVK is **not** a Markdown-only review/audit. A run that produces only `SPEC.md`,
`PROOF_OBLIGATIONS.md`, `FINDINGS.md`, or other prose is **invalid** as an FVK
run, even if the prose is insightful.

Every real FVK run must emit the machine-checkable core:

- `<name>.k` — the K semantics/fragment being reasoned about;
- `<name>-spec.k` — K `claim` blocks for the function contract(s), loop
  circularit(y/ies), ordering/precedence obligations, and other formal properties;
- `PROOF.md` — the constructed proof that refers to those claims;
- exact `kompile` / `kast` / `kprove` commands, labeled **constructed, not
  machine-checked** unless the toolchain actually returns `#Top`.

If the agent cannot write credible `.k` semantics and `.k` claims for the target,
it must stop and report the result as **invalid/unresolved**, not silently weaken
FVK into natural-language analysis.

In a blackbox code-generator setting, these artifacts may be internal evidence and
the outside evaluator may score only the final patch. But internally the magic is
the formalization/proof bottleneck: prompt intent → `.k` claims → proof obstacles
→ Findings → next code patch. Preserve that bottleneck.

Even for users who have never heard of formal verification, the kit delivers two benefits: fewer tests / faster CI, and surfacing hidden subtle bugs — see [`README.md`](README.md).

## BOOTSTRAP (one-time learn step — skip if already internalized)

Before using these commands, read [`knowledge/intent-evidence.md`](knowledge/intent-evidence.md), [`knowledge/matching-logic.md`](knowledge/matching-logic.md), [`knowledge/k-framework.md`](knowledge/k-framework.md), and [`knowledge/reachability-and-circularities.md`](knowledge/reachability-and-circularities.md). This is the one-time "learn public intent + K + matching logic" step. These primers are a fast path for common cases; escalate to [`knowledge/sources.md`](knowledge/sources.md) (papers, matching-logic.org, K docs; optional `--refresh`) when a case isn't covered.

**When you have read them, tell the user you've learned the kit and are ready to `/formalize` and `/verify` — then wait for them.**

## TRIGGERS

- When the user says **`/formalize`**, follow [`commands/formalize.md`](commands/formalize.md).
- When the user says **`/verify`**, follow [`commands/verify.md`](commands/verify.md).
- Users usually phrase these as **"run /formalize"** / **"run /verify"** (a leading bare `/` can be intercepted as a slash command). Treat *"run /formalize"*, *"please formalize this"*, *"/formalize the project"*, etc. as the same trigger.
- **No arguments yet** → operate on the whole project / each function in it.

## TEMPLATE

Imitate the **closest example by shape** in [`examples/`](examples/) — start from its [catalog](examples/README.md). The reference pair is [`examples/02-sum-up/`](examples/02-sum-up/) (count-up / additive invariant) and [`examples/03-sum-down/`](examples/03-sum-down/) (count-down / remaining-work invariant); each shows the file-by-file template — the mini-X K semantics, the reachability/circularity claims, the spec note, the findings, and the constructed proof. For every new target, first build a public intent ledger from the prompt / issue / docs / tests / code, then make the `.k` claims trace back to that ledger. If a precondition, postcondition, invariant, ordering rule, or proof side condition comes from the current implementation and looks different from the human requirement, question it unless it has public intent evidence or is an explicitly named default-domain assumption.

---

Provider-neutral: any agent that reads this `AGENTS.md` works — Claude Code, Copilot CLI, Gemini CLI, Codex, and others.
