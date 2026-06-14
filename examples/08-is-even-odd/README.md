# is_even / is_odd — formally specified & verified

> **Authenticity / repair-loop note.** The source program here is the frozen, no-human-touch `.py` output vibe-coded by **Claude Code Opus 4.8 (`opus-4-8`)** from the prompt in `PROMPTS.md`. This example shows the FVK audit/evidence phase before repair: FVK formalizes, proves or hits escalation boundaries, and reports Findings. In normal use, the coding agent then uses those FVK artifacts to repair the code; this corpus keeps the pre-repair source frozen so the Findings remain visible.


**Status:** constructed

Two mutually recursive predicates. The new shape: the circularity spans two contracts, each used as the coinduction hypothesis for the *other's* recursive call (a generalization of `sum-recursive`'s single `(REC)`); the base case is `n==0` and the precondition `n>=0`. Parity step facts are bundled-tier, so nothing escalates.

**Demonstrates:** **Mutual recursion** — the circularity spans **two** contracts `(EVEN)`/`(ODD)` that discharge *each other's* recursive call. **No escalation** (parity is bundled-tier).

**Key findings:** Unguarded `n<0` does **not terminate** (RecursionError) — `n>=0` is load-bearing for termination; recursion-depth limit at n=998.

| File | What it is |
|---|---|
| [`even_odd.py`](even_odd.py) | the program — **self-contained** (no libraries or builtins) |
| [`mini-python.k`](mini-python.k) | minimal K semantics of just the constructs it uses |
| [`mini-python-spec.k`](mini-python-spec.k) | the K reachability claims (contract + circularities) |
| [`SPEC.md`](SPEC.md) | plain-English spec note |
| [`FINDINGS.md`](FINDINGS.md) | the Findings (bugs / preconditions / corner cases) |
| [`PROOF.md`](PROOF.md) | the constructed proof + test-redundancy report |
| [`PROMPTS.md`](PROMPTS.md) | the prompts that reproduce this example |

Produced cold by an isolated newcomer — see the kit's
[examples/README.md](../README.md) -> *How examples are produced*.
