# Findings report — `sum_recursive.py`

Plain-language findings from formalizing [`sum_recursive.py`](sum_recursive.py).
Each is `input → observed vs expected`. **Non-blocking** — this report never edits
or deletes your code; it is advice. These findings **do not** depend on
machine-checking the proof — they are solid today. (Each observed value below was
checked by running the actual function.)

---

## Finding 1 — `n >= 0` is ENFORCED, not silently assumed (a *positive* finding)

This is the headline contrast with the `sum-up`/`sum-down` loop examples, whose
identical math (`n*(n+1)/2`) hid a **silent** bug: for `n <= -2` they returned `0`
while the formula wanted a positive number, and *nothing told the caller*. The
recursive version closes that hole — the precondition the spec needs (`requires N >=Int 0`)
is **enforced at runtime** by `if n < 0: raise ValueError`:

| input `n` | code does (observed) | expected for a "sum of 1..n" | verdict |
|---|---|---|---|
| `-3` | **raises `ValueError`** | undefined / rejected | ✓ correct rejection |
| `0`  | `0`  | `0`  | ✓ |
| `5`  | `15` | `15` | ✓ |

So where `sum-up(-3)` *silently* returns `0` (wrong), `sum_recursive(-3)` **raises
`ValueError`** — a defined, intentional rejection. The formal contract `(SUM)` is
stated with `requires N >=Int 0`; here that side condition is not a latent bug but
a guard the code already implements. **No action needed** — this is the function
doing the right thing. (If anything, it is a small model for what the `sum-up`
Finding recommended.)

## Finding 2 — the `isinstance(n, bool)` exclusion is a genuine safeguard (subtle)

In Python, `bool` is a **subclass of `int`** (`isinstance(True, int)` is `True`,
and `True == 1`). A naive `isinstance(n, int)` check alone would therefore let a
boolean slip through and be summed as `0`/`1`:

| input `n` | without the bool guard would do | the code actually does (observed) |
|---|---|---|
| `True`  | `sum_recursive(1) == 1` (silently treats `True` as `1`) | **raises `TypeError: ... got bool`** |
| `False` | `sum_recursive(0) == 0` (silently treats `False` as `0`) | **raises `TypeError`** |

The author's guard `not isinstance(n, int) or isinstance(n, bool)` correctly
rejects booleans. This is exactly the class of corner case that writing a precise
"`n` is a natural number" precondition flushes out — and here the code already
handles it. **No action needed; worth keeping a regression test** (see the
test-redundancy note `/verify` will produce — this one is *out of domain* and
should be kept).

## Finding 3 — recursion-depth limit: a real corner case (verified `n = 998`)

This is the one finding that recommends action. The contract is **partial
correctness** — `sum_recursive(n) = n*(n+1)/2` *if and when it returns*. For this
recursive implementation that "if" bites at a concrete, measured boundary:
**non-tail recursion** consumes one Python stack frame per unit of `n`, so it hits
CPython's default recursion limit (`sys.getrecursionlimit() == 1000`):

| input `n` | code does (observed) | mathematically expected |
|---|---|---|
| `997`    | `497503`               | `497503` ✓ |
| `998`    | **raises `RecursionError`** | `498501` |
| `100000` | **raises `RecursionError`** | `5000050000` |

Measured: the smallest `n` that raises is **998** (so the function returns
correctly only for `0 <= n <= 997` at the default limit). This is *sharper* than
the loop examples' termination caveat: it is not merely "termination is unproved"
— the implementation **provably fails to return** for `n >= 998`, so the
postcondition is *vacuously* (partial-correctness) satisfied there only because the
function never returns at all.

**Recommendation:** for unbounded `n`, prefer an **iterative** loop or the
closed form `n * (n + 1) // 2` (both O(1) stack). If the recursive form is desired
for clarity, document the input-range limit, or raise the limit deliberately
(`sys.setrecursionlimit(...)`), or rewrite to **tail-recursive + trampoline**.
Note the underlying recursion *is* mathematically well-founded — the measure `n`
strictly decreases by 1 each call and is bounded below by `0` (base case `n == 0`)
— so in idealized semantics it terminates for every `n >= 0`; the limit is purely a
CPython stack-depth artifact.

## Finding 4 — spec-difficulty / methodology signal: this is the recursion shape

Writing the spec was clean, but it required **escalating past the kit's loop
fast-path**: the circularity is on the **recursive call's contract** (`(REC)`),
not a loop invariant. That is the kit's documented recursion-escalation case
(reachability/circularity primer §7; sources route to Roșu & Ștefănescu, FM 2012 /
LICS 2013). Recorded here for honesty, not as a code bug: the artifacts are
**constructed, not machine-checked**, and the recursion circularity (a call-into-
continuation reachability claim that discharges its own inner call) is the one
piece a reviewer should scrutinize first when `kprove` is eventually run.

## Finding 5 — no overflow (a deliberate non-finding)

Worth stating because a C/Java version would have one: Python integers are
arbitrary-precision, so there is **no overflow** for large `n` — the closed form
`n*(n+1)/2` and the recursive accumulation agree at every magnitude (whenever the
recursion is actually allowed to complete; see Finding 3). The base case is also
off-by-one-clean: `sum_recursive(0) = 0 = 0*(0+1)/2`, and `return n + …` includes
`n` itself, so the recursion computes `0+1+…+n` exactly. No action needed.

---

*Next: run `/verify` to construct the proof of `(SUM)`/`(REC)` and get the
test-redundancy recommendation (benefit 1). Findings 1–2 describe out-of-domain
behavior any `n < 0` or `bool` test should keep pinning; Finding 3 is a
**termination/robustness** matter that the partial-correctness proof does not
cover — keep (or add) a test for it.*
