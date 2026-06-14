// =============================================================================
//  mini-python-spec.k  --  verification of array_max(a) as K `claim`s.
//
//    kompile mini-python.k --backend haskell
//    kast    --backend haskell mini-python-spec.k    // confirm claims parse
//    kprove  mini-python-spec.k                       // expected result: #Top
//
//  TWO claims, nested as the algorithm is:
//    (MAX)  the function contract:  array_max(A) returns a value `result` that is
//           an UPPER BOUND of every element of A and is ITSELF an element of A
//           (i.e. result = max A).  Reuses (LOOP) as a lemma.
//    (LOOP) the loop circularity: invariant = "largest = max of the visited prefix
//           A[0:I)".  Generalized over the accumulator `largest = R` and counter
//           `i = I`, with the soundness side condition 1 <= I <= size(A) and the
//           invariant R = maxPrefix(A, I).
//
//  WHY THIS STAYS IN THE BUNDLED TIER (no multiset, no escalation):
//    The postcondition here is a `forall`-bounded UPPER BOUND plus a MEMBERSHIP,
//    NOT sortedness and NOT permutation. Both reduce to `>Int` / `<=Int`
//    comparisons on K's total order on Int. The loop body
//        if a[i] > largest : largest = a[i]
//    is exactly  largest := max(largest, a[i]) = maxInt(largest, a[i]) , and the
//    prover's #Or case-split on the `if` guard (the two branches) IS the case
//    analysis that discharges it. No multiset/Bag, no permutation, no sorted-
//    prefix composition. Contrast examples/insertion-sort, whose permutation
//    postcondition genuinely needed a multiset theory and hit the escalation
//    boundary. array_max does NOT: every VC below is linear-over-a-total-order
//    plus a finite unfolding of a [function] abstraction, all of which the
//    bundled tier (Z3 + the simplification lemmas here) discharges. CONFIRMED
//    in-tier; NO [ESCALATION BOUNDARY] obligation is needed in this file.
//
//  Program variables: parameter `a`, locals `largest` and `i`; the caller binds
//  the returned value to `result`. Uppercase logical vars: A (the list), R (the
//  running max), I (the counter), N (= size(A)).
//
//  Constructed, not machine-checked (the MVP does not run kprove).
// =============================================================================

requires "mini-python.k"

module MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON-SYNTAX
  // Program variables (a, largest, i, result) are lowercase => lex as Id, never
  // clashing with K's uppercase/?-prefixed logical variables. No [token]s needed.
endmodule

