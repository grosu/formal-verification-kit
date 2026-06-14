# PROOF — `average(nums)` reachability proof

`average` is now **self-contained**: it sums with an explicit `while` loop and then
divides by the length. So — unlike the previous `return sum(nums) / len(nums)`
version — there IS a loop, and the proof has the **`sum-up` two-claim shape**: a loop
circularity `(LOOP)` plus a function contract `(AVG)` that reuses it. The headline
benefit of the rewrite: the loop step is **definitional/clean**, so the proof is
**escalation-FREE** except for one mild spec-symbol-totality obligation (§4).

**Status: constructed, not machine-checked.** The toolchain was not run (MVP
stopgap). `#Top` from `kprove` is what would upgrade "constructed" → "machine-checked".
The *Findings* (benefit 2, [`FINDINGS.md`](FINDINGS.md)) hold today regardless — and
the headline empty-list bug was **executed against the real code** (§5).

Artifacts (same directory): [`average.py`](average.py) ·
[`mini-python.k`](mini-python.k) (fragment semantics) ·
[`average-spec.k`](average-spec.k) (the two claims) ·
[`SPEC.md`](SPEC.md) / [`FINDINGS.md`](FINDINGS.md) (the `/formalize` outputs).

The program ([`average.py`](average.py)):

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

Abbreviation used throughout: **`ls(lo,hi) := listsum(NUMS, lo, hi)`** = the sum of
`NUMS[lo], …, NUMS[hi-1]` (the half-open range `NUMS[lo:hi)`), the spec-only inductive
range fold from [`average-spec.k`](average-spec.k). The whole-list sum is
`ls(0, size(NUMS))`.

---

## 1. The reachability spec — the (AVG) function claim

The contract is one reachability rule `φ_pre ⇒ φ_post`: from a configuration that
*defines* `average` and *calls* it on a symbolic **non-empty** list `NUMS`, execution
reaches a terminated configuration whose `result` holds the integer mean
`ls(0, size(NUMS)) /Int size(NUMS)`.

```
  φ_pre  ≡ ⟨ def average(nums): total=0  i=0  n=len(nums)
               while i<n: (total=total+nums[i]; i=i+1)  return total/n
             result = average(NUMS) ⟩_k
           ⟨ result ↦ _ ⟩_store  ⟨ .Map ⟩_funcs  ⟨ .List ⟩_stack   ∧   size(NUMS) ≥ 1
  φ_post ≡ ⟨ .K ⟩_k  ⟨ result ↦ ls(0,size(NUMS)) /Int size(NUMS) ⟩_store
           ⟨ ?_ ⟩_funcs  ⟨ .List ⟩_stack
```

(The `(AVG)` claim verbatim is in [`average-spec.k`](average-spec.k).)
`<funcs> .Map => ?_:Map` says some function table now exists; `<stack> .List` says the
call stack is balanced; `[all-path]` is sound because mini-Python is deterministic
(all-path ≡ one-path, as in `sum-up`). **Partial correctness** — but here essentially
total: the loop's measure `n - i` strictly decreases (FINDINGS.md "termination").

**The precondition `size(NUMS) ≥ 1` is load-bearing.** It is exactly what discharges
the final division rule's side condition `size(NUMS) =/=Int 0`. Drop it and the proof
stalls on the empty list — the formal mirror of the runtime `ZeroDivisionError`
(Finding 1). This is the missing precondition the code never states.

---

## 2. The loop circularity — the (LOOP) claim

The proof turns on one auxiliary claim about the loop, generalized over the
accumulator `T` and the counter `I`, with side condition `0 ≤ I ≤ N` (`N = size(NUMS)`)
and the running prefix-sum `ls(I, N)`:

```
  (LOOP)   ⟨ while i<n: (total=total+nums[i]; i=i+1)
           | total↦T, i↦I, n↦N, nums↦NUMS ⟩  ∧  0 ≤ I ≤ N ∧ N = size(NUMS)
       ⇒   ⟨ .K | total ↦ T + ls(I,N),  i ↦ N,  n ↦ N,  nums ↦ NUMS ⟩
```

It reads: *running the loop from counter `i = I` (with `0 ≤ I ≤ N`) adds the suffix sum
`ls(I,N) = Σ NUMS[I:N)` to `total` and leaves `i = N`.* At the entry `I = 0` this gives
the whole-list sum `ls(0,N)`. The "running prefix-sum" `total = ls(0,i)` plays the role
the classical loop invariant used to.

---

## 3. Informal proof (English)

Reachability logic replaces the hand-chosen *loop invariant* with **coinduction**: K
adds every claim in the module to its hypotheses, so **(LOOP) may assume itself** while
proving itself — *provided* it first makes one genuine step (guardedness). The running
prefix-sum `ls` plays the role the invariant used to.

