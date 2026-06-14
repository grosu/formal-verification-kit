# tree_height(t) — formally specified & verified

> **Authenticity / repair-loop note.** The source program here is the frozen, no-human-touch `.py` output vibe-coded by **Claude Code Opus 4.8 (`opus-4-8`)** from the prompt in `PROMPTS.md`. This example shows the FVK audit/evidence phase before repair: FVK formalizes, proves or hits escalation boundaries, and reports Findings. In normal use, the coding agent then uses those FVK artifacts to repair the code; this corpus keeps the pre-repair source frozen so the Findings remain visible.


**Status:** constructed (escalation-bounded)

Recursive height of a binary tree, modeled as a K value sort `none | node(Int,Tree,Tree)`. Two contracts are proved: the self-contained helper `max2(x,y)` gets its own `(MAX2)` claim (bundled-tier clean — a demonstration that self-contained helpers each earn a spec), and `tree_height` uses a branching `(REC)` circularity discharging *both* child calls. The structural-induction principle over the `Tree` datatype is the escalation obligation.

**Demonstrates:** **Recursive data structures** (a `Tree` value sort) — the frontier. Two contracts: the helper `(MAX2)` (clean) and `tree_height` (branching `(REC)`); the structural-induction principle escalates.

**Key findings:** Deep/degenerate trees hit Python's recursion limit (depth 999); the exact `(value,left,right)` tuple shape is assumed (malformed nodes raise).

| File | What it is |
|---|---|
| [`tree_height.py`](tree_height.py) | the program — **self-contained** (no libraries or builtins) |
| [`mini-python.k`](mini-python.k) | minimal K semantics of just the constructs it uses |
| [`mini-python-spec.k`](mini-python-spec.k) | the K reachability claims (contract + circularities) |
| [`SPEC.md`](SPEC.md) | plain-English spec note |
| [`FINDINGS.md`](FINDINGS.md) | the Findings (bugs / preconditions / corner cases) |
| [`PROOF.md`](PROOF.md) | the constructed proof + test-redundancy report |
| [`PROMPTS.md`](PROMPTS.md) | the prompts that reproduce this example |

Produced cold by an isolated newcomer — see the kit's
[examples/README.md](../README.md) -> *How examples are produced*.
