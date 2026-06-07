# Example: `sum` (Python)

This directory is the **template** that `/formalize` and `/verify` imitate. It is
the worked artifact set for one function — `sum(n) = 1 + 2 + … + n` — taken all
the way from source code to a constructed correctness proof. When the commands run
on your code, they aim to produce the same shape of output, file for file.

## The files

| File | What it is |
|---|---|
| [`summation.py`](summation.py) | **The program** — the Python function under verification. |
| [`mini-python.k`](mini-python.k) | **The minimal K semantics** of just the language fragment `sum` uses (a "mini-X" fragment semantics: integer literals/names, `+`, `<=`, `=`, `+=`, `while`, `def`, `return`, call — no `if`). |
| [`mini-python-spec.k`](mini-python-spec.k) | **The claims** `/verify` discharges: `(LOOP)` the loop-invariant circularity, and `(SUM)` the function contract (precondition `n >= 0`, result `n*(n+1)/2`). |
| [`PROOF.md`](PROOF.md) | **The condensed proof** plus plain-language **findings** (surfaced preconditions / corner cases) and the **test-redundancy** recommendation. |

## Read the proof

See **[PROOF.md](PROOF.md)** for the condensed reachability-logic proof, the
`kompile`/`kprove` commands that machine-check it, and the human-readable findings
and test-redundancy notes. It is also where the two headline payoffs land — a
**hidden subtle bug** surfaced and a **fewer-tests / faster-CI** recommendation —
so the value is one click away. (MVP status: the proof is **constructed, not
machine-checked** — PROOF.md emits the exact commands to run it.)

## Upstream full write-up

This example distills the end-to-end experiment in the upstream
**`formally-verified-sum`** repo
(<https://github.com/grosu/formally-verified-sum>), files
`sum-verification.md` and `sum-correctness-proof.md` — the same upstream
[`PROOF.md`](PROOF.md) cites. `sum-verification.md` carries the full program /
semantics / spec / informal proof / machine-oriented proof narrative;
`sum-correctness-proof.md` the language-independent reachability proof.

## One example today — the library will grow

`sum` is the **only** worked example in the kit right now. Worked examples are the
kit's primary growth lever, so this library is expected to expand by topic —
recursive data structures, binders, concurrency, and beyond. When a new case isn't
covered by the existing examples or the distilled primers, escalate via
[`knowledge/sources.md`](../../knowledge/sources.md) (optionally with `--refresh`)
to the deeper upstream sources.
