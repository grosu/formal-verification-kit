# Reproducibility — the prompts that produce `reverse`

> **Source-program provenance.** The `.py` program in this folder is intentionally preserved as the exact vibe-coded output of **Claude Code Opus 4.8 (`opus-4-8`)** from prompt P1 below, before FVK was introduced. This protocol refresh updates only FVK documentation/provenance artifacts; it does **not** repair, regenerate, or human-edit the source program. In the full FVK loop, a coding agent uses these artifacts to repair the code in a later iteration; this example freezes the pre-repair source so the Findings remain visible.


Produced **cold**: an isolated agent that did not know the kit was coming first wrote the
program (self-contained — no libraries or builtins); then a clean-context agent learned
the Formal Verification Kit and ran `/formalize` + `/verify` on it. *(Automated here by an
isolated-coder -> kit-user harness; the prompts below are the human-reproducible recipe —
what you would paste, in order, in a fresh session.)*

## The prompts

```text
[P1]  Write `reverse(a)` that reverses the list **in place** (two pointers, index swaps) and returns it. Self-contained — no slicing/`.insert`/`list()`.

[P2]  Learn the Formal Verification Kit at https://github.com/grosu/formal-verification-kit:
      read its AGENTS.md and follow the BOOTSTRAP (read the knowledge/ primers).
      Tell me when you're ready.

[P3]  Before writing any files, walk me through the specification and the
      invariant(s) / circularity you intend to write, and any concerns — no artifacts yet.

[P4]  run /formalize

[P5]  If I say /verify, what exactly will you verify — given any bugs or edge cases
      you've already found?

[P6]  run /verify
```

Append *"be exhaustive and adversarially verify this"* to P4/P6 to make the agent
cross-check itself.

## Produced

- **P1** -> [`reverse.py`](reverse.py) (self-contained)
- **P4** -> [`mini-python.k`](mini-python.k), [`reverse-spec.k`](reverse-spec.k), [`SPEC.md`](SPEC.md), [`FINDINGS.md`](FINDINGS.md)
- **P6** -> [`PROOF.md`](PROOF.md) (constructed, not machine-checked) + the test-redundancy report


> **Protocol refresh note.** Current `/formalize` also emits [`INTENT_SPEC.md`](INTENT_SPEC.md), [`PUBLIC_EVIDENCE_LEDGER.md`](PUBLIC_EVIDENCE_LEDGER.md), [`FORMAL_SPEC_ENGLISH.md`](FORMAL_SPEC_ENGLISH.md), [`SPEC_AUDIT.md`](SPEC_AUDIT.md), and [`PUBLIC_COMPATIBILITY_AUDIT.md`](PUBLIC_COMPATIBILITY_AUDIT.md). The K claims are now named [`reverse-spec.k`](reverse-spec.k) to identify the program being specified; [`mini-python.k`](mini-python.k) remains the language-fragment semantics.
