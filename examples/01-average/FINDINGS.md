# Findings report — `average.py`

Plain-language findings from formalizing [`average.py`](average.py). Each is
`input → observed vs expected`. **Non-blocking** — this report never edits or
deletes your code; it is advice. These findings **do not** depend on
machine-checking the proof — and Findings 1, 3 were **executed against the real
code** (transcript below), not merely conjectured.

The program (now self-contained — sums with an explicit `while` loop, then divides):

```python
def average(nums):
    """Return the arithmetic mean of a non-empty list of numbers."""
    total = 0
    i = 0
    n = len(nums)
    while i < n:
        total = total + nums[i]
        i = i + 1
    return total / n
```

---

## Finding 1 — missing precondition `len(nums) >= 1` — **ZeroDivisionError on `[]`** (the headline bug, executed)

Writing a clean contract forced the precondition `len(nums) >= 1`. The function has
**no guard** against the empty list. On `[]` the loop body never runs, so
`total = 0`, and `n = len([]) = 0`; the final `return total / n` evaluates `0 / 0`,
which Python raises as a **`ZeroDivisionError`**.

**Executed against the code** (transcript: `average([])` raised
`ZeroDivisionError: division by zero`):

| input `nums` | code does (observed) | expected (arithmetic mean) |
|---|---|---|
| `[]` | **raises `ZeroDivisionError: division by zero`** | undefined — there is no mean of an empty list |
| `[42]` | `42.0` | `42` ✓ |
| `[1, 2, 3]` | `2.0` | `2` ✓ |

The "mean of `[]`" is **genuinely undefined** (you cannot average zero numbers), so
the *right* behavior is debatable — but an **unhandled `ZeroDivisionError`** is almost
certainly not the intended one. This is the formal mirror of the semantics: the
division rule in [`mini-python.k`](mini-python.k) carries `requires I2 =/=Int 0`, so
on `n = 0` it **cannot fire** and the configuration is **stuck** — exactly the runtime
exception.

**Recommendation:** add an explicit precondition / guard. Either
- enforce it: `if not nums: raise ValueError("average() of empty list")` (turn the
  silent `ZeroDivisionError` into a clear, intentional error), or
- document `len(nums) >= 1` as a precondition (what `(AVG)`'s
  `requires size(NUMS) >= 1` encodes), and have callers ensure non-emptiness, or
- define a total fallback (e.g. return `0` or `float('nan')` for `[]`) if a total
  function is wanted.

The verified contract `(AVG)` holds **only** for `len(nums) >= 1`; the empty list is
**out of the verified domain**, and any `average([])` test should be kept to pin this
boundary (see [`PROOF.md`](PROOF.md) §6).

## Finding 2 — the missing precondition is *load-bearing in the spec* (spec-difficulty = bug signal)

This is the same class of signal as Finding 1, surfaced from the *spec side*: the
function contract `(AVG)` is **not even well-formed** without `size(NUMS) >= 1`.
Without it, the final division step's side condition `size(NUMS) =/=Int 0` cannot be
discharged, so the proof **stalls on the empty-list case** — the formal counterpart
of the runtime crash. The difficulty of writing a clean precondition *is* the bug;
naming it (`len(nums) >= 1`) is the deliverable. (Cf. the sum example's `n >= 0`: a
side condition you are *forced* to add is usually a precondition the code silently
assumed.) **Note this is the division precondition, distinct from the loop's own
`0 <= i <= n` side condition, which is clean and always holds — see Finding 6.**

## Finding 3 — int-vs-float division: `/` is TRUE division, the model uses `/Int` (executed)

Python 3's `/` is **true (float) division**, so `average` always returns a **float**,
even on integer input — and for inputs where the length does **not** divide the sum,
the result is **non-integer**. The mini-X semantics models `/` as K's `/Int` (integer
division, **truncates toward zero**), because the kit's arithmetic fast path is over
`Int` (floats/rationals are an escalation case —
[`knowledge/sources.md`](../../../formal-verification-kit/knowledge/sources.md)).

**Executed against the code (Python `/`):**

| input `nums` | code returns (observed, a float) | `/Int` model would give | agree? |
|---|---|---|---|
| `[1, 2, 3]` | `2.0` | `2` | ✓ (value-equal; `2.0 == 2`) |
| `[10]` | `10.0` | `10` | ✓ |
| `[-1, 1]` | `0.0` | `0` | ✓ |
| `[1, 2]` | **`1.5`** | **`1`** (truncates) | ✗ — the model loses the `.5` |
| `[1, 2, 3, 4]` | **`2.5`** | **`2`** | ✗ |

So the `/Int` model is **faithful only when `len(nums)` exactly divides `sum`** —
the integer-mean domain. Two consequences worth flagging:

- **The inline test suite *does* exercise the non-integer case** — it asserts
  `average([1, 2]) == 1.5`. That assertion pins the **true (float) mean** and would
  **fail** under a `//`/`/Int` integer-mean implementation (which returns `1`). So the
  *intended* contract is the **float** mean, and the `/Int` model is a deliberate,
  reported restriction — exact only on the remainder-0 sublists, and *not* matching the
  `[1, 2] == 1.5` test. (The other tests — `[1,2,3]==2`, `[10]==10`, `[2,4]==3`,
  `[-1,1]==0`, `[0,0,0]==0` — are all integer-valued means, so they pass under both.)
