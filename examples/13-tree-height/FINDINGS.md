# Findings report — `tree_height.py`

Plain-language findings from formalizing [`tree_height.py`](tree_height.py) (now
**self-contained**: it defines its own `max2`). Each is `input → observed vs
expected`. **Non-blocking** — this report never edits or deletes your code; it is
advice. These findings **do not** depend on machine-checking the proof — they are
solid today. (Each observed value below was checked by running the actual function.)

---

## Finding 1 — `max2` is correct, including the tie case (a *positive* finding)

The self-contained helper is correct on all integer pairs, and the verification gives
it its **own** contract `(MAX2)`. The one subtlety worth naming is the **tie**: `x == y`
takes the `else` branch and returns `y` (the second argument). The returned *value* is
of course identical, so it is harmless here — but it is the kind of detail a precise
spec flushes out, and it matters if `max2` were ever reused with side-effecting or
identity-sensitive arguments.

| input | code does (observed) | expected | verdict |
|---|---|---|---|
| `max2(2, 5)` | `5` | `5` | ✓ |
| `max2(7, 3)` | `7` | `7` | ✓ |
| `max2(4, 4)` | `4` (via the `else` branch, returns `y`) | `4` | ✓ (tie → second arg) |

**No action needed.** The contract `(MAX2)` proves `max2(x, y) = max(x, y)` for all
integer pairs.

## Finding 2 — `tree_height` is correct on every well-formed tree (the core result)

For the verified domain (a well-formed tree: `None`, or `(value, left, right)` with
well-formed children), `tree_height(t)` equals the inductive height measure
`h(t) = 1 + max(h(left), h(right))`, `h(None) = 0`. Spot-checked:

| input | code does (observed) | expected `h(t)` | verdict |
|---|---|---|---|
| `None` | `0` | `0` | ✓ |
| `(5, None, None)` (single node) | `1` | `1` | ✓ |
| left chain of 3 | `3` | `3` | ✓ |
| right chain of 3 | `3` | `3` | ✓ |
| balanced (root + two leaves) | `2` | `2` | ✓ |
| unbalanced (deeper right subtree) | `3` | `3` | ✓ |

The base case is off-by-one-clean: `tree_height(None) = 0`, and a leaf
`(v, None, None)` is `1 + max(0, 0) = 1`. **No action needed.**

## Finding 3 — recursion-depth limit: a real corner case (verified boundary)

This is the one finding that recommends action. The contract is **partial
correctness** — `tree_height(t) = h(t)` *if and when it returns*. For this recursive
implementation that "if" bites at a concrete, measured boundary: a **deep / degenerate
tree** (a chain — every node has one `None` child) consumes one Python stack frame per
level of depth, so it hits CPython's default recursion limit
(`sys.getrecursionlimit() == 1000`):

| input (left chain of depth `d`) | code does (observed) | mathematically expected |
|---|---|---|
| `d = 998` | `998` | `998` ✓ |
| `d = 999` | **raises `RecursionError`** | `999` |
| `d = 100000` | **raises `RecursionError`** | `100000` |

Measured: the smallest chain depth that raises is **999** (so the function returns
correctly only for depth `0 ≤ d ≤ 998` at the default limit). The recursion *is*
mathematically well-founded — every child tree is structurally smaller (the
`Tree` value sort is finite/inductive) — so in idealized semantics it terminates for
every finite tree; the limit is purely a CPython stack-depth artifact. (A *balanced*
tree of `N` nodes recurses only `O(log N)` deep, so it is fine far past `N = 998`; the
limit bites on **unbalanced / degenerate** shapes.)

**Recommendation:** for trees that may be deep or adversarially unbalanced, rewrite the
traversal **iteratively** with an explicit stack (or use an explicit BFS/DFS with a
queue), which is O(1) Python stack. If the recursive form is kept for clarity, document
the depth limit, or raise it deliberately (`sys.setrecursionlimit(...)`).

## Finding 4 — the exact tuple shape is ASSUMED (out-of-domain inputs raise)

The function never validates `t`'s shape; it reads `t[1]` and `t[2]` directly. On the
verified domain that always succeeds, but **malformed inputs** fail (loudly, not
silently):

| input | code does (observed) | note |
|---|---|---|
| `(1, None)` (2-tuple, wrong arity) | **raises `IndexError`** (`t[2]`) | missing `right` slot |
| `(1, 7, None)` (`int` in a child slot) | **raises `TypeError`** (`7[1]` — `int` not subscriptable) | non-tree child |
| `()` (empty tuple) | **raises `IndexError`** | not a node |

These are **out of domain** — the formal contract `(HEIGHT)` is stated with the
precondition "`t` is a well-formed tree", and the mini-X model's `Tree` value sort
(`none | node(Int, Tree, Tree)`) encodes exactly that well-formedness. The failures are
*defined* rejections (exceptions), not silent wrong answers, which is the better
behavior. **Recommendation (optional):** if untrusted input can reach this function,
validate the shape (or accept that a malformed tuple raises). The assumption is recorded
so the contract's domain is explicit, not hidden.

## Finding 5 — spec-difficulty / methodology signal: the recursive-DATA-STRUCTURE shape

Writing the spec was clean, and the **control flow** is exactly the `sum-recursive`
`(REC)` shape — but with **two** new wrinkles, both recorded for honesty (not as code
bugs):

1. **Branching recursion.** `(REC)` discharges **two** recursive child calls
   (`tree_height(left)` and `tree_height(right)`), not one. K handles this with no new
   machinery — each child call earns its own `call` step (guardedness) and the same
   coinductive hypothesis closes both — but it is the first branching circularity in
   the example set, worth a reviewer's eye.

2. **Recursive data structure → an `[ESCALATION BOUNDARY]`.** The post-value uses an
   **inductive measure** `h(T)` over the `Tree` value sort. The base case and the
   per-node step are **bundled-tier clean** (Z3 + the measure equation + `(MAX2)`), but
   the **structural-induction principle over `Tree`** — lifting base + per-node step up
   to "holds for *every* finite tree" — is the kit's documented recursive-data-structure
   escalation (reachability/mu primer section 7; routes to **Chen & Rosu, Matching
   mu-Logic, LICS 2019** and **unified fixpoint reasoning, OOPSLA 2020**). It is
   **stated** as an open obligation `(T-IND)` in [`tree-height-spec.k`](tree-height-spec.k),
   **never** admitted as `[trusted]`. The artifacts are **constructed, not
   machine-checked**, and `(T-IND)` is the one piece a reviewer should scrutinize first.

## Finding 6 — no overflow; non-negative; well-defined (a deliberate non-finding)

Worth stating because a C/Java version might differ: Python integers are
arbitrary-precision, so there is **no overflow** in the `1 + ...` accumulation for any
height. The result is always `>= 0` (`h(None) = 0`, and every node adds 1 to a
non-negative max), matching the intuitive notion of height. The two functions compose
cleanly: `tree_height` uses `max2` only on the two *non-negative* subtree heights, so
`(MAX2)`'s contract is exercised exactly within its (unconditional) domain. No action
needed.

---

*Next: run `/verify` to construct the proof of `(MAX2)`/`(REC)`/`(HEIGHT)` and get the
test-redundancy recommendation (benefit 1). Findings 3-4 describe behavior the
partial-correctness proof does **not** cover (a deep/degenerate tree raising
`RecursionError`; malformed-tuple inputs raising) — keep tests for those. Finding 5
records the `(T-IND)` escalation boundary that `kprove` cannot close from the bundled
tier alone.*
