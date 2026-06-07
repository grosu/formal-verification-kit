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

## Catalog

| Example | Language | What it demonstrates (shape / technique) | Status |
|---|---|---|---|
| [`sum-up/`](sum-up/) | Python | Count-**up** loop (`i` from `1` to `n`); **additive, polynomial** loop invariant + its circularity (`I ≤ N+1`); the `n < 0` missing-precondition *Finding* | constructed |
| [`sum-down/`](sum-down/) | Python | Count-**down** loop; the **"remaining-work"** invariant (`I ≥ 0`) — same result `n·(n+1)/2`, a genuinely **different invariant shape** than `sum-up` (`n` drops out of the loop spec; no init VC; only one live simplification) | constructed |
| [`sum-recursive/`](sum-recursive/) | Python | **Recursion** (no loop): the circularity is on the **recursive call's contract** `(REC)` — same result `n·(n+1)/2`. Uses `if`/`==`; *validates* `n<0` (a **positive** Finding — it fixes the loops' silent bug); plus a measured `RecursionError` depth-limit Finding | constructed |

**The `sum-*` cluster — one contract, many implementations.** `sum-up`, `sum-down`,
and `sum-recursive` all compute the *same* spec (`n·(n+1)/2`) — by counting up, by
counting down, and by **recursion** — yet **the proof obligations differ even though
the contract does not** (loop invariant vs. loop invariant vs. *recursive-call
contract*). That contrast is the teaching payload — see each example's `README.md`.

*Other roadmap shapes worth adding next (each a new pattern): a **product /
factorial** (non-polynomial, multiplicative VC) and an **array / list loop** (sum /
max / search over a sequence).*

## Anatomy of an example

Every example folder follows the same layout, so humans and agents can navigate
any of them the same way:

| File | Stage | What it is |
|---|---|---|
| the program (e.g. `sum.py`) | — | the actual source code being verified |
| `mini-<lang>.k` (e.g. `mini-python.k`) | `/formalize` | a **minimal K semantics** of just the constructs the program uses (the "mini-X" fragment) |
| `<name>-spec.k` (e.g. `mini-python-spec.k`) | `/formalize` | the **K `claim`s** — the function contract (`φ_pre ⇒ φ_post`) and each loop's circularity |
| `SPEC.md` | `/formalize` | plain-English spec note (for a reader who never opens the `.k` files) |
| `FINDINGS.md` | `/formalize` | plain-language **Findings** — bugs / missing preconditions / corner cases (benefit 2) |
| `PROOF.md` | `/verify` | the **constructed proof** + the **test-redundancy** recommendation (benefit 1) |
| `README.md` | — | one-paragraph summary + the example's status |
| `PROMPTS.md` | — | the exact prompts that reproduce the example with the kit |

The file set maps to the two commands: **`/formalize`** produces the semantics, the
claims, `SPEC.md`, and `FINDINGS.md`; **`/verify`** produces `PROOF.md`.

## How examples are produced (and why)

Examples here are produced by an **isolated newcomer**, *not* by someone who already
knows the kit:

1. In a **separate project**, a fresh coding agent — ideally one that has never seen
   this kit — writes the program *its own way* (its own style, its own packages).
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
  there to paper over it. Capture those frictions; they are the kit's real backlog
  (the factorial gap was found exactly this way).
- It keeps the library **diverse.** Examples built by one person/agent with full
  context drift toward looking identical — which overfits both human readers and
  the agents that learn from them. **Vary the producing agent/model** when you can.

**Promotion discipline — *uniform skeleton, authentic content*.** When an example is
brought in, standardize only the **skeleton** so the catalog and a navigating agent
can rely on it: the [file layout](#anatomy-of-an-example), the catalog row, the
status label, fixing broken links, and a correctness sanity-check of the claims. **Do
not** rewrite the producer's voice, findings, or proof into a house style — that
re-introduces the very homogeneity this process exists to avoid. The content should
stay as the isolated session produced it.

*(Heads-up: the `sum-up` / `sum-down` cluster predates this discipline and was
deliberately cross-normalized, so it is more uniform than later examples should be.)*

## How to add an example

1. **Target a new shape.** Pick a program whose invariant / VC pattern is *not*
   already covered by an example in the catalog. Diversity of shape beats quantity.
2. **Copy the layout** above (use [`sum-up/`](sum-up/) as the model).
3. **Vet for correctness.** A wrong example is worse than no example — agents
   imitate it and reproduce the mistake. Review the spec and proof carefully.
4. **Prefer machine-checked.** If you can run K, machine-check it (`kompile` +
   `kprove` → `#Top`) and mark it so. A machine-checked example is trustworthy for
   both humans and the fine-tuning corpus.
5. **Label the status** honestly in the catalog row and the example's `README.md`.
6. **Add a catalog row** to the table above: example, language, the *shape* it
   demonstrates, and status.

## Status legend

- **machine-checked** — `kprove` returned `#Top`; the proof is verified by the K
  toolchain.
- **constructed** — the proof is written and reviewed but **not** yet machine-checked
  (this is the kit's MVP default; see the repo [`README.md`](../README.md)).
