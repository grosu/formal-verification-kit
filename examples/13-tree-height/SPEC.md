# Specification note — `tree_height.py`

## Public intent ledger (protocol refresh)

This section makes the example conform to the current `/formalize` protocol: the
claim provenance is explicit before the formal claims, and the original source program
remains unchanged. The program under audit is `tree_height.py`, preserved as the
exact Claude Code Opus 4.8 (`opus-4-8`) vibe-coded output from `PROMPTS.md`; FVK's
role in this example is to expose obligations and Findings before the repair iteration. In the full FVK loop, the coding agent uses this evidence to repair the code; this corpus preserves the pre-repair source so the issue remains visible.

- **I1 — prompt / public task statement**
  - Evidence: P1 in `PROMPTS.md`: "Write `tree_height(t)` for a binary tree (`None`, or a `(value, left, right)` tuple), recursively. Use your own `max2` helper (no `max`). Self-contained."
  - Obligation: `tree_height(t)` should return the height of a finite well-formed binary tree; helper `max2` should return the larger of two heights.
  - Status: encoded in the function contract(s) and, where needed, the loop/recursion circularity.
- **I2 — implementation shape being audited**
  - Evidence: `tree_height.py`: The code represents empty trees as `None`, non-empty trees as `(value,left,right)`, computes child heights recursively, and uses `max2`.
  - Obligation: the mini-Python semantics and proof obligations model this control/data-flow shape.
  - Status: encoded in `mini-python.k` and `tree-height-spec.k`; the source program is intentionally not rewritten.
- **I3 — FVK finding / conflict signal**
  - Evidence: `FINDINGS.md`: Deep degenerate trees hit Python recursion limits, and malformed tuple shapes are outside the verified domain.
  - Obligation: keep the issue visible as next-iteration feedback instead of weakening the spec or silently fixing the code during the provenance refresh.
  - Status: reported in `FINDINGS.md` / `PROOF.md`; source repair is deferred to the next explicit FVK-guided coding iteration, while this example refresh preserves the original source.
- **I4 — proof-scope / escalation evidence**
  - Evidence: `PROOF.md` and `[ESCALATION BOUNDARY]` notes where present.
  - Obligation: The helper proof is bundled-tier clean; lifting the recursive step to all finite trees requires structural induction and remains an escalation boundary.
  - Status: constructed, not machine-checked; escalation boundaries are stated honestly rather than trusted.


Plain-English companion to the formal artifacts, for a developer who will never
open the `.k` files. Produced by the formal-verification-kit `/formalize` step.

- **Program:** [`tree_height.py`](tree_height.py) — now **self-contained**: it defines
  its **own** helper `max2(x, y)` and uses it. Two functions:
  - `max2(x, y)` — returns the larger of `x` and `y` (`if x > y: return x; else: return y`).
  - `tree_height(t)` — height of a binary tree by **branching recursion**
    (`if t is None: return 0; return 1 + max2(tree_height(left), tree_height(right))`).
    A tree is `None` or a 3-tuple `(value, left, right)`.
- **Artifacts:** [`mini-python.k`](mini-python.k) (the mini-X fragment semantics, with
  a binary-tree **value sort**), [`tree-height-spec.k`](tree-height-spec.k) (the three
  K `claim`s).
- **Status:** specs **constructed, not machine-checked** (the MVP does not run
  `kompile`/`kprove`). The Findings (see [`FINDINGS.md`](FINDINGS.md)) hold today
  regardless of machine-checking.
- **Default scope:** **partial correctness** — the contracts constrain terminating
  runs; termination is a recommendation, not proved (and see Finding 3 — for this
  *recursive* function termination has a real CPython recursion-limit caveat).

## What is specified — there are now TWO function contracts

Because the program is self-contained, **every function** gets its own reachability
contract — including the helper. That is the headline of this example: a
self-contained helper is **verified in its own right**, not hand-waved.

### Contract 1 — `(MAX2)`, the helper

> **Precondition:** none (total on two integers).
> **Postcondition:** `max2(x, y) = the larger of x, y` (formally `max2Int(X, Y)`).

A clean, **non-recursive, bundled-tier-clean** proof: one `if x > y` branch, each
arm returns a parameter; the closed-form post-value is the math max. Discharged
entirely by a Z3 case-split on `X > Y` — no circularity, no induction. This is the
demonstration that a self-contained helper earns its **own** verified claim.

### Contract 2 — `(HEIGHT)`, the tree-height function

> **Precondition:** `t` is a **well-formed tree** — either `None`, or a 3-tuple
> `(value, left, right)` whose `left` and `right` are themselves well-formed trees.
> **Postcondition:** `tree_height(t) = h(t)`, the inductive height **measure**

where the measure is defined over the tree value sort, **using `max2`**:

```
h(None)            = 0
h((_, left, right)) = 1 + max2(h(left), h(right))
```

So the empty tree has height 0, a single node has height 1, and a node's height is
one more than the taller of its two subtrees. Encoded as a reachability claim: from a
configuration that *defines* `max2` and `tree_height` and *calls* `tree_height` on a
symbolic well-formed tree `T`, execution terminates with `result |-> h(T)`.

### Recursion circularity — `(REC)` (this example's distinctive claim)

> Evaluating a call `tree_height(T)` (with both functions already defined) reduces to
> the measure `h(T)`, threading the caller's continuation through and leaving the
> store and stack net-unchanged.

