# Specification note — `gcd.py`

## Public intent ledger (protocol refresh)

This section makes the example conform to the current `/formalize` protocol: the
claim provenance is explicit before the formal claims, and the original source program
remains unchanged. The program under audit is `gcd.py`, preserved as the
exact Claude Code Opus 4.8 (`opus-4-8`) vibe-coded output from `PROMPTS.md`; FVK's
role in this example is to expose obligations and Findings before the repair iteration. In the full FVK loop, the coding agent uses this evidence to repair the code; this corpus preserves the pre-repair source so the issue remains visible.

- **I1 — prompt / public task statement**
  - Evidence: P1 in `PROMPTS.md`: "Write `gcd(a, b)` returning the greatest common divisor of two non-negative integers via the Euclidean algorithm (`while b: a, b = b, a % b`). Self-contained — operators only."
  - Obligation: `gcd(a,b)` should return the non-negative greatest common divisor of two non-negative integers.
  - Status: encoded in the function contract(s) and, where needed, the loop/recursion circularity.
- **I2 — implementation shape being audited**
  - Evidence: `gcd.py`: The code is Euclid's loop `while b: a, b = b, a % b` and then `return a`.
  - Obligation: the mini-Python semantics and proof obligations model this control/data-flow shape.
  - Status: encoded in `mini-python.k` and `gcd-spec.k`; the source program is intentionally not rewritten.
- **I3 — FVK finding / conflict signal**
  - Evidence: `FINDINGS.md`: The implementation accepts negative inputs; e.g. negative second arguments can produce a negative result, so FVK records the non-negativity precondition and the `gcd(0,0)` convention.
  - Obligation: keep the issue visible as next-iteration feedback instead of weakening the spec or silently fixing the code during the provenance refresh.
  - Status: reported in `FINDINGS.md` / `PROOF.md`; source repair is deferred to the next explicit FVK-guided coding iteration, while this example refresh preserves the original source.
- **I4 — proof-scope / escalation evidence**
  - Evidence: `PROOF.md` and `[ESCALATION BOUNDARY]` notes where present.
  - Obligation: Euclid preservation (`gcd(a,b)=gcd(b,a mod b)`) and base facts are explicit escalation-boundary mathematical obligations.
  - Status: constructed, not machine-checked; escalation boundaries are stated honestly rather than trusted.


Plain-English companion to the formal artifacts, for a developer who will never
open the `.k` files. Produced by the formal-verification-kit `/formalize` step.

- **Program:** [`gcd.py`](gcd.py) — `gcd(a, b)` computes the greatest common divisor
  of two non-negative integers by the **Euclidean algorithm**
  (`while b: a, b = b, a % b; return a`).
- **Artifacts:** [`mini-python.k`](mini-python.k) (the mini-X fragment semantics),
  [`gcd-spec.k`](gcd-spec.k) (the two K `claim`s + a spec-only `gcd`
  symbol).
- **Status:** specs **constructed, not machine-checked** (the MVP does not run
  `kompile`/`kprove`), **and** the loop-preservation crux sits at an explicit
  `[ESCALATION BOUNDARY]` (see below). The Findings (see [`FINDINGS.md`](FINDINGS.md))
  hold today regardless.
- **Default scope:** **partial correctness** — the contract constrains terminating
  runs; termination itself is a recommendation (and for `gcd` it is *clean* — see
  Findings), not the default proof obligation.

## What is specified

### Function contract — `(GCD)`

> **Precondition:** `a >= 0` and `b >= 0`.
> **Postcondition:** `gcd(a, b) = gcd(A, B)` — the result *is* the mathematical
> greatest common divisor of the inputs.

To even **state** this contract we introduce a **spec-only symbol** `gcd(Int, Int)`
(declared `[function, total]` in the `VERIFICATION` module). It is **verification
vocabulary, not a language construct** — the program never mentions it; it exists
only so the postcondition can say "the returned value equals the mathematical gcd."
Encoded as a reachability claim: from a configuration that *defines* `gcd` and
*calls* it on symbolic `A, B >= 0`, execution terminates with
`result |-> gcd(A, B)`.

### Loop invariant — `(LOOP)` (the circularity): a **preserved relation**

> From any state with `a = A`, `b = B`, and `A, B >= 0`, running the loop reaches
> `a = gcd(A, B)`, `b = 0`.

