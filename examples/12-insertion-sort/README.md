# insertion_sort(a) — formally specified & verified

> **Authenticity / repair-loop note.** The source program here is the frozen, no-human-touch `.py` output vibe-coded by **Claude Code Opus 4.8 (`opus-4-8`)** from the prompt in `PROMPTS.md`. This example shows the FVK audit/evidence phase before repair: FVK formalizes, proves or hits escalation boundaries, and reports Findings. In normal use, the coding agent then uses those FVK artifacts to repair the code; this corpus keeps the pre-repair source frozen so the Findings remain visible.


**Status:** constructed (escalation-bounded)

In-place insertion sort. Three nested claims — `(SORT)` (the mutated list is a sorted permutation of its original contents), `(OUTER)` (the sorted prefix grows), `(INNER)` (insert the key into its hole). The in-bounds/linear VCs are bundled-tier; the sortedness and permutation VCs are stated as `[ESCALATION BOUNDARY]` obligations, never faked `[trusted]`.

**Demonstrates:** **Arrays + nested loops + a relational spec** — a sorted **permutation** (`isSorted` + multiset `bag`); three nested circularities `(SORT)`/`(OUTER)`/`(INNER)`. The canonical **escalation-boundary** example, handled honestly.

**Key findings:** A total-order precondition (NaN/mixed types break sorting); stability hinges on the strict `>` in the shift guard; the `j>=0` short-circuit keeps indices in-bounds; it mutates its input.

| File | What it is |
|---|---|
| [`insertion_sort.py`](insertion_sort.py) | the program — **self-contained** (no libraries or builtins) |
| [`mini-python.k`](mini-python.k) | minimal K semantics of just the constructs it uses |
| [`mini-python-spec.k`](mini-python-spec.k) | the K reachability claims (contract + circularities) |
| [`SPEC.md`](SPEC.md) | plain-English spec note |
| [`FINDINGS.md`](FINDINGS.md) | the Findings (bugs / preconditions / corner cases) |
| [`PROOF.md`](PROOF.md) | the constructed proof + test-redundancy report |
| [`PROMPTS.md`](PROMPTS.md) | the prompts that reproduce this example |

Produced cold by an isolated newcomer — see the kit's
[examples/README.md](../README.md) -> *How examples are produced*.