**This replaces the loop invariant** of the `sum-up`/`sum-down` examples. There is no
loop, so there is **no `(LOOP)` claim**; the *function's own contract is the
coinductive hypothesis*. K's reachability prover treats every claim in the module as a
circularity, so `(REC)` **discharges BOTH of its recursive child calls**
`tree_height(left)` and `tree_height(right)` — this is **branching recursion**: two
back-edges, each earned by its own `call` step (guardedness). The measure `h(T)` plays
the role the classical loop invariant used to; the two child calls play the role of
the loop back-edge. The combine step `1 + max2(…, …)` reuses **`(MAX2)`** as a lemma.

### How the binary tree is modeled (the one new modeling decision)

The Python tree (`None` or `(value, left, right)`) is modeled as a first-class K
**value sort**:

```
syntax Tree ::= "none" | node(Int, Tree, Tree)
```

This is the tree-shaped analog of [`insertion-sort`](../../../formal-verification-kit/examples/12-insertion-sort/)
modeling a Python list as K's builtin `List` value sort. Because `Tree` is a **value**
(not a heap reference), Python's by-value tuple structure and non-aliasing fall out for
free. The field reads `t[1]`/`t[2]` and the `t is None` test become structural matches
on `node(_, L, R)` / `none`. Spec-only abstraction functions `left(_)`, `right(_)`,
`isNone(_)`, and the measure `h(_)` are **spec vocabulary, not language constructs**
(cf. `isSorted`/`bag` in insertion-sort).

## Honest scope — the recursive-data-structure frontier

Specifying this was **clean**, but proving the `(REC)` circularity reaches the kit's
documented **recursive-data-structure boundary**. The split is sharp:

- **Bundled-tier clean (no escalation):**
  - **`(MAX2)`** in full — a finite, non-recursive, Z3-only proof.
  - The **base case** of `(REC)` (`T = none ⇒ h(none) = 0`).
  - The **per-node step** of `(REC)` (`T = node(V,L,R)`, *assuming* `(REC)` already
    holds at `L` and `R`, the combine `1 + max2Int(h(L), h(R)) = h(node(V,L,R))`
    closes by Z3 + the measure equation + `(MAX2)`).

- **`[ESCALATION BOUNDARY]` — `(T-IND)`, structural induction over `Tree`:** the
  principle that **lifts** "base holds for `none`" + "step holds for `node(V,L,R)`
  given it holds for `L` and `R`" up to "**holds for every finite tree**". This is the
  least-fixpoint / initial-algebra reasoning of Matching μ-Logic; the bundled tier does
  the base and the step but does **not** supply the lift. It is **stated** in
  [`tree-height-spec.k`](tree-height-spec.k) as an open obligation and routed to the
  papers (LICS'19 / OOPSLA'20, see
  [`sources.md`](../../../formal-verification-kit/knowledge/sources.md)) — **never**
  faked as `[trusted]`.

This is the same discipline insertion-sort follows: state every claim well-formed,
discharge everything the bundled tier *can*, and name the rest as explicit obligations.

## How the function proof composes (for `/verify`)

`def max2` and `def tree_height` file both bodies → `result = tree_height(T)`
evaluates the argument and the call heats to the head of `<k>` → **apply `(REC)` at the
symbolic `T`** → the call delivers `h(T)` → the assignment lands `result |-> h(T)`.

`(REC)` itself is proved by symbolic execution + coinduction (per node — the lift is
`(T-IND)`): run the call one step (the `call` rule, the genuine `=>⁺` that earns the
hypothesis), bind `t = T` in a fresh scope, evaluate the guard `t is None`, and
case-split:

- **base (`T = none`):** `if true: return 0`, and `h(none) = 0`. ✓ (VC-BASE)
- **node (`T = node(V,L,R)`):** the guard is false; control reaches
  `return 1 + max2(tree_height(t.left), tree_height(t.right))`. `t.left → L`,
  `t.right → R`; the two inner calls are closed by **`(REC)` on `L` and on `R`**
  giving `h(L)` and `h(R)`; **`(MAX2)`** combines them to `max2Int(h(L), h(R))`; then
  `1 + …` makes `1 + max2Int(h(L), h(R)) = h(node(V,L,R)) = h(T)`. ✓ (VC-STEP)

## Arithmetic the proof will need

- **Map extensionality** `{M[K<-V] #Equals M[K<-V']} => {V #Equals V'}` — to close
  the post-store implication that pins `result`.
- **The math-max simplifications** `max2Int(A,B) = A if A>B else B` — pure linear
  facts, discharged by Z3 (this is also exactly what `(MAX2)` proves the *program's*
  `max2` computes, linking the two contracts).
- No nonlinear / division-by-even reasoning is needed here (unlike the `sum-*`
  examples): the height combine is `1 + max`, which is linear.

## Mini-X semantics scope (only what the in-domain core touches)

Integer literals/names, `+`, `-`, `>`, assignment, `if`/`else` and `if` (no else),
`def`, `return`, call — plus the **`Tree` value sort** with field reads `t.left`/
`t.right` and the `t is None` test. **No `while`**, **no `+=`**, **no `<=`/`==`** (the
program uses none). **Set aside, deliberately:** the exact Python **tuple shape** is
*assumed* — a malformed tuple (wrong arity, a non-tree in a child slot) is out of
domain (Finding 4). The `if __name__ == "__main__"` demo (asserts/`print`) is I/O
outside the verified core and intentionally **not** modeled.

## Next step

Run the kit's **`/verify`** to construct the proof of `(MAX2)`/`(REC)`/`(HEIGHT)`,
emit the `kompile`/`kprove` commands, get the test-redundancy recommendation, and see
the `(T-IND)` escalation obligation laid out explicitly.
