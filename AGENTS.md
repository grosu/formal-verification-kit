# AGENTS.md — Formal Verification Kit

This is a provider-neutral kit that lets any coding agent add **formal specifications** (K reachability claims + matching-logic conditions) to code and **construct a correctness proof** for them. It exposes two commands: **`/formalize`** (write the specs + a plain-language Findings report) and **`/verify`** (construct the proof, emit the `.k` artifacts and `kompile`/`kprove` commands, and recommend which now-redundant tests to drop).

Even for users who have never heard of formal verification, the kit delivers two benefits: fewer tests / faster CI, and surfacing hidden subtle bugs — see [`README.md`](README.md).

## BOOTSTRAP (one-time learn step — skip if already internalized)

Before using these commands, read [`knowledge/matching-logic.md`](knowledge/matching-logic.md), [`knowledge/k-framework.md`](knowledge/k-framework.md), and [`knowledge/reachability-and-circularities.md`](knowledge/reachability-and-circularities.md). This is the one-time "learn K + matching logic" step. These primers are a fast path for common cases; escalate to [`knowledge/sources.md`](knowledge/sources.md) (papers, matching-logic.org, K docs; optional `--refresh`) when a case isn't covered.

## TRIGGERS

- When the user says **`/formalize`**, follow [`commands/formalize.md`](commands/formalize.md).
- When the user says **`/verify`**, follow [`commands/verify.md`](commands/verify.md).
- **No arguments yet** → operate on the whole project / each function in it.

## TEMPLATE

Imitate [`examples/sum-up/`](examples/sum-up/) — see its [`README.md`](examples/sum-up/README.md) for the file-by-file template (the fragment "mini-X" K semantics, the reachability/circularity claims, and the constructed proof).

---

Provider-neutral: any agent that reads this `AGENTS.md` works — Claude Code, Copilot CLI, Gemini CLI, Codex, and others.
