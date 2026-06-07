# Formal Verification Kit (MVP) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a provider-neutral, public Git repo of plain-markdown files that lets any coding agent run `/formalize` and `/verify` to add K/matching-logic specs to code, construct a correctness proof, recommend redundant tests, and report likely bugs.

**Architecture:** No agent-specific wiring. `AGENTS.md` is the universal entrypoint that defines the `/formalize` and `/verify` triggers and tells the agent to read `knowledge/` first (the bundled "learning"). `commands/*.md` hold the two workflows. `knowledge/*.md` hold the distilled K + matching-logic + technique references (read on load; optional live refresh from `sources.md`). `examples/sum-up/` is the worked template the agent imitates.

**Tech Stack:** Plain Markdown only. The example reuses the K artifacts from the `formally-verified-sum` repo (`/home/openclaw/k-bridge`). No build system; "tests" are self-contained-ness and cross-reference checks.

**Repo root:** `/home/openclaw/formal-verification-kit/`

---

## File Structure

| File | Responsibility |
|---|---|
| `LICENSE` | MIT license (permissive, for public sharing) |
| `knowledge/matching-logic.md` | distilled matching logic: patterns-as-sets, definedness ladder, μ, proof system |
| `knowledge/k-framework.md` | distilled K: config cells, rules, seqstrict/heating, `claim`s, `kprove`, simplifications, the Lesson 1.22 pattern, `/Int` |
| `knowledge/reachability-and-circularities.md` | reachability logic, the Circularity rule, coinductive invariants, the proof recipe, VC discharge |
| `knowledge/sources.md` | links to the papers / matching-logic.org / K docs for `--refresh` |
| `examples/sum-up/` | the worked `sum` example (program + `mini-python.k` + spec + proof note + README) — the imitation template |
| `commands/formalize.md` | the `/formalize` workflow (agent-agnostic) |
| `commands/verify.md` | the `/verify` workflow (agent-agnostic) |
| `AGENTS.md` | universal entrypoint: bootstrap + trigger definitions |
| `README.md` | the pitch / how to try it / vision (publicize-ready) |

`knowledge/*.md` (Tasks 2–5) are mutually independent and SHOULD be fanned out in parallel. `examples/sum-up` (Task 6) is independent. `commands/*` (Tasks 7–8) reference knowledge + example. `AGENTS.md` (Task 9) references commands + knowledge. `README.md` (Task 10) references everything. Build in roughly this order.

**Source material on disk (reuse, do not re-derive):**
- `/home/openclaw/k-bridge/summation.py`, `mini-python.k`, `mini-python-spec.k`, `sum-verification.md`, `sum-correctness-proof.md` — the verified example.
- `/home/openclaw/.claude/projects/-home-openclaw-k-bridge/memory/` — `matching-logic-corpus.md`, `k-verification-model.md` (distilled facts + correct citations).
- `/tmp/kdocs/` — `L22_proofs.md`, `user_manual.md` (K reference; cite line areas).

---

## Task 1: Repo scaffolding

**Files:**
- Create: `LICENSE`
- Create: directory layout (`knowledge/`, `commands/`, `examples/sum-up/`)

- [ ] **Step 1: Create the MIT LICENSE**

Write `LICENSE` with the standard MIT text, `Copyright (c) 2026 Grigore Rosu`.

- [ ] **Step 2: Create empty directories with `.gitkeep` if needed**

`knowledge/`, `commands/`, `examples/sum-up/` (they will be filled by later tasks; no `.gitkeep` needed once files land).

- [ ] **Step 3: Commit**

```bash
cd /home/openclaw/formal-verification-kit
git add LICENSE
git commit -m "Add MIT license"
```

---

## Task 2: `knowledge/matching-logic.md`

**Files:**
- Create: `knowledge/matching-logic.md`

**Responsibility:** a tight, self-contained primer an agent reads to "know" matching logic. Distilled from this session's synthesis + the memory file `matching-logic-corpus.md`.