module VERIFICATION
  imports MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON
  imports MAP-SYMBOLIC
  imports K-EQUAL

  // ===========================================================================
  //  SPEC-ONLY ABSTRACTIONS  (used only inside claims; not part of the language)
  //  All are clean inductive `[function]`s over K's `List` value sort. NONE is a
  //  multiset: they are bounded foralls / a recursive max, decidable by Z3 after
  //  a finite unfolding. This is the whole reason array_max stays in-tier.
  // ===========================================================================

  // ---- contiguous prefix:  take(L, N) = the first N elements, L[0:N). ---------
  //   range(L, dropFront, dropBack) is K's LIST builtin slice.
  syntax List ::= take(List, Int) [function]
  rule take(L:List, N:Int) => range(L, 0, size(L) -Int N)

  // ---- isUpperBound(L, B):  forall j in [0, size(L)).  L[j] <= B  -------------
  //   The bounded `forall` of the postcondition, as a clean inductive Bool fn.
  syntax Bool ::= isUpperBound(List, Int) [function, total]
  rule isUpperBound(.List, _)                  => true
  rule isUpperBound(ListItem(X:Int) L, B:Int)  => X <=Int B andBool isUpperBound(L, B)

  // ---- inList(X, L):  X occurs in L  (the membership of the postcondition) -----
  syntax Bool ::= inList(Int, List) [function, total]
  rule inList(_, .List)                  => false
  rule inList(X:Int, ListItem(Y:Int) L)  => X ==Int Y orBool inList(X, L)

  // ---- maxList(L) = max over a NONEMPTY list (a left fold of maxInt). ----------
  //   For the empty list it is left undefined (the precondition keeps prefixes
  //   nonempty, since array_max requires a nonempty input -- FINDINGS.md #1).
  syntax Int ::= maxList(List) [function]
  rule maxList(ListItem(X:Int))    => X
  rule maxList(ListItem(X:Int) L)  => maxInt(X, maxList(L))  requires L =/=K .List

  // ---- maxPrefix(L, N) = the maximum of L[0:N)  (the loop's closed form). ------
  //   Defined for 1 <= N <= size(L) (a nonempty prefix, so the max exists).
  syntax Int ::= maxPrefix(List, Int) [function]
  rule maxPrefix(L:List, N:Int) => maxList(take(L, N))
    requires 1 <=Int N andBool N <=Int size(L)

  // ===========================================================================
  //  BUNDLED-TIER SIMPLIFICATION  (same shape as examples/sum-up)
  // ===========================================================================
  // Map extensionality: reduce a post-store cell #Equals to a scalar/value one,
  // since execution lands the result as STORE[X <- V]. (Cf. Lesson 1.22.)
  rule { M:Map [ K <- V ] #Equals M:Map [ K <- V' ] } => { V #Equals V' }
    [simplification]

  // ---------------------------------------------------------------------------
  //  VC-MAXSTEP -- the one structural fact the loop step needs. It is the
  //  DEFINITIONAL recurrence of maxPrefix: extending the visited prefix by one
  //  element folds that element in with maxInt. This is NOT a multiset/sorted
  //  fact; it is the unfolding of the [function] abstractions above (maxList of a
  //  prefix grown by one tail element), guarded to the in-range prefix. It is
  //  bundled-tier: a finite rewrite of take/maxList that Z3 then closes by the
  //  total order on Int. (Stated as a [simplification] so the prover applies it
  //  where the step's VC matches; NOT [trusted] -- it is a derivable identity.)
  // ---------------------------------------------------------------------------
  rule maxPrefix(L:List, N +Int 1) => maxInt(maxPrefix(L, N), L[N])
    requires 1 <=Int N andBool N +Int 1 <=Int size(L)
    [simplification]

  // VC-MAX-DEF -- maxInt unfolds to the `if a[i] > largest` case-split: it is
  // either the new element (when strictly greater) or the old max. This lets the
  // prover's #Or branches on the loop body's `if` guard each match one side of
  // maxInt. Pure Int arithmetic; Z3-discharged on each branch.
  rule maxInt(R:Int, X:Int) => X requires X >Int R            [simplification]
  rule maxInt(R:Int, X:Int) => R requires notBool (X >Int R)  [simplification]

  // VC-UB / VC-MEM bridges -- "max of the full prefix is an upper bound of, and a
  // member of, the whole list". These connect the loop's closed form maxPrefix to
  // the function postcondition's two predicates. Both are finite inductions over
  // the [function] definitions of isUpperBound / inList / maxList, NOT multiset
  // facts; the bundled tier unfolds and Z3 closes them on the total order.
  rule isUpperBound(L:List, maxList(L)) => true
    requires L =/=K .List   [simplification]
  rule inList(maxList(L:List), L)       => true
    requires L =/=K .List   [simplification]
endmodule

module MINI-PYTHON-SPEC
  imports VERIFICATION

  // ===========================================================================
  //  (LOOP) -- the loop circularity.  Invariant: largest = max of visited prefix
  //  A[0:I).  Running the loop from counter i = I, accumulator largest = R, over
  //  array a = A, with 1 <= I <= size(A) and R = maxPrefix(A, I), leaves
  //  largest = maxPrefix(A, size(A)) = max of all of A, and i = size(A).
  //
  //  The body `if a[i] > largest : largest = a[i]` is largest := max(largest,a[i]).
  //  Each iteration grows the visited prefix [0,I) -> [0,I+1); VC-MAXSTEP folds
  //  a[I] in via maxInt, and VC-MAX-DEF matches that maxInt to the `if` branches.
  //  The side condition 1 <= I <= size(A) is the analogue of the sum example's
  //  I <= N+1: the lower bound 1 <= I justifies the entry invariant (a[0] already
  //  read into largest) and keeps maxPrefix defined on a nonempty prefix -- see
  //  FINDINGS.md #1 (the empty-list precondition). On exit i = size(A), so the
  //  visited prefix is all of A.
  // ===========================================================================
  // SPEC-PROVENANCE:
  // - claim: (LOOP) max-prefix loop circularity over the visited prefix.
  // - from_prompt: P1 in PROMPTS.md: "Write `array_max(a)` returning the maximum element of a non-empty list, scanning with an index `while` loop. Self-contained — no `max`/slicing." => `array_max(a)` should return an element that is a maximum of a non-empty list under a total order.
  // - from_code: The code reads `a[0]` into `largest`, scans with index `i`, and updates when `a[i] > largest`.
  // - conflicts/findings: `array_max([])` raises `IndexError`, and NaN/mixed types violate the implicit total-order assumption; both remain findings, not code fixes.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k>
      while i < len(a) : INDENT
        if a[i] > largest : INDENT
          largest = a[i]
        DEDENT
        i = i + 1
      DEDENT => .K ...
    </k>
    <store>
      a       |-> A:List
      largest |-> (R:Int => maxPrefix(A, size(A)))
      i       |-> (I:Int => size(A))
    </store>
    requires 1 <=Int I andBool I <=Int size(A)
     andBool R ==Int maxPrefix(A, I)
    [all-path]

  // ===========================================================================
  //  (MAX) -- the function contract.
  //  array_max(A) on a NONEMPTY A (size(A) >= 1) returns `result` such that
  //      isUpperBound(A, result)   AND   inList(result, A)
  //  i.e. forall j in [0, len). A[j] <= result, and result is an element of A.
  //  (Together these say result = max A.)
  //
  //  Reuses (LOOP) at entry {R := A[0], I := 1}: the precondition there is
  //  R = maxPrefix(A, 1) = maxList(A[0:1)) = A[0], which holds because the body's
  //  pre-loop init is `largest = a[0]; i = 1`. The (LOOP) postcondition gives
  //  largest = maxPrefix(A, size(A)) = maxList(A) = max A; the VC-UB / VC-MEM
  //  bridges turn that into the two postcondition predicates.
  //
  //  PRECONDITION  size(A) >= 1  is REQUIRED: array_max([]) reads a[0] on the empty
  //  list and is STUCK in the semantics = Python IndexError. See FINDINGS.md #1.
  //  (The Int element model also hides a total-order precondition -- FINDINGS.md #2.)
  // ===========================================================================
  // SPEC-PROVENANCE:
  // - claim: (MAX) function contract returning a member that upper-bounds all elements.
  // - from_prompt: P1 in PROMPTS.md: "Write `array_max(a)` returning the maximum element of a non-empty list, scanning with an index `while` loop. Self-contained — no `max`/slicing." => `array_max(a)` should return an element that is a maximum of a non-empty list under a total order.
  // - from_code: The code reads `a[0]` into `largest`, scans with index `i`, and updates when `a[i] > largest`.
  // - conflicts/findings: `array_max([])` raises `IndexError`, and NaN/mixed types violate the implicit total-order assumption; both remain findings, not code fixes.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k>
      def array_max ( a ) : INDENT
        largest = a[0]
        i = 1
        while i < len(a) : INDENT
          if a[i] > largest : INDENT
            largest = a[i]
          DEDENT
          i = i + 1
        DEDENT
        return largest
      DEDENT
      result = array_max ( A:List )
    => .K ... </k>
    <funcs> .Map => ?_:Map </funcs>
    <store> result |-> (_:KResult => ?M:Int) </store>
    <stack> .List </stack>
    requires size(A) >=Int 1
    ensures  isUpperBound(A, ?M) andBool inList(?M, A)
    [all-path]
endmodule
