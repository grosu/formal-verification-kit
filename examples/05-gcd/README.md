# gcd(a, b) — formally specified & verified

> **Authenticity / repair-loop note.** The source program here is the frozen, no-human-touch `.py` output vibe-coded by **Claude Code Opus 4.8 (`opus-4-8`)** from the prompt in `PROMPTS.md`. This example shows the FVK audit/evidence phase before repair: FVK formalizes, proves or hits escalation boundaries, and reports Findings. In normal use, the coding agent then uses those FVK artifacts to repair the code; this corpus keeps the pre-repair source frozen so the Findings remain visible.


**Status:** constructed (escalation-bounded)

Euclid's algorithm. The loop invariant is that `gcd(a,b)` is *preserved* (`gcd(a,b)=gcd(b, a mod b)`), and the variant `b` strictly decreases (clean termination). Proving the result *is* the gcd rests on the number-theoretic identity, which is beyond the bundled simplification tier.

**Demonstrates:** Loop invariant is a **preserved relation** (`gcd(a,b)` is invariant), not an accumulator; clean termination (variant `b`). Full correctness needs the number-theoretic Euclid identity.

**Key findings:** Missing `a,b >= 0` precondition — floor-mod makes `gcd(12,-8)` return `-4`; `gcd(0,0)=0` is the conventional value. The Euclid identity is the escalation obligation.

| File | What it is |
|---|---|
| [`gcd.py`](gcd.py) | the program — **self-contained** (no libraries or builtins) |
| [`mini-python.k`](mini-python.k) | minimal K semantics of just the constructs it uses |
| [`gcd-spec.k`](gcd-spec.k) | the K reachability claims (contract + circularities) |
| [`SPEC.md`](SPEC.md) | plain-English spec note |
| [`FINDINGS.md`](FINDINGS.md) | the Findings (bugs / preconditions / corner cases) |
| [`PROOF.md`](PROOF.md) | the constructed proof + test-redundancy report |
| [`PROMPTS.md`](PROMPTS.md) | the prompts that reproduce this example |

Produced cold by an isolated newcomer — see the kit's
[examples/README.md](../README.md) -> *How examples are produced*.


## Protocol adequacy artifacts

This example follows the current adequacy round-trip explicitly:

- [`INTENT_SPEC.md`](INTENT_SPEC.md) — prompt/default-domain intent before accepting implementation behavior.
- [`PUBLIC_EVIDENCE_LEDGER.md`](PUBLIC_EVIDENCE_LEDGER.md) — public evidence ledger mirrored by `SPEC-PROVENANCE` comments.
- [`gcd-spec.k`](gcd-spec.k) — program-specific K claims for `gcd`; [`mini-python.k`](mini-python.k) is only the mini-Python semantics.
- [`FORMAL_SPEC_ENGLISH.md`](FORMAL_SPEC_ENGLISH.md) — English paraphrase of the claims and proof scope.
- [`SPEC_AUDIT.md`](SPEC_AUDIT.md) — intent-vs-formal-spec pass/fail/ambiguous audit.
- [`PUBLIC_COMPATIBILITY_AUDIT.md`](PUBLIC_COMPATIBILITY_AUDIT.md) — public callsite/API/override compatibility audit.
