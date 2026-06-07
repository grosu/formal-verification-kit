# AGENTS.md — Formal Verification Kit

This is a provider-neutral kit that lets any coding agent add **formal specifications** (K reachability claims + matching-logic conditions) to code and **construct a correctness proof** for them. It exposes two commands: **`/formalize`** (write the specs + a plain-language Findings report) and **`/verify`** (construct the proof, emit the `.k` artifacts and `kompile`/`kprove` commands, and recommend which now-redundant tests to drop).

Even for users who have never heard of formal verification, the kit delivers two benefits: fewer tests / faster CI, and surfacing hidden subtle bugs — see [`README.md`](README.md).

## BOOTSTRAP (one-time learn step — skip if already internalized)

Before using these commands, read [`knowledge/matching-logic.md`](knowledge/matching-logic.md), [`knowledge/k-framework.md`](knowledge/k-framework.md), and [`knowledge/reachability-and-circularities.md`](knowledge/reachability-and-circularities.md). This is the one-time "learn K + matching logic" step. These primers are a fast path for common cases; escalate to [`knowledge/sources.md`](knowledge/sources.md) (papers, matching-logic.org, K docs; optional `--refresh`) when a case isn't covered.

**When you have read them, tell the user you've learned the kit and are ready to `/formalize` and `/verify` — then wait for them.**

## TRIGGERS

- When the user says **`/formalize`**, follow [`commands/formalize.md`](commands/formalize.md).
- When the user says **`/verify`**, follow [`commands/verify.md`](commands/verify.md).
- **No arguments yet** → operate on the whole project / each function in it.

## TEMPLATE

Imitate the **closest example by shape** in [`examples/`](examples/) — start from its [catalog](examples/README.md). The reference pair is [`examples/sum-up/`](examples/sum-up/) (count-up / additive invariant) and [`examples/sum-down/`](examples/sum-down/) (count-down / remaining-work invariant); each shows the file-by-file template — the mini-X K semantics, the reachability/circularity claims, the spec note, the findings, and the constructed proof.

---

Provider-neutral: any agent that reads this `AGENTS.md` works — Claude Code, Copilot CLI, Gemini CLI, Codex, and others.
