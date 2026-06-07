# Formal Verification Kit — Design (MVP)

- **Date:** 2026-06-07
- **Status:** approved (brainstorming), pending spec review → implementation plan
- **Working name:** `formal-verification-kit` (final name TBC before publishing)

## 1. Purpose & vision

Turn the spec-and-verify process discovered in the `sum(n)` experiment
(`formally-verified-sum`) into a **reusable, provider-neutral kit** that any
coding agent can use to formally specify and verify AI-generated code. It exposes
two commands:

- **`/formalize`** — add formal pre/post-conditions (reachability rules) for each
  function and a loop invariant (circularity) for each loop, plus a
  recommendations report.
- **`/verify`** — construct the correctness proof for those specs and emit the
  machine-checkable artifacts.

This is a **first MVP**, optimized for reach and "try it": maximize the number of
people/agents who can use it, publicize the repo, then optimize later.
Performance, deep integration, and turnkey per-agent wiring are explicitly *not*
goals yet.

**Product vision (context, not MVP scope).** The eventual product is a
**fine-tuned model** that already knows full language semantics, the K framework
(syntax, rules, specs, `kprove`), matching logic and its papers, and the proof
techniques (coinductive proofs/invariants, circularities). Then one line from the
human yields program + end-to-end formal verification with zero extra effort. The
MVP approximates that with bundled knowledge + an agent-driven workflow.

## 2. Form & packaging

- A standalone **public Git repo** of **provider-neutral plain-markdown** files
  that any agent (Claude Code, Copilot CLI, Gemini CLI, Codex, …) can read.
- **No agent-specific command/plugin files in the MVP.** The two "commands" are
  conventions defined in `AGENTS.md`; an agent honors `/formalize` and `/verify`
  after reading the kit.
- **Split files** (knowledge / workflows / example separated) so an agent loads
  only what it needs and humans can read it.

Rationale: provider-neutral maximizes reach for an MVP; native per-agent adapters
are a later optimization.

## 3. Repo layout

```
README.md         — what it is, why, how to try it, the product vision (publicize-ready)
AGENTS.md         — universal entrypoint: bootstrap + defines the /formalize and
                    /verify triggers; instructs the agent to read knowledge/ first
commands/
  formalize.md    — the /formalize workflow (agent-agnostic steps)
  verify.md       — the /verify workflow (agent-agnostic steps)
knowledge/        — the distilled "learning" (bundled = instant, offline)
  matching-logic.md                 — patterns-as-sets, definedness ladder, μ, proof system
  k-framework.md                    — config cells, rules, seqstrict/heating, claims,
                                      kprove, simplifications, the Lesson 1.22 pattern, /Int
  reachability-and-circularities.md — reachability logic, the Circularity rule,
                                      coinductive invariants, the proof recipe, VC discharge
  sources.md                        — links to papers / matching-logic.org / K docs (refresh)
examples/
  sum/            — the worked sum example (program + mini-python.k + spec + proof excerpt)
                    as a template the agent imitates
LICENSE
```

## 4. Knowledge delivery

- **Bundle distilled references** in `knowledge/` (the distilled result of what we
  learned this session): read on load → instant, offline, identical every time.
- **Optional refresh**: `/formalize --refresh` / `/verify --refresh` re-fetches the
  live sources listed in `knowledge/sources.md`. (Documented option; not the
  default.)

## 5. `/formalize` workflow (no args → whole program / each function)

1. **Learn** — read `knowledge/*.md` if not already internalized (instant; bundled).
2. **Read the target** — identify each function and each loop; infer intended
   behavior from code + names + docstrings + tests.
3. **Specify each function** — write its pre/post-condition as a **reachability
   rule** (a K `claim`) over a minimal K semantics of the language fragment the
   code uses (see §7), following the `examples/sum` template.
4. **Specify each loop** — derive the loop **invariant / circularity** claim.
5. **Write artifacts** next to the code (`<mod>.k` semantics + `<mod>-spec.k`
   claims + a human-readable spec note).
6. **Report recommendations** (non-blocking) — e.g. *missing side condition*
   (`n ≥ 0`), spec doesn't cover the whole input space, possible non-termination,
   undefined/edge behavior. The kit aims for specs that cover the entire input
   space and flags gaps as suggestions.

## 6. `/verify` workflow (MVP: does NOT call the toolchain)

1. Ensure specs exist (run `/formalize` first if missing).
2. **Construct the proof** — symbolic execution + circularity discharge + arithmetic
   VCs, faithful to the K semantics — i.e. *verify enough to say so*.
3. **Emit artifacts** — the proof write-up, the `.k` claim/semantics files, and the
   exact `kompile`/`kprove` commands to machine-check later, clearly labeled
   **"constructed, not machine-checked."**
4. **Report** — what's proved, residual risk (partial vs total correctness, trusted
   base), and anything that did not go through.

> **Decision (supersedes the earlier auto-detect choice):** the MVP does **not**
> invoke `kompile`/`kprove`. Actually running the toolchain (auto-detect: run if
> present, else emit artifacts) is deferred to a later version.

## 7. Language semantics approach

**Ideal (long-term):** there should be a **complete K semantics for each
language** — a clear Python semantics in K, a TypeScript semantics in K, etc.
Each is its own project, and the K ecosystem already maintains many full
language-semantics repositories. The kit should ultimately target those complete
semantics, so the *literal* program is verified against the *real* language's
semantics (no fragment, no transliteration).

**MVP (this experiment):** generate a **minimal K semantics fragment for just the
constructs the code uses** (the "mini-X" approach, exactly as the `sum`
experiment built *mini Python*). This is a deliberate stopgap and **may change
very soon** — once full per-language semantics are wired in, the fragment step
goes away.

## 8. Scope & defaults

- **Any language** — via the fragment approach for the MVP (§7).
- **Partial correctness by default**; termination is surfaced as a
  *recommendation*, not proved unless asked.
- **Artifacts written alongside the code** in the project.
- **No-args** for both commands → operate on the whole current program / each
  function in it. (Targeted args for specific functions/blocks: later.)

## 9. Out of scope (MVP)

Agent-specific plugins/command formats; performance; deep IDE/editor integration;
fine-tuned-model packaging; full real-language K semantics; and **calling the
verification toolchain** (`kompile`/`kprove`). All deferred.

## 10. Success criteria

A user points their agent at the repo, runs `/formalize` then `/verify` on their
code, and gets — **without needing K installed** — formal specs (K reachability
claims) for each function and loop-invariant circularities, a constructed proof
plus the `.k` artifacts and run-commands, and a recommendations report. The repo
is clear enough to publicize and have strangers try.

## 11. Open questions (resolve before/at publish)

- Final repo name (`formal-verification-kit` is the working name).
- Which language(s) to seed `examples/` with beyond `sum` (Python).
- Future: argument forms for `/formalize`/`/verify` (target a function/block);
  native per-agent adapters; auto-running the toolchain; wiring full per-language
  K semantics.
