# Specification note — `array_max.py`

## Public intent ledger (protocol refresh)

This section makes the example conform to the current `/formalize` protocol: the
claim provenance is explicit before the formal claims, and the original source program
remains unchanged. The program under audit is `array_max.py`, preserved as the
exact Claude Code Opus 4.8 (`opus-4-8`) vibe-coded output from `PROMPTS.md`; FVK's
role in this example is to expose obligations and Findings before the repair iteration. In the full FVK loop, the coding agent uses this evidence to repair the code; this corpus preserves the pre-repair source so the issue remains visible.

- **I1 — prompt / public task statement**
  - Evidence: P1 in `PROMPTS.md`: "Write `array_max(a)` returning the maximum element of a non-empty list, scanning with an index `while` loop. Self-contained — no `max`/slicing."
  - Obligation: `array_max(a)` should return an element that is a maximum of a non-empty list under a total order.
  - Status: encoded in the function contract(s) and, where needed, the loop/recursion circularity.
- **I2 — implementation shape being audited**
  - Evidence: `array_max.py`: The code reads `a[0]` into `largest`, scans with index `i`, and updates when `a[i] > largest`.
  - Obligation: the mini-Python semantics and proof obligations model this control/data-flow shape.
  - Status: encoded in `mini-python.k` and `mini-python-spec.k`; the source program is intentionally not rewritten.
- **I3 — FVK finding / conflict signal**
  - Evidence: `FINDINGS.md`: `array_max([])` raises `IndexError`, and NaN/mixed types violate the implicit total-order assumption; both remain findings, not code fixes.
  - Obligation: keep the issue visible as next-iteration feedback instead of weakening the spec or silently fixing the code during the provenance refresh.
  - Status: reported in `FINDINGS.md` / `PROOF.md`; source repair is deferred to the next explicit FVK-guided coding iteration, while this example refresh preserves the original source.
- **I4 — proof-scope / escalation evidence**
  - Evidence: `PROOF.md` and `[ESCALATION BOUNDARY]` notes where present.
  - Obligation: The max-prefix invariant is within the bundled tier; no multiset/permutation escalation is needed.
  - Status: constructed, not machine-checked; escalation boundaries are stated honestly rather than trusted.


Plain-English companion to the formal artifacts, for a developer who will never
open the `.k` files. Produced by the formal-verification-kit `/formalize` step.

Artifacts in this directory: [`array_max.py`](array_max.py) (the code),
[`mini-python.k`](mini-python.k) (the fragment semantics),
[`mini-python-spec.k`](mini-python-spec.k) (the K claims),
[`FINDINGS.md`](FINDINGS.md) (the plain-language findings), and
[`PROOF.md`](PROOF.md) (the constructed proof + reproduce commands).

---

## What the program does

```python
def array_max(a):
    largest = a[0]
    i = 1
    while i < len(a):
        if a[i] > largest:
            largest = a[i]
        i = i + 1
    return largest
```

`array_max(a)` returns the **maximum element** of the list `a`. It seeds `largest`
with the first element `a[0]`, then scans the rest of the list with an explicit
index `i` running from `1` to `len(a) - 1`, replacing `largest` whenever it meets a
strictly larger element. The list is only **read** (`a[0]`, `a[i]`, `len(a)`); it is
never modified. There is no `else` branch — when `a[i] <= largest`, `largest` is
left unchanged.

---

## The contract (function `array_max`)

- **Precondition:** `len(a) >= 1` — the list must be **non-empty**. The first line
  `largest = a[0]` indexes element 0, which fails (`IndexError`) on `[]`. This
  precondition is silent in the code; the spec makes it explicit. (See FINDINGS #1.)
  A second, implicit precondition is that the elements are **totally ordered** under
  `>` — true for the `Int` model we verify, but not for arbitrary Python values such
  as `NaN` or mixed incomparable types. (See FINDINGS #2.)

- **Postcondition (∀-quantified):** the returned value `result` satisfies **both**

  1. **Upper bound:** `for all j in [0, len(a)).  a[j] <= result`
     — every element of `a` is `<=` the result; and
  2. **Membership:** `result` **is** one of the elements of `a`.

  Together these two say exactly `result = max(a)`. In the formal file they are the
  spec-only `[function]` abstractions `isUpperBound(A, result)` and `inList(result, A)`
  in the `(MAX)` claim's `ensures`.

This is **partial correctness**: *if and when* `array_max` returns, the result
satisfies the postcondition. Termination is not proved (see PROOF §"Residual risk");
it is obvious here — the counter `i` increases by 1 each step toward the fixed bound
`len(a)` — and is offered as a recommendation, not part of the default contract.

---

## The loop invariant (the `while`)

The loop is specified by the `(LOOP)` circularity claim, **generalized** over the
running maximum `largest = R` and the counter `i = I` (not pinned to their entry
values), with:

- **Invariant:** `largest = max of the visited prefix a[0:i)` — formally
  `R = maxPrefix(A, I)`, the maximum of the first `I` elements.
- **Soundness side condition:** `1 <= i <= len(a)`. The lower bound `1 <= i` records
  that `a[0]` has already been folded into `largest` before the loop (the init
  `largest = a[0]; i = 1`), so the visited prefix is always non-empty and its maximum
  is defined. The upper bound `i <= len(a)` holds on every reachable iteration.
- **On exit** (`i = len(a)`): the visited prefix is the whole list, so
  `largest = maxPrefix(A, len(a)) = max(a)`.

This is the analogue of the `sum` example's `i <= n + 1` side condition: a bound the
code silently relies on, surfaced by the spec.

---

## Why this is a max problem, not a sort problem (tier note)

The postcondition is a **bounded `forall` (upper bound) + a membership** — both
decidable by comparisons on a total order. It is **not** sortedness and **not**
permutation, so it needs **no multiset / `Bag` reasoning**. The loop body
`if a[i] > largest: largest = a[i]` is literally `largest := max(largest, a[i])`, and
the `if` guard's two branches are exactly the case-split that proves the step. The
whole verification therefore stays **within the kit's bundled simplification tier**
(`Z3` + the lemmas in [`mini-python-spec.k`](mini-python-spec.k)); unlike
`examples/12-insertion-sort`, it reaches **no escalation boundary**. See PROOF §4.
