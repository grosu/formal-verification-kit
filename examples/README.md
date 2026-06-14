# Examples — a growing library of worked, formally specified & verified programs

Each example takes a real program from source code all the way to a **formal
specification** (K reachability claims), the **loop invariants / circularities**,
and a **constructed correctness proof** — including the plain-language *Findings*
and *test-redundancy* reports the kit produces.

These examples do double duty:

- **For people** — see exactly how `/formalize` and `/verify` work on a real
  function, file for file.
- **For the AI agents** — they are the templates an agent imitates to find specs
  and invariants in *new* code. The agent picks the closest example **by shape**
  (see the "what it demonstrates" column), not just the first one. And every
  vetted, machine-checked example is also a row in the eventual **fine-tuning
  corpus** for the product.

> The single most valuable way to grow the kit is to add examples that teach a
> **new shape** of reasoning — not more of the same. A second counting loop
> teaches an agent nothing new; a first *recursive* or *array* example teaches a
> whole new pattern. See **[How to add an example](#how-to-add-an-example)**.

## Source-program authenticity

The `.py` programs in these folders are deliberately preserved as the exact
**Claude Code Opus 4.8 (`opus-4-8`) vibe-coded outputs** from the prompts recorded in
each `PROMPTS.md`. They are not cleaned up inside this corpus. That is the point of
the showcase: these examples capture the FVK **audit/evidence phase** — missing
preconditions, underspecified behavior, proof obstacles, and next-iteration repair
guidance — before a coding agent consumes that evidence to repair the code. In normal
use, FVK absolutely feeds code repair; these examples freeze the pre-repair artifact
so readers can see what FVK discovered.

The 2026-06 protocol refresh standardized provenance only: every `SPEC.md` now has a
public intent ledger, and every nontrivial claim/circularity in `mini-python-spec.k`
has a `SPEC-PROVENANCE` comment tying the formal property back to the prompt, code,
Findings, proof scope, and explicit next repair iteration.

## Catalog

Examples are **numbered in increasing order of complexity** — simplest first, the
frontier last. Every program is **self-contained** (no libraries or builtins; see
[below](#programs-are-self-contained)).

| # | Example | What it demonstrates (shape / technique) | Status |
|---|---|---|---|
| 01 | [`01-average/`](01-average/) | Scalar over a list; a **running-sum loop invariant**; the **bug-finding showcase** (`average([])` → ZeroDivisionError). Self-contained sum (no `sum()`) keeps the VC definitional | constructed (escalation-bounded — only `listsum` totality) |
| 02 | [`02-sum-up/`](02-sum-up/) | Count-**up** loop; an **additive, polynomial** invariant + its circularity (`I ≤ N+1`); the `n < 0` missing-precondition *Finding* | constructed |
| 03 | [`03-sum-down/`](03-sum-down/) | Count-**down** loop; the **"remaining-work"** invariant — a genuinely different invariant shape, same result `n·(n+1)/2` | constructed |
| 04 | [`04-fibonacci/`](04-fibonacci/) | **Coupled accumulators** — an invariant relating *two* variables to consecutive `fib`; a spec-only recursive `fib` symbol (definitional step VC) | constructed (escalation-bounded — only `fib` totality) |
| 05 | [`05-gcd/`](05-gcd/) | Loop invariant is a **preserved relation** (`gcd(a,b)`), *not* an accumulator; clean termination (variant `b`); the Euclid identity escalates | constructed (escalation-bounded) |
| 06 | [`06-sum-recursive/`](06-sum-recursive/) | **Recursion** (no loop): the circularity is on the **recursive call's contract** `(REC)`; *validates* `n<0` (a **positive** Finding) | constructed |
| 07 | [`07-factorial/`](07-factorial/) | **Recursion + a non-polynomial result** — a spec-only recursive `fact` symbol; the VCs reduce to `fact`'s own defining equations (definitional, no halving lemma) | constructed (escalation-bounded — only `fact` totality) |
| 08 | [`08-is-even-odd/`](08-is-even-odd/) | **Mutual recursion** — the circularity spans **two** contracts `(EVEN)`/`(ODD)` that discharge *each other's* recursive call; **no escalation** | constructed |
| 09 | [`09-array-max/`](09-array-max/) | Arrays with a **∀-quantified** postcondition (upper-bound + membership) via a running-max invariant; a predicate over a list, **not** a multiset → **no escalation** | constructed |
| 10 | [`10-binary-search/`](10-binary-search/) | Arrays with a **sortedness precondition** (mirror of insertion-sort's postcondition) + a narrowing-window invariant; the famous `mid = (lo+hi)//2` overflow *Finding* | constructed (escalation-bounded — the not-present/membership half) |
| 11 | [`11-reverse/`](11-reverse/) | Arrays; an **index-relation** postcondition (clean) + **permutation** (escalates); in-place, O(n) — a simpler bridge to the multiset frontier | constructed (escalation-bounded — permutation) |
| 12 | [`12-insertion-sort/`](12-insertion-sort/) | **Arrays + nested loops + a relational spec** — a sorted **permutation** (`isSorted` + multiset `bag`); three nested circularities `(SORT)`/`(OUTER)`/`(INNER)`; the canonical **escalation boundary**, handled honestly | constructed (escalation-bounded) |
| 13 | [`13-tree-height/`](13-tree-height/) | **Recursive data structures** (a `Tree` value sort) — the frontier; a verified helper `(MAX2)` + a branching `(REC)`; the structural-induction principle escalates | constructed (escalation-bounded) |

**The `sum-*` cluster — one contract, many implementations.** `02-sum-up`,
`03-sum-down`, and `06-sum-recursive` all compute the *same* spec (`n·(n+1)/2`) — by
counting up, by counting down, and by **recursion** — yet **the proof obligations
differ even though the contract does not** (loop invariant vs. loop invariant vs.
*recursive-call contract*). That contrast is the teaching payload — see each
example's `README.md`.

*Roadmap — the remaining frontier is **machine-checking**: the inductive obligations
that the escalation-bounded examples state honestly (the multiset / sortedness VCs in
`11-reverse` and `12-insertion-sort`, the structural induction in `13-tree-height`,
and the spec-symbol totalities in `01`/`04`/`07`) need an inductive list/multiset/
datatype theory plus a `kprove` run — see each example's `[ESCALATION BOUNDARY]`
markers and `knowledge/sources.md`.*

## Programs are self-contained

Every example program uses **no imports and no high-level builtins** (`sum`, `max`,
`min`, `sorted`, slicing, `.insert`/`.append`, `list()`): only operators, indexing,
`len`, `while`/`if`, assignment, and its **own helper functions**. List-transformers
(`11-reverse`, `12-insertion-sort`) operate **in place**.

This is a deliberate verification choice, not a style preference: a builtin is an
**unspecified black box** (or forces a spec-only fold that escalates — compare
`01-average`'s clean loop sum to the `sum()` version it replaced). When every function
is written out, **every function gets its own reachability rule** — more specification,
more verified surface, more places to catch a bug — and the mini-X semantics stays
minimal. A self-contained helper like `13-tree-height`'s `max2` earns its own `(MAX2)`
contract.

## Anatomy of an example

Every example folder follows the same layout, so humans and agents can navigate
any of them the same way:

| File | Stage | What it is |
|---|---|---|
| the program (e.g. `average.py`) | — | the actual source code being verified (self-contained) |
| `mini-<lang>.k` (e.g. `mini-python.k`) | `/formalize` | a **minimal K semantics** of just the constructs the program uses (the "mini-X" fragment) |
| `<name>-spec.k` (e.g. `mini-python-spec.k`) | `/formalize` | the **K `claim`s** — the function contract (`φ_pre ⇒ φ_post`) and each loop's circularity |
| `SPEC.md` | `/formalize` | plain-English spec note plus the public intent ledger / provenance for each obligation (for a reader who never opens the `.k` files) |
| `FINDINGS.md` | `/formalize` | plain-language **Findings** — bugs / missing preconditions / corner cases (benefit 2) |
| `PROOF.md` | `/verify` | the **constructed proof**, proof-derived Findings / next-iteration feedback, and the **test-redundancy** recommendation (benefit 1) |
| `README.md` | — | one-paragraph summary + the example's status |
| `PROMPTS.md` | — | the exact prompts that reproduce the example with the kit |

The file set maps to the two commands: **`/formalize`** produces the semantics, the
claims, `SPEC.md`, and `FINDINGS.md`; **`/verify`** produces `PROOF.md`.

## How examples are produced (and why)

Examples here are produced by an **isolated newcomer**, *not* by someone who already
knows the kit:

1. In a **separate project**, a fresh coding agent — ideally one that has never seen
   this kit — writes the program *its own way* (self-contained, no libraries).
2. **Only then** is that agent pointed at this kit, asked to learn it, and asked to
   `/formalize` and `/verify` the code it just wrote.
3. If that goes through cleanly, the example is brought in here.

**Why this way — it is a deliberate guard against overfitting:**

- It mirrors the **real use case.** Developers build in isolation and bring the kit
  in *at the end* to catch errors. Examples produced that way are honest evidence
  the kit works on code it didn't grow up with.
- Each cold run is a **usability test of the kit itself.** Where the fresh agent
  stalls, misreads [`AGENTS.md`](../AGENTS.md), or can't formalize some construct,
  that is a **bug in the kit** — and it only surfaces when no expert context is
  there to paper over it. Capture those frictions; they are the kit's real backlog.
- It keeps the library **diverse.** Examples built by one person/agent with full
  context drift toward looking identical — which overfits both human readers and
  the agents that learn from them. **Vary the producing agent/model** when you can.

**Promotion discipline — *uniform skeleton, authentic content*.** When an example is
brought in, standardize only the **skeleton** so the catalog and a navigating agent
can rely on it: the [file layout](#anatomy-of-an-example), the catalog row, the
status label, fixing broken links, public-intent ledgers, claim-provenance comments,
and a correctness sanity-check of the claims. **Do not rewrite or repair the `.py`
source program**, and do not rewrite the producer's voice, findings, or proof into a
house style — that re-introduces the very homogeneity this process exists to avoid.

*(Heads-up: the `02-sum-up` / `03-sum-down` cluster predates this discipline and was
deliberately cross-normalized, so it is more uniform than later examples should be.)*

## How to add an example

1. **Target a new shape.** Pick a program whose invariant / VC pattern is *not*
   already covered by an example in the catalog. Diversity of shape beats quantity.
2. **Keep it self-contained.** No imports, no high-level builtins — see
   [above](#programs-are-self-contained).
3. **Copy the layout** above (use [`02-sum-up/`](02-sum-up/) as the model).
4. **Vet for correctness.** A wrong example is worse than no example — agents
   imitate it and reproduce the mistake. Review the spec and proof carefully.
5. **Prefer machine-checked.** If you can run K, machine-check it (`kompile` +
   `kprove` → `#Top`) and mark it so.
6. **Label the status** honestly in the catalog row and the example's `README.md`,
   and **insert it at the right complexity position** (renumber if needed).

## Status legend

- **machine-checked** — `kprove` returned `#Top`; the proof is verified by the K
  toolchain.
- **constructed** — the proof is written and reviewed but **not** yet machine-checked
  (this is the kit's MVP default; see the repo [`README.md`](../README.md)).
- **constructed (escalation-bounded)** — *doubly* short of machine-checked: beyond not
  running `kprove`, some VCs need a theory the bundled simplification tier lacks (an
  inductive list/multiset/datatype theory, number theory, or a spec-symbol totality),
  so they are stated as explicit `[ESCALATION BOUNDARY]` obligations rather than
  discharged or faked `[trusted]`. The catalog row notes *what* escalates.
