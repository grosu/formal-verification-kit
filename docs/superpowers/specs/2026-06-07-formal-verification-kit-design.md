# Formal Verification Kit — Design (MVP)

- **Date:** 2026-06-07
- **Status:** approved (brainstorming), pending spec review → implementation plan
- **Working name:** `formal-verification-kit` (final name TBC before publishing)

## 1. Purpose & vision

Turn the spec-and-verify process discovered in the `sum_to_n(n)` experiment
(the `sum` example) into a **reusable, provider-neutral kit** that any
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

### 1.1 The two headline benefits (delivered even to users who don't know formal verification)

Most users will not know or care what "formal verification" is. The kit must
deliver value to them anyway — for free. These two benefits, **not** the proof
itself, are what we lead with in the README and what we optimize the reports for:

1. **Fewer tests, faster CI.** A formally verified function is proven correct for
   *all* inputs in its specified domain, so the unit tests that merely check
   input/output cases already covered by the verified spec become redundant.
   After a successful `/verify`, the kit reports exactly which tests are subsumed
   and recommends removing them, noting the CI time saved. (Conservative,
   recommendation-only; conditioned on machine-checking — see §6.)
2. **Finds hidden, subtle bugs.** Trying to formalize code routinely uncovers
   missing preconditions, forgotten corner cases, and undefined behavior — and,
   crucially, **difficulty or inability to write a clean specification is itself a
   strong signal that the code has a bug or a forgotten case.** Both commands
   surface these as a plain-language **Findings report** that is valuable even to
   someone who never reads the proof. This is the primary day-one value for
   non-expert users.

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
   code uses (see §7), following the `examples/02-sum-up` template.
4. **Specify each loop** — derive the loop **invariant / circularity** claim.
5. **Write artifacts** next to the code (`mini-<lang>.k` semantics + `<program>-spec.k`
   claims + a human-readable spec note).
6. **Produce the Findings report** (a first-class output; non-blocking) — in plain
   language for any developer, each finding with a concrete example (`input →
   observed vs expected`). Report: missing preconditions / side conditions (e.g.
   `n ≥ 0`); forgotten corner cases (empty / zero / negative / boundary / overflow
   / off-by-one); inputs where behavior is undefined or contradicts the apparent
   intent; postconditions that don't hold universally; dead/unreachable code. The
   kit aims for specs that cover the entire input space and flags gaps as
   suggestions.

   **Spec-difficulty = bug signal.** Whenever a clean specification is hard or
   impossible to write — no clean precondition, a postcondition needing awkward
   case splits, a loop with no clean invariant — say so explicitly and explain
   what looks suspicious. That difficulty is usually a real code smell, and naming
   it is itself a deliverable (benefit #2 in §1.1).

## 6. `/verify` workflow (MVP: does NOT call the toolchain)

1. Ensure specs exist (run `/formalize` first if missing).
2. **Construct the proof** — symbolic execution + circularity discharge + arithmetic
   VCs, faithful to the K semantics — i.e. *verify enough to say so*.
3. **Test-redundancy report** (benefit #1) — map the existing tests to the verified
   spec and flag those whose assertions are **entailed by what was proved, within
   the verified domain**; recommend removing them, with the reasoning and an
   estimate of CI time saved. **Keep** tests outside the spec's domain (e.g.
   `n < 0`) and termination / performance / integration tests. Recommendation-only;
   **never auto-delete** (an opt-in `--apply` is a later option).
4. **Emit artifacts** — the proof write-up, the `.k` claim/semantics files, and the
   exact `kompile`/`kprove` commands to machine-check later, clearly labeled
   **"constructed, not machine-checked."**
5. **Report** — what's proved, residual risk (partial vs total correctness, trusted
   base), the test-redundancy recommendation, and — **if verification fails or gets
   stuck, surface that prominently as a strong bug signal** (it feeds the Findings
   report / benefit #2).

> **Honesty gate (test removal).** Because the MVP constructs the proof but does
> **not** run `kprove`, test removal is presented as a recommendation *conditioned
> on machine-checking*: the kit advises running the emitted `kompile`/`kprove`
> commands first, or keeping the tests until then. It never deletes tests and never
> claims confidence the (un-machine-checked) proof does not yet have. The Findings
> report (benefit #2) does **not** depend on machine-checking and is solid today.

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

Crucially, **a user who does not know what formal verification is still gets
concrete value without reading any proof**: the Findings report (potential bugs /
missing cases, §1.1 benefit #2) and, after `/verify`, the list of now-redundant
tests to drop (§1.1 benefit #1).

## 11. Open questions (resolve before/at publish)

- Final repo name (`formal-verification-kit` is the working name).
- Examples: **seed with the `sum` (Python) example only for now**; extend to more
  examples/languages later. (Resolved.)
- Future: argument forms for `/formalize`/`/verify` (target a function/block);
  an opt-in `--apply` to actually remove redundant tests; native per-agent
  adapters; auto-running the toolchain (which also enables *confident* test
  removal); wiring full per-language K semantics.

## 12. Roadmap — top item from the final review (the "growth lever")

The final whole-kit dry-run (factorial, `def fact(n): r=1; i=1; while i<=n: r*=i; i+=1`)
confirmed the limit we designed for: a fresh agent gets through the semantics and
the loop-invariant *shape* by imitation, then stalls because factorial's closed
form `N!/(I-1)!` is **non-polynomial**. The kit's VC toolbox (Z3 for linear facts +
the exact-halving `[simplification]`) is polynomial/division-by-2 specialized and
offers no transferable recipe for a multiplicative VC over a recursively-defined
symbol. The agent correctly hits the "spec-difficulty → escalate via `sources.md`"
off-ramp — but that off-ramp is a pointer to papers, not an operational path, so it
cannot *complete* the factorial proof from the kit alone.

**Highest-leverage next investment (matches §1.1(c), examples are the growth lever):**
add a second worked example with (a) a **recursively-defined postcondition symbol**
(e.g. `factorial`) declared in the semantics/spec module, and (b) a **non-halving
multiplicative `[simplification]` lemma**, so agents have a transferable pattern for
non-polynomial specs. A list-loop example (separation-logic-style heap reasoning) is
the natural third. These do more for capability than expanding the prose primers.
