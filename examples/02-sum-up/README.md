# Example: `sum-up` (Python — count-up loop)

> **Authenticity / repair-loop note.** The source program here is the frozen, no-human-touch `.py` output vibe-coded by **Claude Code Opus 4.8 (`opus-4-8`)** from the prompt in `PROMPTS.md`. This example shows the FVK audit/evidence phase before repair: FVK formalizes, proves or hits escalation boundaries, and reports Findings. In normal use, the coding agent then uses those FVK artifacts to repair the code; this corpus keeps the pre-repair source frozen so the Findings remain visible.


This directory is a **template** that `/formalize` and `/verify` imitate. It is the
worked artifact set for one function — `sum_to_n(n) = 1 + 2 + … + n`, computed by a loop
that counts **up** (`i` from `1` to `n`) — taken all the way from source code to a
constructed correctness proof. When the commands run on your code, they aim to
produce the same shape of output, file for file.

The companion example [`sum-down/`](../03-sum-down/) computes the **same** result with
a loop that counts *down*, illustrating a genuinely **different invariant shape** (a
"remaining-work" invariant). See the [examples catalog](../README.md).

## The files

| File | What it is |
|---|---|
| [`sum.py`](sum.py) | **The program** — `sum_to_n(n)` (count-up: `s = 0; i = 1; while i <= n: s += i; i += 1`). |
| [`mini-python.k`](mini-python.k) | **The minimal K semantics** of just the fragment used (integer literals/names, `+`, `<=`, `=`, `+=`, `while`, `def`, `return`, call — no `if`). |
| [`mini-python-spec.k`](mini-python-spec.k) | **The claims**: `(LOOP)` the loop-invariant circularity, and `(SUM)` the function contract (precondition `n >= 0`, result `n*(n+1)/2`). |
| [`SPEC.md`](SPEC.md) | Plain-English spec note (the `/formalize` stage). |
| [`FINDINGS.md`](FINDINGS.md) | Plain-language findings — the `n >= 0` bug (the `/formalize` stage). |
| [`PROOF.md`](PROOF.md) | **The condensed proof** plus findings and the test-redundancy recommendation (the `/verify` stage). |
| [`PROMPTS.md`](PROMPTS.md) | **The exact prompts** that reproduce this example with the kit. |

## Read the proof

See **[PROOF.md](PROOF.md)** for the condensed reachability-logic proof, the
`kompile`/`kprove` commands that machine-check it, and the human-readable findings
and test-redundancy notes. It is also where the two headline payoffs land — a
**hidden subtle bug** surfaced and a **fewer-tests / faster-CI** recommendation —
so the value is one click away. (MVP status: the proof is **constructed, not
machine-checked** — PROOF.md emits the exact commands to run it.)

## Reproduce it

The exact prompts that drive the kit to (re)produce this example are in
[`PROMPTS.md`](PROMPTS.md).

## Part of a growing library

`sum-up` demonstrates the **count-up, additive (polynomial)** invariant shape. See
the [examples catalog](../README.md) for the full list and for how to add a new
example — worked examples are the kit's primary growth lever, so the library is
expected to expand by *shape* (count-down, product/factorial, array loops,
recursion, and beyond). When a case isn't covered by an existing example or the
distilled primers, escalate via
[`knowledge/sources.md`](../../knowledge/sources.md) (optionally with `--refresh`)
to the deeper primary sources.
