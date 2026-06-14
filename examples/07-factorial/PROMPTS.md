# Reproducibility — the prompts that produce `factorial`

> **Source-program provenance.** The `.py` program in this folder is intentionally preserved as the exact vibe-coded output of **Claude Code Opus 4.8 (`opus-4-8`)** from prompt P1 below, before FVK was introduced. This protocol refresh updates only FVK documentation/provenance artifacts; it does **not** repair, regenerate, or human-edit the source program. In the full FVK loop, a coding agent uses these artifacts to repair the code in a later iteration; this example freezes the pre-repair source so the Findings remain visible.


Produced **cold**: an agent that did not know the kit was coming first wrote the
program; then a clean-context agent learned the Formal Verification Kit and ran
`/formalize` + `/verify` on it. *(In this run that two-step was automated by an
isolated-coder → kit-user harness; the prompts below are the human-reproducible
recipe — i.e. what you would paste, in order, in a fresh session.)*

## The prompts

```text
[P1]  Write a Python function `factorial(n)` that returns n factorial
      (n! = 1·2·…·n, with 0! = 1) for a non-negative integer n. Use recursion.
      Add a few tests and run them.

[P2]  Learn the Formal Verification Kit at https://github.com/grosu/formal-verification-kit:
      read its AGENTS.md and follow the BOOTSTRAP (read the knowledge/ primers).
      Tell me when you're ready.

[P3]  Before writing any files, walk me through the specification and the recursion
      circularity you intend to write, and any concerns — no artifacts yet.

[P4]  run /formalize

[P5]  If I say /verify, what exactly will you verify — given any bugs or edge cases
      you've already found?

[P6]  run /verify
```

Append *"be exhaustive and adversarially verify this"* to P4/P6 to make the agent
cross-check itself.

## What each prompt produced

- **P1** → [`factorial.py`](factorial.py) (recursive, with a `ValueError` guard for
  `n<0`) and [`test_factorial.py`](test_factorial.py).
- **P2** → the agent read the kit and reported the recursion adaptation it would make.
- **P4** → [`mini-python.k`](mini-python.k) (adds `*`), [`mini-python-spec.k`](mini-python-spec.k)
  (the spec-only `fact()` symbol + the `(REC)` and `(FACT)` claims),
  [`SPEC.md`](SPEC.md), [`FINDINGS.md`](FINDINGS.md).
- **P6** → [`PROOF.md`](PROOF.md) (constructed, not machine-checked) with the
  test-redundancy report.
