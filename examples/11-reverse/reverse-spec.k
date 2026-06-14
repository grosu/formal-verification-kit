// =============================================================================
//  reverse-spec.k  --  verification of reverse(a) as K `claim`s.
//
//    kompile mini-python.k --backend haskell
//    kast    --backend haskell reverse-spec.k    // confirm claims parse
//    kprove  reverse-spec.k                       // GOAL: #Top  (see caveat)
//
//  TWO claims, matching the algorithm's single loop:
//    (REV)  the function contract:  reverse(A) returns the IN-PLACE reversal of A:
//           same length, out[i] = A[n-1-i] for all i, and a permutation of A.
//           Reuses (LOOP) as a lemma.
//    (LOOP) the two-pointer-swap loop circularity: invariant = "the band already
//           swapped at the two ends is the reversal of A's matching band; the
//           untouched middle [i, j] still equals A's middle; same length;
//           same multiset". Discharges its own loop.
//
//  POSTCONDITION SHAPE (this is what sets `reverse` between sum-up and
//  insertion-sort, see SPEC.md):
//    The contract is NOT a polynomial closed form (sum-up) and NOT a comparison
//    predicate (sortedness, insertion-sort). It splits into TWO halves:
//
//    (H-CLEAN) INDEX RELATION + LENGTH:  size(out) == size(A)  AND
//              out[I] == A[size(A) -Int 1 -Int I]  for all in-range I.
//              This half is FIRST-ORDER over positions: each position equality is
//              an index/`L[_]` fact discharged by the bundled tier (in-bounds
//              indices, map/list extensionality). It is the "clean" half -- the
//              analogue of sum-up's closed form -- and it is BUNDLED-TIER CLEAN.
//
//    (H-PERM)  PERMUTATION:  bag(out) ==K bag(A)  (multiset equality).
//              Multiset preservation across the swaps needs an inductive list/Bag
//              theory -- the SAME [ESCALATION BOUNDARY] the insertion-sort example
//              hits (see examples/insertion-sort/reverse-spec.k). Marked
//              [ESCALATION BOUNDARY] below; NOT admitted as [trusted].
//
//    LOGICAL NOTE (recorded honestly, not used to skip the obligation):
//      (H-PERM) is LOGICALLY REDUNDANT given (H-CLEAN): a length-preserving
//      bijection of positions (I |-> n-1-I is a bijection on [0,n)) carrying
//      out[I] = A[n-1-I] already implies out is a rearrangement of A, hence
//      bag(out) ==K bag(A). The kit's bundled tier still cannot MECHANIZE that
//      "index bijection => multiset equality" step (it is itself an inductive/
//      combinatorial fact over lists), so (H-PERM) remains an [ESCALATION
//      BOUNDARY] obligation despite being a semantic consequence of (H-CLEAN).
//      We keep both conjuncts in the contract for parallelism with insertion-sort
//      and to state the permutation property explicitly.
//
//  HONESTY / SCOPE BANNER  (read before trusting this file):
//    The (H-CLEAN) half (index relation + equal length) is constructed and rests
//    only on the bundled simplification tier (in-bounds index facts + map/list
//    extensionality). The (H-PERM) half is the kit's documented ESCALATION case
//    for "recursive data structures ... inductively defined predicates / multiset
//    reasoning (often mu)". See knowledge/sources.md: OOPSLA'20 (unified fixpoint
//    reasoning over inductive data structures) and LICS'19 (Matching mu-Logic).
//    Lemmas tagged  // [ESCALATION BOUNDARY]  are STATED (so the claims are
//    well-formed and the obligations explicit) but are NOT derivable from the
//    bundled tier; they are exactly what /verify routes upstream. Marking them
//    [trusted] would be DISHONEST, so they are left as explicit obligations.
//    This file is "constructed, not machine-checked" -- the strongest honest label.
// =============================================================================

requires "mini-python.k"

module MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON-SYNTAX
  // Program variables (a, i, j, tmp, out) are lowercase => lex as Id, never
  // clashing with K's uppercase/?-prefixed logical variables. No [token]s.
endmodule

