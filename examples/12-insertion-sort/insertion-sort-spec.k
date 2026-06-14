// =============================================================================
//  insertion-sort-spec.k  --  verification of in-place insertion_sort(a) as K `claim`s.
//
//    kompile mini-python.k --backend haskell
//    kast    --backend haskell insertion-sort-spec.k    // confirm claims parse
//    kprove  insertion-sort-spec.k                       // GOAL: #Top  (see caveat)
//
//  THREE claims, nested exactly like the algorithm:
//    (SORT)  the function contract:  insertion_sort(A) sorts its list IN PLACE and
//            returns it -- the returned/mutated list is a SORTED PERMUTATION of A
//            (same length).  Reuses (OUTER) as a lemma.
//    (OUTER) the outer-loop circularity: invariant = "prefix [0,i) is sorted and
//            the whole array is a permutation of the input".  Reuses (INNER).
//    (INNER) the inner-loop circularity: the "insert key into a hole" invariant.
//
//  IN-PLACE NOTE (from PROMPTS.md P1): the program variable is `a` (the parameter
//  itself), NOT a `result` copy. There is no `list()` step. (OUTER)/(INNER) mutate
//  `a`; (SORT) returns the mutated `a`. The value-level contract is sorted
//  permutation; the behavioral side effect (input MUTATED) is FINDINGS.md #4.
//
//  HONESTY / SCOPE BANNER  (read before trusting this file):
//    Sorting's postcondition is NOT a polynomial closed form (the kit's arithmetic
//    fast path, as in examples/sum-up). It is two NON-arithmetic predicates:
//      * SORTEDNESS  -- an inductively-defined / universally-quantified predicate;
//      * PERMUTATION -- MULTISET equality of input and output.
//    The kit's bundled simplification tier (exact-halving + map-extensionality)
//    does NOT discharge multiset-preservation or sorted-prefix-composition VCs.
//    Those need an inductive list/multiset theory -- the kit's documented
//    ESCALATION case for "recursive data structures ... inductively defined
//    predicates (often mu)". See knowledge/sources.md: OOPSLA'20 (unified fixpoint
//    reasoning over inductive data structures) and LICS'19 (Matching mu-Logic).
//    Lemmas below tagged  // [ESCALATION BOUNDARY]  are STATED (so the claims are
//    well-formed and the proof obligations are explicit) but are NOT derivable
//    from the bundled tier; they are exactly what /verify will route upstream.
//    This file is "constructed, not machine-checked" -- the strongest honest label.
// =============================================================================

requires "mini-python.k"

module MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON-SYNTAX
  // Program variables (a, out, i, j, key) are lowercase => lex as Id, never
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

  // ---- sortedness: a clean inductive Bool function (fully definable) ---------
  syntax Bool ::= isSorted(List) [function, total]
  rule isSorted(.List)                          => true
  rule isSorted(ListItem(_))                    => true
  rule isSorted(ListItem(X:Int) ListItem(Y:Int) L)
       => X <=Int Y andBool isSorted(ListItem(Y) L)

  // ---- "every element > K" (the shifted region in the inner loop) -----------
  syntax Bool ::= allGt(List, Int) [function, total]
  rule allGt(.List, _)                => true
  rule allGt(ListItem(X:Int) L, K:Int) => X >Int K andBool allGt(L, K)

  // ---- contiguous segments via K's range(L, dropFront, dropBack) -------------
  //   take(L,N) = first N ;  seg(L,A,B) = positions [A, B).
  syntax List ::= take(List, Int)        [function]
                | seg(List, Int, Int)    [function]
  rule take(L:List, N:Int)        => range(L, 0, size(L) -Int N)
  rule seg(L:List, A:Int, B:Int)  => range(L, A, size(L) -Int B)

  // ---- multiset abstraction: value |-> multiplicity (a count Map) -----------
  //   bag(X) ==K bag(Y)  <=>  X is a permutation of Y.
  syntax Map ::= bag(List)        [function, total]
               | incr(Map, Int)   [function, total]
  rule bag(.List)                 => .Map
  rule bag(ListItem(X:Int) L)     => incr(bag(L), X)
  rule incr(M:Map, X:Int) => M [ X <- (({M[X]}:>Int) +Int 1) ] requires X in_keys(M)
  rule incr(M:Map, X:Int) => M [ X <- 1 ]                      requires notBool X in_keys(M)

  // ===========================================================================
  //  BUNDLED-TIER SIMPLIFICATION (same shape as examples/sum-up) ---------------
  // ===========================================================================
  // Map extensionality, to reduce a post-store cell #Equals to a scalar/value one.
  rule { M:Map [ K <- V ] #Equals M:Map [ K <- V' ] } => { V #Equals V' }
    [simplification]

  // ===========================================================================
  //  [ESCALATION BOUNDARY] lemmas -- STATED, not bundled-derivable.
  //  These are the multiset / sortedness facts the inner+outer steps need. They
  //  require an inductive list theory; /verify routes them to OOPSLA'20 / LICS'19
  //  (see knowledge/sources.md). Marked [trusted] would be DISHONEST here, so they
  //  are left as explicit obligations, NOT admitted.
  // ===========================================================================
  // (L1) one index-update changes the multiset by swapping one element out/in:
  //        bag(L[P <- V]) = incr( bag(L) "minus" L[P], V )
  //      -- the crux of permutation-preservation across a shift. NEEDS a Bag
  //      theory with element delete; not expressible cleanly in the count-Map
  //      above without a decr partial inverse. [ESCALATION BOUNDARY]
  //
  // (L2) a contiguous shift of a sorted block stays sorted, and
  //        isSorted(prefix ++ ListItem(KEY) ++ block)  when prefix all <= KEY < block.
  //      -- sorted-prefix composition for the outer step. [ESCALATION BOUNDARY]
  //
  // (Intentionally not written as `rule ... [simplification]`: doing so and
  //  tagging [trusted] would manufacture confidence the kit does not have. The
  //  honest deliverable names them as open obligations. See FINDINGS.md #6.)
endmodule

module MINI-PYTHON-SPEC
  imports VERIFICATION

  // ===========================================================================
  //  (INNER) -- inner-loop circularity: "insert KEY into a hole".
  //  At the head of `while j >= 0 and a[j] > key`, with current array C, counter
  //  J, the value KEY being inserted, outer index I (constant here), and MS the
  //  multiset to be preserved (= the entry array's multiset):
  //    PRE invariant:
  //      -1 <= J < I < size(C)
  //      isSorted(take(C, J+1))                 -- positions [0,J+1) untouched, sorted
  //      allGt(seg(C, J+2, I+1), KEY)           -- positions [J+2, I] shifted, all > KEY
  //      bag(C[J+1 <- KEY]) ==K MS              -- filling the hole at J+1 recovers MS
  //  The loop ends at ?J2 with the guard false: ?J2 = -1 OR ?D[?J2] <= KEY, the
  //  shifted region grown to [?J2+2, I], the hole still at ?J2+1, MS preserved.
  //  The discharge of the bag/sorted parts is the [ESCALATION BOUNDARY] (L1,L2).
  //
  //  In-place note: the mutated list IS `a` here (no `result` copy).
  // ===========================================================================
  // SPEC-PROVENANCE:
  // - claim: (INNER) inner shift-loop circularity.
  // - from_prompt: P1 in PROMPTS.md: "Write `insertion_sort(a)` that sorts the list **in place** (nested while loops, index assignment) and returns it. Self-contained — no `list()`/slic..." => `insertion_sort(a)` should sort the same list in place, returning the mutated list as a sorted permutation of the input.
  // - from_code: The code uses an outer index `i`, saves `key = a[i]`, shifts larger elements right in an inner loop, writes `key`, and returns `a`.
  // - conflicts/findings: A total-order precondition is required (NaN/mixed types break it); strict `>` makes stability intent-relevant; mutation is a visible behavioral contract.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k>
      while j >= 0 and a[j] > key : INDENT
        a[j + 1] = a[j]
        j = j - 1
      DEDENT => .K ...
    </k>
    <store>
      a   |-> (C:List => ?D:List)
      j   |-> (J:Int  => ?J2:Int)
      key |-> KEY:Int
      i   |-> I:Int
    </store>
    requires -1 <=Int J andBool J <Int I andBool I <Int size(C)
     andBool isSorted(take(C, J +Int 1))
     andBool allGt(seg(C, J +Int 2, I +Int 1), KEY)
    ensures  -1 <=Int ?J2 andBool ?J2 <Int I
     andBool size(?D) ==Int size(C)
     andBool allGt(seg(?D, ?J2 +Int 2, I +Int 1), KEY)
     andBool (?J2 ==Int -1 orBool (?D [ ?J2 ]):>Int <=Int KEY)
     andBool isSorted(take(?D, ?J2 +Int 1))
     // multiset link: bag(C[J+1<-KEY]) ==K bag(?D[?J2+1<-KEY])   [ESCALATION BOUNDARY]
    [all-path]

  // ===========================================================================
  //  (OUTER) -- outer-loop circularity: "sorted prefix grows by one".
  //  Invariant at head of `while i < len(a)`, array B, counter I:
  //      1 <= I <= size(B)
  //      isSorted(take(B, I))                   -- prefix [0,I) sorted
  //  One iteration inserts B[I] into the sorted prefix (via (INNER) + the hole
  //  fill `a[j+1] = key`), giving isSorted(take(_, I+1)) and a preserved multiset;
  //  then re-invokes (OUTER) at I+1. Exit (I = size(B)) => whole array sorted.
  //  Permutation across the whole loop is bag-preservation. [ESC: L1,L2]
  //
  //  In-place note: the loop mutates `a` directly (no `result` copy).
  // ===========================================================================
  // SPEC-PROVENANCE:
  // - claim: (OUTER) outer sorted-prefix circularity.
  // - from_prompt: P1 in PROMPTS.md: "Write `insertion_sort(a)` that sorts the list **in place** (nested while loops, index assignment) and returns it. Self-contained — no `list()`/slic..." => `insertion_sort(a)` should sort the same list in place, returning the mutated list as a sorted permutation of the input.
  // - from_code: The code uses an outer index `i`, saves `key = a[i]`, shifts larger elements right in an inner loop, writes `key`, and returns `a`.
  // - conflicts/findings: A total-order precondition is required (NaN/mixed types break it); strict `>` makes stability intent-relevant; mutation is a visible behavioral contract.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k>
      while i < len(a) : INDENT
        key = a[i]
        j = i - 1
        while j >= 0 and a[j] > key : INDENT
          a[j + 1] = a[j]
          j = j - 1
        DEDENT
        a[j + 1] = key
        i = i + 1
      DEDENT => .K ...
    </k>
    <store>
      a   |-> (B:List => ?R:List)
      i   |-> (I:Int  => size(B))
      key |-> (_:Int  => ?_:Int)
      j   |-> (_:Int  => ?_:Int)
    </store>
    requires 1 <=Int I andBool I <=Int size(B)
     andBool isSorted(take(B, I))
    ensures  size(?R) ==Int size(B)
     andBool isSorted(?R)
     andBool bag(?R) ==K bag(B)
    [all-path]

  // ===========================================================================
  //  (SORT) -- the function contract.
  //  insertion_sort(A) sorts A IN PLACE and returns it: the returned value ?R is a
  //  sorted permutation of A of equal length. Reuses (OUTER) at entry {B := A,
  //  I := 1}, whose precondition isSorted(take(A,1)) holds because any 1-element
  //  (or empty) prefix is sorted -- the analogue of the sum example's
  //  "1 <= N+1 follows from N >= 0". NO numeric precondition is needed: on the Int
  //  model the order is total. (The total-order precondition for the GENERIC
  //  function is FINDINGS.md #1.)
  //
  //  IN-PLACE: note there is NO `result = list(array)` line -- the body binds `a`
  //  to the argument and mutates it directly, then `return a`. The aliasing fact
  //  `insertion_sort(x) is x` (Python returns the SAME object) is a reference-level
  //  property the value-sort model does not express -- FINDINGS.md #4; the VALUE
  //  contract below (sorted permutation, equal length) IS faithful.
  // ===========================================================================
  // SPEC-PROVENANCE:
  // - claim: (SORT) function contract for in-place sorted permutation.
  // - from_prompt: P1 in PROMPTS.md: "Write `insertion_sort(a)` that sorts the list **in place** (nested while loops, index assignment) and returns it. Self-contained — no `list()`/slic..." => `insertion_sort(a)` should sort the same list in place, returning the mutated list as a sorted permutation of the input.
  // - from_code: The code uses an outer index `i`, saves `key = a[i]`, shifts larger elements right in an inner loop, writes `key`, and returns `a`.
  // - conflicts/findings: A total-order precondition is required (NaN/mixed types break it); strict `>` makes stability intent-relevant; mutation is a visible behavioral contract.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k>
      def insertion_sort ( a ) : INDENT
        i = 1
        while i < len(a) : INDENT
          key = a[i]
          j = i - 1
          while j >= 0 and a[j] > key : INDENT
            a[j + 1] = a[j]
            j = j - 1
          DEDENT
          a[j + 1] = key
          i = i + 1
        DEDENT
        return a
      DEDENT
      out = insertion_sort ( A:List )
    => .K ... </k>
    <funcs> .Map => ?_:Map </funcs>
    <store> out |-> (_:KResult => ?R:List) </store>
    <stack> .List </stack>
    ensures  size(?R) ==Int size(A)
     andBool isSorted(?R)
     andBool bag(?R) ==K bag(A)
    [all-path]
endmodule