- **Verifying the *true* mean precisely** needs a **Rational/Float theory** — an
  `[ESCALATION BOUNDARY]` beyond the bundled integer tier. The integer-mean contract
  `(AVG)` is the faithful image of `total // n`; the float intent is a separate, harder
  target. Either way the int-vs-float choice is **load-bearing and was invisible to a
  quick read**; the spec made it explicit.

## Finding 4 — element-type genericity (a modeling restriction, stated)

The signature `average(nums)` is generic over the element type. The mini-X model
restricts elements to `Int` (the analogue of the sum example's Int restriction). This
is a **faithful restriction reported, not erased**: a float-element list is covered by
the same loop/fold *shape* but needs the Rational/Float theory of Finding 3 to be
exact. No action required for the integer-mean contract; noted so the gap is explicit.

## Finding 5 — the spec-only fold's *totality* is the lone `[ESCALATION BOUNDARY]` (a mild capability gap, not a code defect) — and the loop is otherwise escalation-FREE

This is about the *proof*, not the *code*. The loop invariant and the postcondition
use a spec-only abstraction `listsum(L, lo, hi)` (the sum of `L[lo:hi)`), a clean
inductive **range fold** defined in [`average-spec.k`](average-spec.k).

**The crucial good news — the loop step is clean.** Because the program now *literally
adds the list element* each iteration (`total = total + nums[i]`), the loop's step
verification condition is

> `total_new = total + nums[i]`,  i.e.  `listsum(nums,0,i) + nums[i] = listsum(nums,0,i+1)`

which is **exactly the unfold (defining) equation of `listsum`** — a single fold step,
**no division, no truncation, no nonlinear arithmetic**. It is discharged by the fold's
own rewrite rule (bundled tier). **This is the headline difference from the previous
`return sum(nums) / len(nums)` version**, whose single VC entangled the fold with a
**truncating `/Int` divisibility** fact — a genuine, harder `[ESCALATION BOUNDARY]`.
**That escalation is gone here.**

**The one residual obligation** is the `[function, total]` **totality** of `listsum`:
that the range fold is well-defined on *every* `(L, lo, hi)`. Its two defining
equations (empty range `→ 0`; peel-the-last) are exhaustive and the recursion
decreases `hi - lo`, so totality is a **structural induction on `hi - lo`** — the kind
of well-foundedness K's bundled tier does not certify on its own. It is therefore
**stated as an explicit `[ESCALATION BOUNDARY]`, NOT admitted as `[trusted]`** (which
would manufacture confidence the kit does not have). **Route:** OOPSLA'20 (unified
fixpoint reasoning over inductive data structures) / LICS'19 (Matching μ-Logic) — see
[`knowledge/sources.md`](../../../formal-verification-kit/knowledge/sources.md);
`/verify --refresh` re-fetches them.

This residual is **much milder** than the builtin-`sum()` version's boundary: there
the open obligation was *divisibility of a symbolic fold under truncating division*;
here it is merely *the fold is total* — a housekeeping induction, with the actual
arithmetic (the step, the exit) already clean. A worked list-fold example is the
durable fix, of which `average` is a natural seed.

## Finding 6 — the loop side condition `0 <= i <= n` is clean (a deliberate non-finding, contrast with sum-up)

Worth stating because the `sum-up` example's loop bound `I <= N+1` was a *finding*
(its closed form went negative outside the bound). Here the loop circularity `(LOOP)`
carries `0 <= I <= N` (`N = size(nums)`), and unlike `sum-up` this bound is **never
violated and never surprising**: the loop is a plain index walk `i: 0 → n`, the
invariant `total = listsum(nums,0,i)` is meaningful for every `0 <= i <= n`, and the
guard `i < n` keeps every read `nums[i]` in bounds (`0 <= i < n = size(nums)`), so
there is **no IndexError** and **no off-by-one**. The bound is load-bearing for the
fold (the empty range at `i = n` gives the base case `0`) but it is *satisfied by
construction*, not a hidden precondition. No action needed.

## Note — termination (trivial here, easily total)

The loop clearly terminates: the measure `n - i` strictly decreases by `1` each
iteration (as `i` rises `0 → n`) and is bounded below by `0`. The contract is stated
as **partial correctness** (the kit default), but **total correctness is one variant
away** — add `n - i` (bounded below by `0`, strictly decreasing) to `(LOOP)` and
discharge it alongside the existing VCs. **Recommendation-only**, not attempted unless
asked. (The only non-termination-like failure is the `ZeroDivisionError` of Finding 1,
which is "stuck", not "looping".)

---

*Next: run `/verify` to construct the proof of `(AVG)`/`(LOOP)` and get the
test-redundancy recommendation (benefit 1). The `average([])` case (Finding 1) is
exactly the out-of-domain behavior any empty-list test should keep pinning.*