module VERIFICATION
  imports MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON
  imports MAP-SYMBOLIC
  imports K-EQUAL

  // ===========================================================================
  //  SPEC-ONLY ABSTRACTIONS (used only inside claims; not part of the language)
  // ===========================================================================

  // ---- contiguous segments via K's range(L, dropFront, dropBack) -------------
  //   seg(L,A,B) = positions [A, B).  Used to name the three regions: the already
  //   reversed left/right bands and the untouched middle [i, j].
  syntax List ::= seg(List, Int, Int)    [function]
  rule seg(L:List, A:Int, B:Int) => range(L, A, size(L) -Int B)

  // ---- "this region of OUT mirrors that region of A" : the index relation -----
  //   isMirror(O, A, P, Q) holds iff  O[k] == A[size(A)-1-k]  for every k in [P,Q).
  //   The whole-list contract is isMirror(out, A, 0, size(A)). A clean inductive
  //   Bool function -- this is the (H-CLEAN) vocabulary.
  syntax Bool ::= isMirror(List, List, Int, Int) [function, total]
  rule isMirror(_, _, P:Int, Q:Int) => true requires P >=Int Q
  rule isMirror(O:List, A:List, P:Int, Q:Int)
       =>      (O [ P ]):>Int ==Int (A [ size(A) -Int 1 -Int P ]):>Int
       andBool isMirror(O, A, P +Int 1, Q)
    requires P <Int Q

  // ---- multiset abstraction: value |-> multiplicity (a count Map) -----------
  //   bag(X) ==K bag(Y)  <=>  X is a permutation of Y.  (Same as insertion-sort.)
  syntax Map ::= bag(List)        [function, total]
               | incr(Map, Int)   [function, total]
  rule bag(.List)                 => .Map
  rule bag(ListItem(X:Int) L)     => incr(bag(L), X)
  rule incr(M:Map, X:Int) => M [ X <- (({M[X]}:>Int) +Int 1) ] requires X in_keys(M)
  rule incr(M:Map, X:Int) => M [ X <- 1 ]                      requires notBool X in_keys(M)

  // ===========================================================================
  //  BUNDLED-TIER SIMPLIFICATION (same shape as examples/sum-up & insertion-sort)
  // ===========================================================================
  // Map extensionality, to reduce a post-store cell #Equals to a scalar/value one.
  rule { M:Map [ K <- V ] #Equals M:Map [ K <- V' ] } => { V #Equals V' }
    [simplification]

  // ===========================================================================
  //  [ESCALATION BOUNDARY] lemma -- STATED, not bundled-derivable.
  //  The single multiset fact the swap step needs. It requires an inductive
  //  list/Bag theory; /verify routes it to OOPSLA'20 / LICS'19 (see
  //  knowledge/sources.md). Tagging it [trusted] would be DISHONEST here, so it is
  //  left as an explicit obligation, NOT admitted.
  // ===========================================================================
  // (P1) a single two-position SWAP preserves the multiset:
  //        bag( L[I <- L[J]][J <- L[I]] )  ==K  bag(L)
  //      -- the crux of permutation-preservation per loop iteration. NEEDS a Bag
  //      theory with element delete/insert symmetry; not expressible in the count-
  //      Map above without a `decr` partial inverse. [ESCALATION BOUNDARY]
  //
  // (Equivalently, the whole-list fact: a length-preserving index BIJECTION
  //  I |-> size-1-I carrying out[I] = A[size-1-I] implies bag(out) ==K bag(A).
  //  See the LOGICAL NOTE in the header: (H-PERM) is a SEMANTIC CONSEQUENCE of
  //  (H-CLEAN), but mechanizing that implication is itself this inductive fact.)
  //
  // (Intentionally NOT written as `rule ... [simplification]` + [trusted]: doing
  //  so would manufacture confidence the kit does not have. The honest deliverable
  //  names it as an open obligation. See FINDINGS.md #6.)
endmodule

module MINI-PYTHON-SPEC
  imports VERIFICATION

  // ===========================================================================
  //  (LOOP) -- two-pointer-swap loop circularity.
  //  At the head of `while i < j`, array C, pointers I (left) and J (right). The
  //  invariant captures the three regions w.r.t. the ORIGINAL array A:
  //    PRE invariant:
  //      0 <= I,  J < size(C),  size(C) == size(A),  I +Int J == size(A) -Int 1
  //        (the two pointers are reflections of each other about the centre, which
  //         is why each step `i+=1; j-=1` keeps I+J constant = n-1)
  //      isMirror(C, A, 0, I)                  -- left band [0,I) already reversed
  //      isMirror(C, A, J +Int 1, size(A))     -- right band (J,n) already reversed
  //      seg(C, I, J +Int 1) ==K seg(A, I, J +Int 1)   -- middle [I,J] untouched
  //      bag(C) ==K bag(A)                     -- multiset preserved so far  [ESC]
  //  Running the loop to exit (i >= j) leaves the WHOLE array mirrored:
  //      isMirror(?D, A, 0, size(A))  AND  size(?D)==size(A)  AND  bag(?D)==K bag(A)
  //  The index-relation/length parts are (H-CLEAN); the bag part is (H-PERM) [ESC].
  // ===========================================================================
  // SPEC-PROVENANCE:
  // - claim: (LOOP) two-pointer mirror loop circularity.
  // - from_prompt: P1 in PROMPTS.md: "Write `reverse(a)` that reverses the list **in place** (two pointers, index swaps) and returns it. Self-contained — no slicing/`.insert`/`list()`." => `reverse(a)` should mutate the list in place so returned positions mirror the original positions, preserving the same elements.
  // - from_code: The code swaps `a[i]` and `a[j]` while moving two pointers inward, then returns `a`.
  // - conflicts/findings: FVK records mutation as a behavioral contract point and notes that no total-order precondition is needed; permutation preservation is escalation-bounded.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k>
      while i < j : INDENT
        tmp = a[i]
        a[i] = a[j]
        a[j] = tmp
        i = i + 1
        j = j - 1
      DEDENT => .K ...
    </k>
    <store>
      a   |-> (C:List => ?D:List)
      i   |-> (I:Int  => ?I2:Int)
      j   |-> (J:Int  => ?J2:Int)
      tmp |-> (_:KResult => ?_:KResult)
    </store>
    requires 0 <=Int I andBool J <Int size(C)
     andBool size(C) ==Int size(A)
     andBool I +Int J ==Int size(A) -Int 1
     andBool isMirror(C, A, 0, I)
     andBool isMirror(C, A, J +Int 1, size(A))
     andBool seg(C, I, J +Int 1) ==K seg(A, I, J +Int 1)
     andBool bag(C) ==K bag(A)
    ensures  size(?D) ==Int size(A)
     andBool isMirror(?D, A, 0, size(A))               // (H-CLEAN)
     andBool bag(?D) ==K bag(A)                         // (H-PERM)   [ESCALATION BOUNDARY]
    [all-path]

  // ===========================================================================
  //  (REV) -- the function contract.
  //  reverse(A) returns OUT with: same length, out[i] = A[n-1-i] for all i
  //  (the index relation), and OUT a permutation of A.
  //  Composition: `def` files reverse -> `call` binds a = A in a fresh scope ->
  //  `i = 0`, `j = len(a) - 1` -> apply (LOOP) at entry {C := A, I := 0, J := n-1}.
  //  The (LOOP) precondition holds at entry:
  //    - I+J = 0 + (n-1) = n-1  (centre reflection, base case),
  //    - isMirror(A, A, 0, 0) and isMirror(A, A, n, n) are vacuous (empty bands),
  //    - seg(A,0,n) ==K seg(A,0,n) trivially (whole middle untouched),
  //    - bag(A) ==K bag(A) trivially.
  //  Then `return a` delivers the mirrored list. NO numeric precondition is needed
  //  -- empty/singleton are handled (the guard `0 < n-1` is false), the analogue of
  //  insertion-sort's "any <=1-element prefix is sorted for free". NO total-order
  //  precondition either: reverse compares nothing (FINDINGS.md #1).
  // ===========================================================================
  // SPEC-PROVENANCE:
  // - claim: (REV) function contract for in-place reversed value plus permutation boundary.
  // - from_prompt: P1 in PROMPTS.md: "Write `reverse(a)` that reverses the list **in place** (two pointers, index swaps) and returns it. Self-contained — no slicing/`.insert`/`list()`." => `reverse(a)` should mutate the list in place so returned positions mirror the original positions, preserving the same elements.
  // - from_code: The code swaps `a[i]` and `a[j]` while moving two pointers inward, then returns `a`.
  // - conflicts/findings: FVK records mutation as a behavioral contract point and notes that no total-order precondition is needed; permutation preservation is escalation-bounded.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k>
      def reverse ( a ) : INDENT
        i = 0
        j = len(a) - 1
        while i < j : INDENT
          tmp = a[i]
          a[i] = a[j]
          a[j] = tmp
          i = i + 1
          j = j - 1
        DEDENT
        return a
      DEDENT
      out = reverse ( A:List )
    => .K ... </k>
    <funcs> .Map => ?_:Map </funcs>
    <store> out |-> (_:KResult => ?R:List) </store>
    <stack> .List </stack>
    ensures  size(?R) ==Int size(A)
     andBool isMirror(?R, A, 0, size(A))               // (H-CLEAN): out[i] = A[n-1-i]
     andBool bag(?R) ==K bag(A)                         // (H-PERM)   [ESCALATION BOUNDARY]
    [all-path]
endmodule
