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
| `sum-down/` *(coming)* | Python | Count-**down** loop; the **"remaining-work"** invariant — same result `n·(n+1)/2`, a genuinely **different invariant shape** than `sum-up` | coming |

*Roadmap shapes worth adding next (each a new pattern): a **product / factorial**
(non-polynomial, multiplicative VC), an **array/list loop** (sum/max/search over a
sequence), and a **recursive** function (gcd, fib).*

## Anatomy of an example

Every example folder follows the same layout, so humans and agents can navigate
any of them the same way:

| File | What it is |
|---|---|
| the program (e.g. `summation.py`) | the actual source code being verified |
| `mini-<lang>.k` (e.g. `mini-python.k`) | a **minimal K semantics** of just the language constructs the program uses (the "mini-X" fragment) |
| `<name>-spec.k` (e.g. `mini-python-spec.k`) | the **K `claim`s** — the function contract (`φ_pre ⇒ φ_post`) and each loop's circularity |
| `PROOF.md` | the **constructed proof** — the reachability spec, the circularity, an informal then machine-detailed proof, plus the **Findings** and **test-redundancy** sections |
| `README.md` | one-paragraph summary + the example's status |

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