**Prove (LOOP).** Run the loop one step. `(while)` evaluates the guard `i < n` — that
genuine first step earns the right to reuse the hypothesis — then case-split:

- **Guard true (`I < N`):** the body runs. `total = total + nums[i]` reads `nums[I]`
  (in bounds, since `0 ≤ I < N = size(NUMS)`) and makes `total = T + NUMS[I]`;
  `i = i + 1` makes `i = I + 1`; control returns to the same `while`. **Invoke (LOOP)
  itself** at `T := T + NUMS[I], I := I+1` (its precondition `0 ≤ I+1 ≤ N` follows from
  `0 ≤ I < N`). The one arithmetic fact to check is the **clean, definitional step**:
  `NUMS[I] + ls(I+1, N) = ls(I, N)` — *exactly the unfold (defining) equation of the
  fold `ls`*. No division, no truncation. ✓
- **Guard false (`I ≥ N`, and `I ≤ N` from the precondition):** then `I = N`, the body
  never runs, `total` is unchanged, and the empty range gives `ls(N, N) = 0`. So
  `total = T + 0` and `i = N`. ✓

Both branches land on (LOOP)'s post-state, and the hypothesis was used only after a
real step, so the circularity discharges. The side condition **`0 ≤ I ≤ N` is the load
bound** but (unlike `sum-up`'s `I ≤ N+1`) it is satisfied by construction — a plain
index walk, no off-by-one (Finding 6).

**Prove (AVG).** Execute the program against the semantics: `def average` files the
body into `<funcs>`; `result = average(NUMS)` evaluates the argument, and `(call)`
pushes the caller's frame, gives the callee a fresh scope, and binds `nums = NUMS`. The
body runs `total = 0`, `i = 0`, `n = len(nums) = size(NUMS)`, then the loop — and here
we **use (LOOP) as a lemma** at `T = 0, I = 0` (its precondition `0 ≤ 0 ≤ N` follows
from `N = size(NUMS) ≥ 1`), making `total = 0 + ls(0, N) = ls(0, N)` and `i = N`. Then
`return total / n` fires the **division rule** — **because `size(NUMS) ≥ 1` makes the
divisor `n = N` non-zero** — delivering `ls(0,N) /Int N`. `return` pops the frame,
restores the caller store, and the value is assigned to `result`. Final store:
`result ↦ ls(0, size(NUMS)) /Int size(NUMS)` — exactly the spec. ∎

---

## 4. Machine-detailed proof sketch (for `kprove`)

Each step cites a rule of [`mini-python.k`](mini-python.k); VCs go to Z3 + the
`[simplification]` lemmas (the fold's own equations + map extensionality) in
[`average-spec.k`](average-spec.k).

**PART A — (LOOP) by circularity.** Reuse (LOOP) only after ≥ 1 genuine rewrite.
- **A1 progress:** `(while)` → `(i<n) ~> #whileLoop(i<n, Bdy)`. This `=>+` transition
  discharges guardedness.
- **A2 guard:** `<` is `seqstrict` → `(lookup)` `i⇒I`, `n⇒N`; `(lt)` → `I <Int N`.
- **A3 split** (`#Or` on `I <Int N` under `0 <=Int I <=Int N`):
  - **true / `(while-t)`:** rebuild the `while` (never an `if`); the body:
    `total = total + nums[i]` — `+` is `seqstrict`: `(lookup)` `total⇒T`, `(lookup)`
    `nums⇒NUMS`, `(lookup)` `i⇒I`, index read `NUMS[I]` (in bounds: `0 ≤ I < size(NUMS)`),
    `(add)` ⇒ `T +Int NUMS[I]`, `(asgn)` `total ↦ T +Int NUMS[I]`; then `i = i + 1` ⇒
    `i ↦ I +Int 1`. **Reuse (LOOP)** at `{T := T +Int NUMS[I], I := I +Int 1}`.
    Closes via **VC-STEP**.
  - **false / `(while-f)`:** antisymmetry ⇒ `I = N`; store unchanged. Closes via
    **VC-EXIT** (`ls(N,N) = 0`).

**PART B — (AVG) over the real call layer.**
`(def)` files the body (witnesses `?_:Map`) → arg eval + `(call)` pushes
`state(CONT, STORE)`, resets `<store>` to `.Map` → `#makeBindings((nums),(NUMS))` binds
`nums ↦ NUMS` → `(asgn)` `total ↦ 0`, `i ↦ 0`, `(len)` `n ↦ size(NUMS)` → **apply
(LOOP) at `{T := 0, I := 0}`** (precondition `0 ≤ 0 ≤ size(NUMS)` from
`size(NUMS) ≥ 1`), `total ↦ ls(0, size(NUMS))` (**VC-INIT**, trivial: `0 + ls = ls`) →
`return total / n`: `/` is `seqstrict` → `total⇒ls(0,size)`, `n⇒size(NUMS)`; `(div)`
fires, side condition `size(NUMS) =/=Int 0` discharged by **Z3** from `size(NUMS) ≥ 1`
→ `ls(0,size) /Int size` → `(return)` pops the frame, restores caller store, delivers
the `Int` → `(asgn)` `result ↦ ls(0,size(NUMS)) /Int size(NUMS)`. Map-extensionality
`[simplification]` reduces the post-store cell `#Equals` to the value-level obligation.

**Verification conditions.**

| VC | Statement | Discharged by |
|---|---|---|
| **VC-STEP** | `NUMS[I] + ls(I+1, N) = ls(I, N)`  (loop step) | the fold's **own unfold equation** `[simplification]` — **clean / definitional** ✓ |
| **VC-EXIT** | `I = N ⇒ ls(N, N) = 0`  (loop exit, empty range) | the fold's **base equation** + Z3 ✓ |
| **VC-INIT** | `0 + ls(0,N) = ls(0,N)`  (loop entry) | Z3 (additive identity) ✓ |
| **VC-nz** | `size(NUMS) ≥ 1 ⇒ size(NUMS) =/=Int 0`  (division side condition) | **Z3** (linear) ✓ |
| **VC-ext** | post-store cell `#Equals` ⇒ value | **map-extensionality `[simplification]`** ✓ |
| **TOTAL-ls** | `listsum` is `[function, total]` (defined on every `(L,lo,hi)`) | **`[ESCALATION BOUNDARY]`** — structural induction on `hi - lo`; routed to OOPSLA'20 / LICS'19 ✗(stated, not admitted) |

So **every arithmetic / control VC discharges with the bundled tier** — Z3, the fold's
own defining equations, and map extensionality. The loop step (**VC-STEP**), which in
the builtin-`sum()` version was a *truncating-`/Int` divisibility* fact (a genuine
escalation), is here **just one fold unfold**: pure, definitional, no division. The
**only** open obligation is **TOTAL-ls**, the totality of the spec-only fold symbol —
a *mild structural-induction housekeeping* fact, **far weaker** than the previous
version's boundary, **stated, NOT admitted as `[trusted]`** (Finding 5).

> **Honest note — int-vs-float (Finding 3).** The result `ls(0,size) /Int size` is the
> **integer (truncating) mean**. Python's `/` is **true** division, so the real code
> returns a **float** — and `average([1,2]) == 1.5`, which the inline test asserts and
> which the `/Int` model does **not** match (it gives `1`). A precise contract for the
> *true* mean relates `result` to `ls / size` over **Rationals** — a Float/Rational
> theory, a separate `[ESCALATION BOUNDARY]`. The integer-mean contract above is exact
> on its (remainder-0) domain. This is the only modeling gap; the loop itself is exact.

---

## 5. FINDINGS — benefit 2 (these do NOT depend on machine-checking)

Formalizing surfaced real, **executed** findings — full detail in
[`FINDINGS.md`](FINDINGS.md). The headline:

> **The headline bug — ZeroDivisionError on the empty list (Finding 1).**
> Constructing a clean contract forced the precondition `len(nums) >= 1`. Violate it
> and the function crashes. **Executed:**
>
> | input | observed | expected |
> |---|---|---|
> | `[]` | **`ZeroDivisionError: division by zero`** | undefined (no mean of `[]`) |
>
> The empty list skips the loop (`total = 0`), then `n = 0`, and `total / n = 0 / 0`
> raises. In the semantics the division rule's `requires I2 =/=Int 0` is unsatisfiable
> on `n = 0`, so the configuration is **stuck** — the formal mirror of the exception.
> Recommendation: guard it (`if not nums: raise ValueError(...)`), document
> `len(nums) >= 1`, or define a total fallback. This is the missing precondition the
> code never states.

> **A load-bearing modeling choice — int-vs-float division (Finding 3).** Python's `/`
> is **true** division (returns a float; `[1,2] → 1.5`); the model uses `/Int`
> (truncates; `[1,2] → 1`). The model is faithful **only when `len` divides `sum`**.
> The inline tests include `average([1,2]) == 1.5`, which pins the **float** intent and
> would fail under integer division — so the *intended* contract is the true mean,
> needing a Rational theory (escalation). Invisible to a quick read; the spec made it
> explicit.

> **Escalation status (Finding 5) — the loop is escalation-FREE.** Because the sum is
> now an explicit loop adding the actual element, the loop step VC is the fold's clean
> **unfold equation** — no truncating division. Every control / arithmetic VC
> discharges with the bundled tier. The **only** residual is the *totality* of the
> spec-only `listsum` fold — a mild structural-induction obligation, **stated, not
> `[trusted]`**, routed to OOPSLA'20 / LICS'19
> ([`knowledge/sources.md`](../../../formal-verification-kit/knowledge/sources.md);
> `/verify --refresh` re-fetches). **This is strictly milder than the previous
> builtin-`sum()` version**, whose boundary was the entanglement of the fold with
> divisibility-under-truncating-`/Int`.

---

## 6. TEST REDUNDANCY — benefit 1 (conditioned — do not delete anything yet)

> A verified function is proven for *all* inputs in its domain, so in-domain unit tests
> that re-check single points become redundant — **once the proof actually discharges.**
> Here that is gated (see the Honesty gate below).

The inline tests in [`average.py`](average.py):

```python
assert average([1, 2, 3]) == 2
assert average([10]) == 10
assert average([2, 4]) == 3
assert average([-1, 1]) == 0
assert average([1, 2]) == 1.5
assert average([0, 0, 0]) == 0
```

If `(AVG)` were machine-checked (and `listsum`'s totality supplied), it would prove
`result = ls(0,len) /Int len` — the **integer (truncating) mean** — for **every
non-empty integer list**. The tests map as follows:

| Test | In verified domain? | `len` divides `sum`? | Status |
|---|---|---|---|
| `average([1,2,3]) == 2` | yes (non-empty Int list) | yes (`6 / 3`) | *would-be* redundant |
| `average([10]) == 10` | yes | yes (`10 / 1`) | *would-be* redundant |
| `average([2,4]) == 3` | yes | yes (`6 / 2`) | *would-be* redundant |
| `average([-1,1]) == 0` | yes | yes (`0 / 2`) | *would-be* redundant |
| `average([0,0,0]) == 0` | yes | yes (`0 / 3`) | *would-be* redundant |
| `average([1,2]) == 1.5` | **non-integer mean** — **outside the `/Int` model** | **no** (`3 / 2`) | **KEEP** — Finding 3 (int-vs-float) |

- **KEEP `average([1, 2]) == 1.5`.** It is the **non-integer mean** the integer-mean
  contract does not cover (`/Int` gives `1`, not `1.5`). It pins the **float intent**
  and is exactly where Finding 3 lives — keep it (and it is what tells you the contract
  should ultimately be the *true* mean, needing the Rational escalation).
- **ADD the missing out-of-domain boundary test.** There is currently **no** test for
  the empty list — the Finding-1 boundary, the **headline bug**. Add `average([])` and
  assert it raises (`pytest.raises(ZeroDivisionError)`), or (if you add a guard)
  `ValueError`. This is the analogue of `sum-up` keeping `sum_to_n(-1)`; it guards the
  boundary the proof does **not** cover.

**Honesty gate.** Do **not** drop any test now, for **two** reasons: (1) the MVP did not
run `kprove` ("constructed, not machine-checked"), and (2) one obligation
(`listsum` totality, TOTAL-ls) is an open `[ESCALATION BOUNDARY]` — so `(AVG)` is not
yet constructed-to-`#Top` on paper. The five "*would-be* redundant" integer-mean tests
become *actually* redundant only after **both**: the fold-totality obligation is
supplied **and** `kprove` returns `#Top`. Until then, **keep all of them.** (Even then,
keep `[1,2]==1.5` and add `average([])` — both are out of the verified domain.)

---

## Reproduce the (attempted) machine check

```sh
kompile mini-python.k --backend haskell        # compile the fragment semantics
kast    --backend haskell average-spec.k   # (optional) confirm the claims parse
kprove  average-spec.k                       # EXPECTED: (LOOP) and the (AVG)
                                                 # call/division layer discharge; the
                                                 # only residual is listsum's totality
                                                 # (TOTAL-ls) -- the [ESCALATION
                                                 # BOUNDARY], until the inductive
                                                 # well-foundedness lemma is added.
```

`kprove` inherits the Haskell backend from the `kompile`d definition, so it needs no
`--backend haskell` of its own. Reaching a full `#Top` requires certifying `listsum`'s
totality (structural induction on `hi - lo`, per OOPSLA'20 / LICS'19); the loop step,
loop exit, division side condition, and post-store all discharge with the bundled tier.
Only after a genuine `#Top` are the §6 integer-mean test deletions safe.

---

*Status: constructed, not machine-checked; structurally complete and **escalation-free
at the loop/arithmetic level** — the lone open obligation is the totality of the
spec-only `listsum` fold (a mild structural induction), strictly milder than the
builtin-`sum()` version's truncating-divisibility boundary. References: kframework.org;
runtimeverification/k; K Tutorial Lesson 1.22. Roșu, "Matching Logic", LMCS 2017.
Chen & Roșu, "Matching μ-Logic", LICS 2019. Roșu & Ștefănescu, FM 2012 / LICS 2013
(reachability & Circularity). Chen et al., unified fixpoint reasoning, OOPSLA 2020
(inductive data structures).*
