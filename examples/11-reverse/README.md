# reverse(a) — formally specified & verified

> **Authenticity / repair-loop note.** The source program here is the frozen, no-human-touch `.py` output vibe-coded by **Claude Code Opus 4.8 (`opus-4-8`)** from the prompt in `PROMPTS.md`. This example shows the FVK audit/evidence phase before repair: FVK formalizes, proves or hits escalation boundaries, and reports Findings. In normal use, the coding agent then uses those FVK artifacts to repair the code; this corpus keeps the pre-repair source frozen so the Findings remain visible.


**Status:** constructed (escalation-bounded)

In-place two-pointer reversal. The postcondition splits into a clean half — index relation `out[i]=a_old[n-1-i]` and equal length, discharged by the bundled tier — and a permutation half `bag(out)=bag(a_old)` that needs an inductive multiset theory (and is logically redundant given the index bijection). The loop circularity is the two-pointer swap invariant (`i+j=n-1`).

**Demonstrates:** Arrays with an **index-relation** postcondition (`out[i]=a[n-1-i]`, clean) + **permutation** (escalates). In-place, O(n) — bridges toward the multiset frontier with simpler structure.

**Key findings:** Now **O(n) in place** (the natural `.insert(0,x)` version is O(n^2) — a positive finding); reverse compares nothing, so **no** total-order precondition (clean contrast to sorting); it mutates its input.

| File | What it is |
|---|---|
| [`reverse.py`](reverse.py) | the program — **self-contained** (no libraries or builtins) |
| [`mini-python.k`](mini-python.k) | minimal K semantics of just the constructs it uses |
| [`mini-python-spec.k`](mini-python-spec.k) | the K reachability claims (contract + circularities) |
| [`SPEC.md`](SPEC.md) | plain-English spec note |
| [`FINDINGS.md`](FINDINGS.md) | the Findings (bugs / preconditions / corner cases) |
| [`PROOF.md`](PROOF.md) | the constructed proof + test-redundancy report |
| [`PROMPTS.md`](PROMPTS.md) | the prompts that reproduce this example |

Produced cold by an isolated newcomer — see the kit's
[examples/README.md](../README.md) -> *How examples are produced*.