- [ ] **Step 1: Write the file** with these sections (each a few sentences + notation, not a paper):
  - **One-line model:** a *pattern* denotes the **set of elements that match it** (`|φ| ⊆ M`), unifying terms and formulas.
  - **Connectives as set ops:** `⊥=∅`, `⊤=M`, `∧=∩`, `¬=complement`, `∨=∪`, `∃=union over witnesses`, `→` accordingly.
  - **Symbols** interpreted into the powerset; application extended pointwise; functions/partial-functions/relations as special cases.
  - **Definedness ladder (all *derived*, not primitive):** `⌈_⌉` with axiom `⌈x⌉=⊤`; totality `⌊φ⌋≡¬⌈¬φ⌉`; equality `φ₁=φ₂≡⌊φ₁↔φ₂⌋` (two-valued — FOL `↔` can't be); membership `x∈φ≡⌈x∧φ⌉`; sorts via an inhabitant symbol `⟦s⟧`.
  - **μ (matching μ-logic):** set variables + least fixpoint `μX.φ` (positivity ⇒ monotone ⇒ Knaster–Tarski); `ν` derived. This is what gives induction/recursion/reachability.
  - **Proof system (names only):** propositional + Modus Ponens; `∃`-quantifier/generalization; Frame/Propagation; **Pre-Fixpoint** + **Knaster–Tarski (induction)**.
  - **What it unifies:** FOL(+LFP), modal/temporal logics, separation logic, reachability logic, λ/type systems — as *theories*, not logic extensions.
  - **Why it matters for K:** K's `claim`s/configurations are matching-logic formulas; `#And/#Or/#Equals/#Not/#Exists` are its connectives.
  - Cross-link: "for the proof technique see `reachability-and-circularities.md`; for citations see `sources.md`."

- [ ] **Step 2: Self-check** — file is standalone, uses correct notation, has no dangling references. Verify the equality/definedness facts match `sources.md` citations (Rosu 2017 LMCS; Chen–Rosu 2019 LICS).

- [ ] **Step 3: Commit**

```bash
git add knowledge/matching-logic.md
git commit -m "knowledge: distilled matching logic primer"
```

---

## Task 3: `knowledge/k-framework.md`

**Files:**
- Create: `knowledge/k-framework.md`

**Responsibility:** how to actually write a K definition and a `kprove` claim. Distilled from `k-verification-model.md` + `/tmp/kdocs/`.

- [ ] **Step 1: Write the file** with:
  - **What K is:** rewrite-based executable semantics; `kompile` / `krun` / `kprove` (Haskell backend for proofs; Z3 for feasibility).
  - **Definition shape:** `module X-SYNTAX` (BNF `syntax` with `strict`/`seqstrict`/`left`/`bracket`/`token`, and `syntax KResult ::= ...`) + `module X` with a `configuration` of cells and `rule`s using `=>` and `~>`, `requires`. Builtins `INT` (`+Int`, `<=Int`, `/Int` truncates toward zero), `BOOL`, `MAP` (`M[K <- V]`, `K |-> V`), `LIST`.
  - **Strictness ⇒ heating/cooling:** `seqstrict` auto-generates `[heat]`/`[cool]` rules with `isKResult(HOLE)` side conditions — this is the small-step stepping.
  - **Claims:** spec module (`requires "sem.k"`; a `VERIFICATION` module importing `MAP-SYMBOLIC`, `K-EQUAL`); a claim is `<k> LHS => RHS ...</k>` with store `x |-> (OLD => NEW)`, `requires` (pre), `ensures` (post, `?`-existentials), `[all-path]`/`[one-path]`.
  - **Circularities:** every claim is a coinduction hypothesis (a loop claim discharges itself); `[trusted]` = assume as proven; `[simplification]` rules = user lemmas to discharge arithmetic/map side conditions (the VC oracle).
  - **The Lesson 1.22 pattern (cite):** config `<k>/<store>/<funcs>/<stack>`; assignment/`if`/`while`/`def`/`return`/call; loop-invariant claim + function claim, proved by `kprove` → `#Top`. Note the `Bot`/`Bots` shared-`klabel` list trick for evaluated args (a `KResult` subsort of the arg list).
  - **Common gotchas (from the sum build):** list-sort/`KResult` subsorting (FIX-1); statement-sequencing parse ambiguity vs suite priority (FIX-2); map-extensionality `[simplification]` (FIX-3); exact-halving `[simplification]` when dividing a symbolic product (FIX-4).
  - Cross-link to `examples/sum-up/mini-python.k` and `mini-python-spec.k` as a concrete instance; `sources.md` for the manual/tutorial.

- [ ] **Step 2: Self-check** — every claimed K feature matches the user manual / Lesson 1.22; gotchas match the example files.

- [ ] **Step 3: Commit**

```bash
git add knowledge/k-framework.md
git commit -m "knowledge: distilled K-framework + kprove reference"
```

---

## Task 4: `knowledge/reachability-and-circularities.md`

**Files:**
- Create: `knowledge/reachability-and-circularities.md`

**Responsibility:** the proof technique and the recipe the workflows follow.

- [ ] **Step 1: Write the file** with:
  - **Reachability rule:** `φ ⇒ φ'` between configuration patterns generalizes a Hoare triple; one operational semantics serves both execution and proof.
  - **Proof system:** Reflexivity, Axiom (+framing), Transitivity, Consequence (FOL/SMT side conditions), Case Analysis, Abstraction, **Circularity**.
  - **Circularity rule (the key):** `A ∪ {φ⇒φ'} ⊢ φ⇒φ'  ⟹  A ⊢ φ⇒φ'`, **provided** the hypothesis is used only after ≥1 genuine `=>+` step (guarded coinduction). This replaces the loop invariant: the loop's own reachability claim is the coinductive hypothesis.
  - **The recipe (how `/formalize` + `/verify` proceed):**
    1. Build/obtain a K semantics of the language fragment (mini-X) — see `k-framework.md`.
    2. State the function spec as a reachability rule (`φ_pre ⇒ φ_post`).
    3. For each loop, state the loop-invariant circularity claim (generalize over the accumulator/counter; include the side condition that makes it sound, e.g. `I ≤ N+1`).
    4. Prove: symbolic execution (heating/cooling + semantic rules), case split on the loop guard (the two while/`if` branches), invoke the circularity after the body step, discharge arithmetic VCs (Z3 / `[simplification]`).
    5. Compose function-level via Transitivity (def → call → loop-via-circularity → return).
  - **Partial vs total correctness:** circularity gives *partial* correctness (soundness without a variant). Total correctness needs a decreasing measure — flag as a recommendation, don't do unless asked.
  - **VC discharge:** linear facts → Z3; nonlinear/division-by-even → `[simplification]` lemmas (VC-EXACT etc.).
  - Cross-link to `examples/sum-up/` (the loop circularity `I ≤ N+1` and the function contract) and `sources.md` (FM 2012, LICS 2013).

- [ ] **Step 2: Self-check** — the recipe matches what the `sum` example actually did; the Circularity statement and guardedness proviso are correct.

- [ ] **Step 3: Commit**

```bash
git add knowledge/reachability-and-circularities.md
git commit -m "knowledge: reachability logic, circularities, the proof recipe"
```

---

## Task 5: `knowledge/sources.md`

**Files:**
- Create: `knowledge/sources.md`

**Responsibility:** the live-source index for `--refresh` and citations.

- [ ] **Step 1: Write the file** listing, with URLs:
  - matching-logic.org (note: TLS cert altname is broken — use `curl -sk`, WebFetch fails).
  - Papers (fsl.cs.illinois.edu/publications/`<slug>.pdf`): `rosu-2017-lmcs` (Matching Logic), `chen-rosu-2019-lics` (Matching μ-Logic), `chen-lucanu-rosu-2020-tr` (Initial Algebra Semantics), `rosu-stefanescu-2012-fm`, `rosu-stefanescu-ciobaca-moore-2013-lics` (reachability).
  - K: github.com/runtimeverification/k; `docs/user_manual.md`; `k-distribution/k-tutorial/1_basic/22_proofs` (Lesson 1.22 — the canonical sum proof); kframework.org.
  - One line each on what to pull on `--refresh`.

- [ ] **Step 2: Self-check** — every cross-reference in the other knowledge files resolves to an entry here.

- [ ] **Step 3: Commit**

```bash
git add knowledge/sources.md
git commit -m "knowledge: source index for citations and --refresh"
```

---

## Task 6: `examples/sum-up/` (the worked template)

**Files:**
- Create: `examples/sum-up/summation.py` (copy of `/home/openclaw/k-bridge/summation.py`)
- Create: `examples/sum-up/mini-python.k` (copy of `/home/openclaw/k-bridge/mini-python.k`)
- Create: `examples/sum-up/mini-python-spec.k` (copy of `/home/openclaw/k-bridge/mini-python-spec.k`)
- Create: `examples/sum-up/PROOF.md` (condensed proof + findings + test-redundancy illustration)
- Create: `examples/sum-up/README.md` (what this example demonstrates + pointer to full write-up)

- [ ] **Step 1: Copy the three real artifacts**

```bash
cd /home/openclaw/formal-verification-kit
cp /home/openclaw/k-bridge/summation.py examples/sum-up/summation.py
cp /home/openclaw/k-bridge/mini-python.k examples/sum-up/mini-python.k
cp /home/openclaw/k-bridge/mini-python-spec.k examples/sum-up/mini-python-spec.k
```

- [ ] **Step 2: Write `examples/sum-up/PROOF.md`** — a condensed version of `/home/openclaw/k-bridge/sum-verification.md`: the reachability spec (SUM claim), the loop circularity (LOOP claim, `I ≤ N+1`), the informal proof, and the machine-detailed proof sketch. ALSO add a short worked instance of each user benefit: a **Findings** snippet (the `n < 0` missing-case: code returns 0 but `N(N+1)/2` ≠ 0 — recommend a precondition or a sign split) and a **Test-redundancy** snippet (the verified spec subsumes the `test_sums_one_to_n`/`test_sum_of_one` cases within `n ≥ 0`; keep the `n ≤ 0` test since it's the boundary/out-of-spec case).

- [ ] **Step 3: Write `examples/sum-up/README.md`** — 1 paragraph: this is the template `/formalize` and `/verify` imitate; lists the files; links to PROOF.md and to the upstream full write-up repo `formally-verified-sum`.

- [ ] **Step 4: Self-check** — the copied `.k` files are byte-identical to source; PROOF.md's claims match `mini-python-spec.k` exactly (same loop body term, same `I ≤ N+1`, same `N*(N+1)/2`).

- [ ] **Step 5: Commit**

```bash
git add examples/sum-up/
git commit -m "examples: the worked sum template (program, semantics, spec, proof, findings)"
```

---

## Task 7: `commands/formalize.md`

**Files:**
- Create: `commands/formalize.md`

**Responsibility:** the agent-agnostic `/formalize` workflow (spec §5).

- [ ] **Step 1: Write the file** as an ordered instruction list an agent follows, no-args = whole program / each function:
  1. **Learn** — read `knowledge/matching-logic.md`, `k-framework.md`, `reachability-and-circularities.md` if not already internalized. (`--refresh` ⇒ also pull `sources.md` live.)
  2. **Read the target** — enumerate functions and loops; infer intent from code + names + docstrings + tests.
  3. **Semantics** — build a minimal K semantics of the language fragment used (mini-X), imitating `examples/sum-up/mini-python.k`. (Note: the long-term path is a full per-language K semantics; the fragment is an MVP stopgap.)
  4. **Specify each function** — a reachability rule (`φ_pre ⇒ φ_post`) as a K `claim`, imitating `examples/sum-up/mini-python-spec.k`.
  5. **Specify each loop** — a loop-invariant circularity claim, generalized over accumulator/counter, with the soundness side condition.
  6. **Write artifacts** alongside the code: `<mod>.k`, `<mod>-spec.k`, and a human-readable spec note.
  7. **Findings report** (first-class, plain language, `input → observed vs expected`): missing preconditions/side conditions; forgotten corner cases (empty/zero/negative/boundary/overflow/off-by-one); undefined or intent-contradicting behavior; non-universal postconditions; dead code. **Spec-difficulty = bug signal:** if a clean spec is hard/impossible, say so and explain what's suspicious.
  - Include the `sum` `n ≥ 0` discovery as a concrete worked example of the Findings report.
  - State output contract: artifacts + Findings report; non-blocking.

- [ ] **Step 2: Self-check** — every step is concrete and references real files (`examples/sum-up/*`, `knowledge/*`); matches spec §5 and §1.1 benefit #2.

- [ ] **Step 3: Commit**

```bash
git add commands/formalize.md
git commit -m "commands: /formalize workflow"
```

---

## Task 8: `commands/verify.md`

**Files:**
- Create: `commands/verify.md`

**Responsibility:** the agent-agnostic `/verify` workflow (spec §6).

- [ ] **Step 1: Write the file** as an ordered instruction list:
  1. Ensure specs exist (run `/formalize` first if missing).
  2. **Construct the proof** — symbolic execution + circularity discharge + arithmetic VCs, faithful to the K semantics (per `reachability-and-circularities.md`).
  3. **Test-redundancy report** (benefit #1) — map existing tests to the verified spec; flag those entailed by what was proved *within the verified domain*; recommend removal + CI-time saved; KEEP out-of-domain (e.g. `n < 0`), termination, performance, integration tests; recommendation-only, never auto-delete.
  4. **Emit artifacts** — proof write-up, `.k` files, exact `kompile`/`kprove` commands, labeled **"constructed, not machine-checked."**
  5. **Report** — what's proved, residual risk (partial vs total; trusted base), the test-redundancy recommendation, and — if verification fails/gets stuck — surface that as a strong bug signal feeding the Findings report.
  - **Honesty gate (verbatim intent):** MVP does NOT run `kprove`; test removal is *conditioned on machine-checking* — advise running the emitted commands first or keeping tests until then; never claim unproven confidence.
  - Reference `examples/sum-up/PROOF.md` test-redundancy snippet as the worked example.

- [ ] **Step 2: Self-check** — matches spec §6 incl. the honesty gate and §1.1 benefit #1; no step implies running the toolchain.

- [ ] **Step 3: Commit**

```bash
git add commands/verify.md
git commit -m "commands: /verify workflow"
```

---

## Task 9: `AGENTS.md`

**Files:**
- Create: `AGENTS.md`

**Responsibility:** the universal entrypoint any agent reads.

- [ ] **Step 1: Write the file** with:
  - 2-sentence "what this is."
  - **Bootstrap:** "Before using these commands, read `knowledge/matching-logic.md`, `knowledge/k-framework.md`, and `knowledge/reachability-and-circularities.md`. This is the one-time 'learn K + matching logic' step."
  - **Triggers:** "When the user says `/formalize`, follow `commands/formalize.md`. When the user says `/verify`, follow `commands/verify.md`. (No arguments yet → operate on the whole project / each function.)"
  - **Template:** "Imitate `examples/sum-up/`."
  - One line that this is provider-neutral (any agent that reads `AGENTS.md` works).

- [ ] **Step 2: Self-check** — every referenced path exists (Tasks 2–8 done); triggers and bootstrap match the spec.

- [ ] **Step 3: Commit**

```bash
git add AGENTS.md
git commit -m "Add AGENTS.md universal entrypoint (/formalize, /verify triggers + bootstrap)"
```

---

## Task 10: `README.md`

**Files:**
- Create: `README.md`

**Responsibility:** the publicize-ready pitch.

- [ ] **Step 1: Write the file** with:
  - **Headline + the two benefits FIRST** (§1.1): (1) fewer tests / faster CI; (2) finds hidden subtle bugs — explicitly "even if you don't know what formal verification is."
  - **What it is / how to try it:** point your agent at this repo (it reads `AGENTS.md`), then say `/formalize` and `/verify` on your code. Works with any agent that reads `AGENTS.md`.
  - **What you get:** formal specs (K reachability claims) per function + loop-invariant circularities; a constructed proof + `.k` artifacts + run-commands; a Findings report; a test-redundancy recommendation.
  - **Honest status:** MVP — constructs proofs but does not run `kprove` yet (commands to do so are emitted); fragment K semantics per code (full per-language semantics is the roadmap); partial correctness.
  - **The vision:** the fine-tuned-model end state (one line in → verified program out); link to the `formally-verified-sum` example repo.
  - **Layout** table + license.

- [ ] **Step 2: Self-check** — benefits lead; status is honest; all internal links resolve.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "Add README: the pitch, the two benefits, how to try it, the vision"
```

---

## Task 11: Cross-reference + dry-run review, then finalize

**Files:**
- Modify: any file with a broken cross-reference found below.

- [ ] **Step 1: Link audit** — grep every markdown file for relative links/paths and confirm each target exists.

```bash
cd /home/openclaw/formal-verification-kit
grep -rnoE '\]\([^)]+\)|`(knowledge|commands|examples)/[^`]+`' --include='*.md' . | sort -u
```
Fix any dangling reference.

- [ ] **Step 2: Dry-run the workflow on the example** — read `AGENTS.md` → `commands/formalize.md` → `commands/verify.md` as if an agent with zero prior context, against `examples/sum-up/`. Confirm an agent could reproduce the example's spec + Findings + test-redundancy report from these instructions alone. Note/fix any gap.

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "Finalize MVP kit: link audit + dry-run review"
```

- [ ] **Step 4: Publishing (separate, user-authorized)** — do NOT push without the user's go-ahead. When approved: confirm final repo name, `gh repo create <name> --public --source=. --remote=origin --push` under `grosu`, author `Grigore Rosu <grosu@illinois.edu>`.

---

## Self-Review (run before handing off)

- **Spec coverage:** §1.1 benefits → README Task 10 + Findings (Task 7) + test-redundancy (Task 8). §2 packaging → Tasks 9/1. §3 layout → all tasks. §4 knowledge delivery → Tasks 2–5 + `--refresh` in Tasks 7/8. §5 `/formalize` → Task 7. §6 `/verify` + honesty gate → Task 8. §7 semantics approach → Tasks 3/7. §8 defaults → Tasks 7/8/9. §9 out-of-scope → respected (no toolchain calls, no per-agent files). §10 success → Tasks 10/11. §11 examples=sum → Task 6. ✅ All covered.
- **Placeholders:** none — each task names exact files and concrete content.
- **Consistency:** command names `/formalize` `/verify`; file names `mini-python.k` / `mini-python-spec.k`; the `n ≥ 0` finding and `I ≤ N+1` circularity are used identically across Tasks 6/7/8.
