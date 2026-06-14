# Findings report — `gcd.py`

Plain-language findings from formalizing [`gcd.py`](gcd.py). Each is
`input → observed vs expected`. **Non-blocking** — this report never edits or
deletes your code; it is advice. These findings **do not** depend on
machine-checking the proof — they are solid today.

---

## Finding 1 — missing precondition: non-negative inputs (`a >= 0`, `b >= 0`)

The docstring says "two **non-negative** integers", but the code never enforces it.
Writing a clean contract forced the guard `requires A >= 0 andBool B >= 0`. The
reason it is load-bearing: the loop uses Python's `%`, which is **floor** modulo —
its result takes the **sign of the divisor**. For non-negative operands `a % b` is
the usual remainder in `[0, b)`, the algorithm is the textbook Euclid, and the
result is a non-negative gcd. For **negative** inputs the behavior drifts from the
mathematical |gcd|:

| input `(a, b)` | code returns (observed) | mathematical gcd (expected) | agree? |
|---|---|---|---|
| `(12, 8)`  | `4`  | `4`  | OK |
| `(-12, 8)` | `4`  | `4`  | OK (Python floor `%` lands right here) |
| `(12, -8)` | `-4` | `4`  | NO (result is negative — sign of the divisor) |
| `(-12, -8)`| `-4` | `4`  | NO |

So for `(12, -8)` the function yields `-4` while gcd is `4` — they disagree in
**sign**. The function is specified (and only verified) on the non-negative domain
`a, b >= 0` — what `(GCD)`'s `requires A >= 0 andBool B >= 0` encodes.
**Recommendation:** document and/or enforce `a, b >= 0`, or normalize with
`a, b = abs(a), abs(b)` up front if negative inputs must be supported.

## Finding 2 — the `gcd(0, 0)` edge case: returns `0` (a convention, flag it)

`gcd(0, 0)`: the guard `while b:` is false immediately (`b == 0`), the loop never
runs, and the function returns `a = 0`.

- input `(0, 0)` -> observed: `0`. The inline test `assert gcd(0, 0) == 0` pins this.
- Mathematically `gcd(0, 0)` is **undefined as a "greatest"** common divisor (every
  integer divides `0`, so there is no greatest), but the **conventional** value is
  `0` (it is the identity of the gcd monoid, and matches `math.gcd(0, 0) == 0`).

The code returns the conventional `0` — **correct by convention**, but worth naming
because it is the one input where "greatest common divisor" has no literal meaning.
This is consistent with the `(GCD)` contract: the spec-only symbol `gcd` satisfies
`gcd(a, 0) = a`, so `gcd(0, 0) = 0` falls straight out of the base case. No action
needed; just be aware the result is a *convention*, not a maximum.

Adjacent (a deliberate non-finding): `gcd(0, 5)` -> first iteration swaps to
`(5, 0)` -> returns `5`; `gcd(5, 0)` -> loop never runs -> returns `5`. Both correct;
the algorithm is symmetric in effect even though the body is not, because the first
iteration swaps a zero second argument into first position.

## Finding 3 — spec-difficulty signal = ESCALATION, not a code defect

Constructing the loop circularity `(LOOP)` is **structurally clean** but its
preservation step rests on one fact the bundled simplification tier cannot
discharge: the **Euclid identity**

> `gcd(a, b) = gcd(b, a mod b)`   (for `b != 0`).

This is an **inductive number-theoretic** identity (it follows from the divisibility
lattice / Bezout's identity), **not** linear arithmetic and **not** division-by-even
— so it is **outside** the kit's bundled VC tier. Per the kit's discipline this is a
**capability boundary, not a correctness bug**: the code is right; the *automated
proof* needs more theory.

- It is **stated** as an explicit `[ESCALATION BOUNDARY]` obligation (VC-EUCLID) in
  [`gcd-spec.k`](gcd-spec.k) and [`PROOF.md`](PROOF.md) — and is
  **deliberately NOT** supplied as a `[simplification]` rule and **NOT** marked
  `[trusted]`. Admitting it either way would manufacture confidence the kit does not
  have.
- **Route:** number theory is not a matching-logic primitive; the inductive-reasoning
  machinery is the **mu-logic line** (LICS'19 / OOPSLA'20 in
  `knowledge/sources.md`; `/verify --refresh` re-fetches them). The durable fix is a
  number-theory lemma library (a worked gcd example is a natural seed for the kit).

By contrast, the **base value** `gcd(a, 0) = a` *is* clean and **is** supplied as a
bundled `[simplification]`, and the entire **control-flow** of the proof (loop exits
at `b = 0`, composition through `def`/`call`/`return`) is inside the fragment.

## Note — termination (partial vs total correctness): this one is CLEAN

The kit's default is **partial correctness** (it says nothing about halting). For
`gcd` total correctness is **easy and worth noting**, because there is an obvious
decreasing measure: **`b` itself**.

- Each iteration sets `b := a mod b`. For the entry `b > 0`, `a mod b` is in `[0, b)`,
  so **`b` strictly decreases** and is **bounded below by `0`**. A strictly-decreasing
  natural number cannot decrease forever, so the loop terminates after finitely many
  steps — for **every** `a, b >= 0`. (This is exactly why the algorithm is fast:
  `b` shrinks at least by a constant factor every two steps.)
- **Recommendation-only:** if you want termination machine-proved, add the variant
  `b` (bounded below by `0`, strictly decreasing each iteration: `a mod b < b` for
  `b > 0`) to `(LOOP)` and discharge it alongside the existing VCs. The
  strictly-decreasing fact `0 <= a mod b < b` is **linear once `b > 0`** (a property
  of `modInt`), so — unlike the *preservation* identity — termination does **not**
  hit the escalation boundary. Not attempted unless you ask.

---

*Next: run `/verify` to construct the proof of `(GCD)`/`(LOOP)`, get the
test-redundancy recommendation (benefit 1), and see the `[ESCALATION BOUNDARY]`
obligation (VC-EUCLID) itemized and routed. The `(12, -8) -> -4` and `(0, 0) -> 0`
rows above are exactly the out-of-domain / edge behavior any boundary test should
keep pinning.*
