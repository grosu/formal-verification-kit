# AGENTS.md — Formal Verification Kit

This is a provider-neutral kit that lets any coding agent add **formal specifications** (K reachability claims + matching-logic conditions) to code and **construct a correctness proof** for them. It exposes two commands: **`/formalize`** (write the specs + a plain-language Findings report) and **`/verify`** (construct the proof, emit the `.k` artifacts and `kompile`/`kprove` commands, accumulate proof-derived Findings, and recommend which tests to add, keep, or conditionally drop).

The intended automatic loop is: problem prompt → conventional code generation → learn this kit → `/formalize` → `/verify` → stop with the accumulated evidence package (`INTENT_SPEC.md`, `FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`, `PUBLIC_COMPATIBILITY_AUDIT.md`, `FINDINGS.md`, `SPEC.md`, `PROOF.md`, `.k` artifacts, and next-iteration guidance). Do not silently regenerate or patch code during this loop unless the user explicitly asks for a repair pass; the default goal is to gather feedback that makes the next code-generation pass better.

## NON-NEGOTIABLE ARTIFACT CONTRACT

FVK is **not** a Markdown-only review/audit. A run that produces only `SPEC.md`,
`PROOF_OBLIGATIONS.md`, `FINDINGS.md`, or other prose is **invalid** as an FVK
run, even if the prose is insightful.

Every real FVK run must emit the machine-checkable core:

- `mini-<lang>.k` (for example `mini-python.k`) — the K semantics/fragment being reasoned about;
- `<program>-spec.k` (for example `binary-search-spec.k` or `average-spec.k`) — K `claim` blocks for the function contract(s), loop
  circularit(y/ies), ordering/precedence obligations, and other formal properties;
- `PROOF.md` — the constructed proof that refers to those claims;
- exact `kompile` / `kast` / `kprove` commands, labeled **constructed, not
  machine-checked** unless the toolchain actually returns `#Top`.

Every real FVK run must also emit the adequacy/audit core that prevents proving the
wrong thing:

- `INTENT_SPEC.md` — intent-only English obligations extracted from the prompt,
  docs, public tests, names, and default-domain conventions **before** accepting
  candidate/legacy behavior as a spec;
- `PUBLIC_EVIDENCE_LEDGER.md` — the standalone ledger of public evidence mirrored
  into `SPEC.md` and `SPEC-PROVENANCE` comments above the relevant claims;
- `FORMAL_SPEC_ENGLISH.md` — a plain-English paraphrase of every nontrivial K
  claim/circularity and expected result;
- `SPEC_AUDIT.md` — a claim-by-claim comparison of `FORMAL_SPEC_ENGLISH.md`
  against `INTENT_SPEC.md`, marking pass/fail/ambiguous;
- `PUBLIC_COMPATIBILITY_AUDIT.md` — public callsite/API/override compatibility
  audit for every changed public symbol or virtual dispatch/signature.

A proof that closes against `.k` claims whose English paraphrase does not match
public intent is a proof of the wrong contract. Treat it as **invalid/unresolved**
and feed the mismatch into `FINDINGS.md` rather than using it to justify `V2 == V1`.

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
- When the user says **"use FVK"**, **"use the Formal Verification Kit"**, **"run FVK on this code"**, **"FVK my code"**, or **"use FVK now because the current code is not good enough"**, treat that as the complete black-box FVK improvement loop: learn this kit, run `/formalize`, run `/verify`, and if the user asked for better/repaired code, apply only the changes justified by the FVK artifacts.
- **No arguments yet** → operate on the whole project / each function in it.

## BLACK-BOX IMPROVEMENT RULES

FVK must be self-contained. Do not rely on wrapper-specific hints such as "the baseline failed", hidden tests, evaluator output, gold patches, benchmark scores, or any success/failure status for a previous attempt. The only allowed evidence is public/user-provided intent, public docs/tests, the current code, and proof/formalization obstacles discovered while running FVK.

### Normal software-development use

The primary product experience is not a benchmark. A developer should be able to keep using their usual coding environment and, at any point in the normal lifecycle, say something like **"use FVK"**, **"run FVK on this code"**, or **"FVK my code"**. The agent should then learn this kit, run `/formalize`, run `/verify`, produce the evidence package, and — if the user asked for improvement/repair — revise production code only when the FVK artifacts justify the change.

In day-to-day use, treat the current project state as the candidate to audit. It is fine for FVK to build on the ordinary coding context, design notes, public issue text, docs, and source code already available in that environment. The important boundary is evidentiary: FVK's verdict must come from public/user-provided intent, source code, public docs/tests, and its own proof/formalization findings, not from hidden evaluator signals or benchmark-only metadata.

### Benchmark and audit use

When comparing an ordinary coding pass against an FVK pass, use the **faithful-baseline + resumed-FVK** protocol:

1. Generate the first repair exactly as a normal coding task, before any FVK files or FVK instructions are present.
2. Freeze that repair's code, notes, and reasoning context.
3. Only then introduce FVK materials and continue from the same coding context/session if the agent platform supports it.
4. Do not reveal test results, evaluator verdicts, gold patches, or whether the first repair passed/failed. Run evaluation only after the FVK generation phase is complete.

This benchmark/audit protocol gives FVK the intended benefit of building on everything the coding pass learned, while preserving a clean, truthful baseline: FVK may inherit the coder's public-problem reasoning and candidate patch, but not any external success/failure signal.

When improving code, derive the verdict from FVK artifacts:

1. Build the public intent ledger first.
2. Treat the current implementation as a candidate, not as the specification.
3. Treat public/in-repo tests as evidence, not as an oracle. If a test appears to encode behavior contradicted by the public issue or public intent, mark that obligation **SUSPECT** and explain the conflict instead of preserving legacy behavior automatically.
4. If a clean spec or proof obligation cannot be written without forcing legacy behavior, record a Finding and revise the code only when the public intent justifies the revision.
5. Do not edit tests unless the user explicitly asks. The default repair target is production code.

## TEMPLATE

Imitate the **closest example by shape** in [`examples/`](examples/) — start from its [catalog](examples/README.md). The reference pair is [`examples/02-sum-up/`](examples/02-sum-up/) (count-up / additive invariant) and [`examples/03-sum-down/`](examples/03-sum-down/) (count-down / remaining-work invariant); each shows the file-by-file template — the mini-X K semantics, the reachability/circularity claims, the spec note, the findings, and the constructed proof. For every new target, first build a public intent ledger from the prompt / issue / docs / tests / code, then make the `.k` claims trace back to that ledger. If a precondition, postcondition, invariant, ordering rule, or proof side condition comes from the current implementation and looks different from the human requirement, question it unless it has public intent evidence or is an explicitly named default-domain assumption.

---

Provider-neutral: any agent that reads this `AGENTS.md` works — Claude Code, Copilot CLI, Gemini CLI, Codex, and others.