This is the structurally interesting part, and it differs sharply from the
`sum` examples. The sum loop carried an **accumulator** and a **polynomial closed
form** `(I+N)*(N-I+1)/2`. **The gcd loop carries no accumulator.** Its invariant is
a **preserved RELATION** — the quantity `gcd(a, b)` is *invariant* across every
iteration:

1. **The body** `a, b = b, a % b` rewrites the pair `(a, b) -> (b, a mod b)`.
2. **The math identity** `gcd(a, b) = gcd(b, a mod b)` (the **Euclid identity**)
   says this rewrite *does not change* `gcd(a, b)`. So `gcd(a, b)` is the loop's
   invariant — held constant, not accumulated.
3. **The loop ends at `b = 0`** (the `while b:` truthiness guard is false exactly
   when `b == 0`), and `gcd(a, 0) = a`, so the final `a` *is* `gcd(A, B)`.

Generalized over **both** `a` and `b` (not pinned to entry values), this is the
loop's reachability claim; K's prover uses it as its own coinduction hypothesis, so
it **discharges its own loop** — replacing a hand-written invariant. The post-value
`gcd(A, B)` plays the role the classical invariant used to.

**Two things specific to this program** (the mirror of the sum examples' two):

1. **No accumulator, no counter arithmetic — a preserved relation instead.** There
   is nothing like `s += i`. The "invariant" is an *equation between two `gcd`
   applications*, kept true by the Euclid identity. This is why `(LOOP)` needs no
   exact-halving lemma and no polynomial; it needs **one number-theoretic identity**.
2. **The crux identity is at the escalation boundary.** The Euclid step
   `gcd(a, b) = gcd(b, a mod b)` (for `b != 0`) is an **inductive number-theoretic
   fact**, not linear arithmetic or division-by-even. It is **outside the bundled
   simplification tier** and is marked `[ESCALATION BOUNDARY]` in
   [`gcd-spec.k`](gcd-spec.k) — **stated, not faked as `[trusted]`**.
   The base value `gcd(a, 0) = a` *is* clean and is supplied as a bundled
   `[simplification]`.

## How the function proof composes (for `/verify`)

`def` files the body → `call` binds `a = A`, `b = B` in a fresh scope →
**apply `(LOOP)` at `{a := A, b := B}`** (side condition `A, B >= 0` discharged by
the function precondition) → store reaches `a = gcd(A, B)`, `b = 0` →
`return a` delivers it → `result |-> gcd(A, B)`.

The **control-flow / structural** part of this composition is clean and inside the
fragment. The single thing that does **not** close in the bundled tier is the Euclid
identity used inside `(LOOP)` (see VC-EUCLID in [`PROOF.md`](PROOF.md)).

## The tuple-swap and truthiness modeling decisions (faithful, commented)

Two faithfulness points the semantics nails (full detail in
[`mini-python.k`](mini-python.k)):

- **Tuple swap `a, b = b, a % b` via a temp.** Python evaluates the *whole* RHS
  tuple `(b, a % b)` against the **old** store, then binds simultaneously. A naive
  `a = b; b = a % b` is **wrong** (after `a = b`, the second line computes
  `b % b = 0`). We desugar to `t = a; a = b; b = t % b`, with the temp `t` capturing
  the **old** `a`, so `b` becomes `(old a) mod (old b)` — exactly Python. `t` is a
  fresh name gcd never uses.
- **Truthiness guard `while b:`.** Python's `while b:` runs the body iff `b != 0`.
  We coerce a bare integer guard `b` to the boolean `b =/= 0` — the only Boolean
  fact gcd needs (no general `if`, no boolean algebra).

## Mini-X semantics scope (only what the code touches)

Integer literals/names, `%` (modulo, modeled by K's floor `modInt` — matches Python
exactly for non-negative operands), assignment, the tuple swap, the truthiness
`while`, `def`, `return`, call. **No `if`**, **no `+`/`<=`/`+=`** (this program uses
none of them). `gcd.py` includes an inline `__main__` test block; the spec covers the
**pure function** `gcd` — the asserts are point-checks mapped in
[`PROOF.md`](PROOF.md)'s test-redundancy table.

## Next step

Run the kit's **`/verify`** to construct the proof of these claims, emit the
`kompile`/`kprove` commands, get the test-redundancy recommendation, and itemize the
`[ESCALATION BOUNDARY]` obligation (the Euclid identity) routed to the sources.
