# Formal Verification Kit

**Prove your code correct for *all* inputs — and let your AI agent do the work.**

Point any coding agent at this repo and run `/formalize` then `/verify` on your
code. You get two concrete wins even if you have never heard of "formal
verification":

## Benefit 1 — Fewer tests, faster CI

A formally verified function is proven correct for **every** input in its
specified domain — not just the handful your unit tests happen to check. So the
tests that merely re-check input/output cases the spec already covers become
**redundant**.

After `/verify`, the kit tells you exactly **which existing tests are now
subsumed** by the proof and recommends removing them, with an estimate of the CI
time saved. It is conservative and **recommendation-only** — it never deletes a
test, and (because the MVP constructs proofs but does not yet machine-check them,
see [Honest status](#honest-status)) it advises you to run the emitted
`kprove` commands first, or keep the tests until you do. Tests outside the spec's
domain, plus termination, performance, and integration tests, are always kept.

## Benefit 2 — Finds hidden, subtle bugs

You get this one **even if you never read a single line of the proof.**

The act of writing a precise specification routinely flushes out **missing
preconditions, forgotten corner cases, and undefined behavior** — the empty
input, the zero, the negative number, the off-by-one, the overflow. And here is
the key signal: **if a clean specification is hard or impossible to write, that
is itself strong evidence the code has a bug or a forgotten case.**

The kit reports all of this in plain language as a **Findings report** —
`input → observed vs expected` — readable by any developer. This is the primary
day-one value for people who don't care what formal verification is.

---

## What it is

A standalone, **provider-neutral** public repo of plain-markdown files. There is
nothing to install and no SDK to wire up. Any coding agent that can read a repo
(Claude Code, Copilot CLI, Gemini CLI, Codex, …) can use it, because the two
"commands" are just conventions defined in a markdown file the agent reads.

## The automated improvement loop

The intended use is an automatic loop around ordinary code generation:

1. Start with a problem prompt / informal intent.
2. Use your normal AI coding agent to generate code.
3. Teach that same agent this kit.
4. Run `/formalize` to infer the intended contract, write K claims, and collect
   intent/code mismatch Findings.
5. Run `/verify` to construct the proof attempt, collect proof-derived Findings,
   classify blocked VCs, and identify tests to add, keep, or conditionally remove.
6. **Stop with the accumulated evidence package** — `FINDINGS.md`, `SPEC.md`,
   `PROOF.md`, `.k` artifacts, and next-iteration guidance — so a conventional
   code generator can use that feedback to produce better code in the next pass.

The kit should not silently regenerate or patch the code during this workflow
unless the user explicitly asks for a repair pass. The default goal is to gather
better intent, better specifications, and better feedback than the original prompt
contained.

## Quick start — copy/paste to your agent

Bring this kit to code you've **already written or just generated**. You don't need
K, a prover, or anything installed. In your project, paste these to your coding
agent, in order.

**1. Teach it the kit** (works with any agent — Claude Code, Copilot, Gemini, Codex, …):

> Learn the Formal Verification Kit at https://github.com/grosu/formal-verification-kit
> — read its `AGENTS.md` and follow the BOOTSTRAP (read the `knowledge/` primers) so
> you actually learn it, not just skim the README. Tell me when you're ready.

*If your agent can't browse the web, first run `git clone
https://github.com/grosu/formal-verification-kit`, then paste:* "Read
`./formal-verification-kit/AGENTS.md` and follow it. Tell me when you're ready."

**2. (Recommended) Sanity-check the plan before any files are written:**

> Before writing any files, walk me through the spec and the loop invariant(s) you
> intend to write, and any concerns — no artifacts yet.

**3. Find the specs — and the bugs:**

> run /formalize

*Say **run /formalize**, not a bare `/formalize` — some agents (Claude Code, etc.)
treat a leading `/` as a built-in slash command and reject an unknown one.*

Then read the **Findings report** — the missing preconditions, corner cases, and
likely bugs it surfaced. (You get this even if you never read the proof.)

**4. Construct the proof — and accumulate next-iteration feedback:**

> run /verify

Then read the **proof**, the proof-derived additions to the **Findings report**, and
the **test-redundancy** recommendation. Stop there unless you explicitly want a
repair/regeneration pass; the accumulated findings are the feedback package for the
next code-generation iteration.

> **Tip:** append *"be exhaustive and adversarially verify this"* to steps 3–4 to
> make the agent cross-check itself — the proofs are *constructed, not yet
> machine-checked* (see [Honest status](#honest-status)).

Both commands need **no arguments** — they operate on the whole project (each
function and each loop). It works with **any** agent that reads `AGENTS.md`; it does
not have to be Claude Code.

## What you get

Running `/formalize` then `/verify` produces, written alongside your code:

- **Formal specifications** — a K reachability claim (pre/post-condition) for
  each function, and a **loop-invariant circularity** for each loop.
- **A constructed correctness proof** — symbolic execution of your code through
  the semantics, discharging the loop invariant, and checking the leftover
  arithmetic.
- **`.k` artifacts + run-commands** — the claim/semantics files and the exact
  `kompile` / `kprove` commands to machine-check the proof later.
- **A Findings report** (Benefit 2) — plain-language bugs, missing
  preconditions, and corner cases, each with a concrete example; `/verify` extends
  this with proof-derived findings when a VC, circularity, or side condition shows
  how the next code-generation pass should improve the code or intent.
- **A test-redundancy recommendation** (Benefit 1) — which tests the proof makes
  redundant, and which to keep.

This is one of a **growing library of worked examples** — browse the catalog in
[`examples/`](examples/). Each takes a real function from source code all the way
to a constructed proof, file for file. The first members are the **`sum-*`
cluster** — [`sum-up/`](examples/02-sum-up/) and [`sum-down/`](examples/03-sum-down/)
compute the *same* contract (`n·(n+1)/2`) by counting **up** vs. **down**, showing
that **the proof obligations differ even when the spec does not**. More are added
over time — and the vetted, machine-checked ones double as the fine-tuning corpus
for the product. See [`examples/README.md`](examples/README.md) for the catalog and
how to add your own.

## <a id="honest-status"></a>Honest status (MVP)

This is a first MVP, optimized for reach. We are upfront about what it does *not*
yet do:

- **Constructs the proof, does not run it.** `/verify` builds the proof and emits
  the exact `kompile`/`kprove` commands, but **does not invoke the toolchain**.
  Artifacts are clearly labeled **"constructed, not machine-checked."** Test
  removal is therefore a recommendation *conditioned on* you running those
  commands. (The Findings report does **not** depend on machine-checking and is
  solid today.)
- **Fragment ("mini-X") semantics.** For the MVP, the kit generates a minimal K
  semantics covering only the constructs your code actually uses — exactly as the
  `sum` example builds a *mini Python*. This is a deliberate stopgap. Wiring in
  **full, real per-language K semantics** (so the literal program is verified
  against the real language) is the roadmap.
- **Partial correctness by default.** The proof establishes correctness *if the
  function returns*; termination is surfaced as a recommendation, not proved
  unless asked.

The distilled primers in [`knowledge/`](knowledge/) are a **fast path** for
common cases. When your case exceeds them (recursive data structures, binders,
concurrency, …), [`knowledge/sources.md`](knowledge/sources.md) is the
first-class escalation path — it routes you to the right primary source by topic,
and an optional `--refresh` re-fetches them live.

## The vision

The end state is a **fine-tuned model** that already knows full language
semantics, the [K framework](https://kframework.org), matching logic, and the
proof techniques — so that **one line in yields a verified program out**, with
zero extra effort. This MVP approximates that today with bundled knowledge plus
an agent-driven workflow.

## Layout

| Path | What it is |
|---|---|
| [`README.md`](README.md) | This file — what it is, the two benefits, how to try it, status, vision. |
| [`AGENTS.md`](AGENTS.md) | Universal entrypoint: bootstrap + defines the `/formalize` and `/verify` triggers. |
| [`commands/formalize.md`](commands/formalize.md) | The `/formalize` workflow (agent-agnostic steps). |
| [`commands/verify.md`](commands/verify.md) | The `/verify` workflow (agent-agnostic steps). |
| [`knowledge/matching-logic.md`](knowledge/matching-logic.md) | Matching-logic primer: patterns-as-sets, the definedness ladder, the proof system. |
| [`knowledge/k-framework.md`](knowledge/k-framework.md) | K primer: config cells, rules, claims, `kprove`, `/Int`. |
| [`knowledge/reachability-and-circularities.md`](knowledge/reachability-and-circularities.md) | Reachability logic, the Circularity rule, the proof recipe. |
| [`knowledge/sources.md`](knowledge/sources.md) | Live source index + the `--refresh` escalation path. |
| [`examples/`](examples/) | A **growing library** of worked examples — [catalog + how-to-add](examples/README.md). The first is [`sum-up/`](examples/02-sum-up/) (Python `sum`), the template the commands imitate. |
| [`LICENSE`](LICENSE) | MIT. |
| `docs/` | Internal design spec — not part of the user-facing kit. |

## License

[MIT](LICENSE).
