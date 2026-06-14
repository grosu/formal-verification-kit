// =============================================================================
//  binary-search-spec.k  --  verification of binary_search(a, x) as K `claim`s.
//
//    kompile mini-python.k --backend haskell
//    kast    --backend haskell binary-search-spec.k    // confirm claims parse
//    kprove  binary-search-spec.k                       // GOAL: #Top  (see caveat)
//
//  TWO claims, nested like the algorithm:
//    (SEARCH) the function contract: binary_search(a, x) returns an index `i` with
//             a[i] == x if x occurs in the sorted list a, and -1 if it does not.
//             Reuses (LOOP) as a lemma.  PRECONDITION: isSorted(a).
//    (LOOP)   the narrowing-window circularity: the search window [lo, hi] shrinks
//             every iteration, and the membership invariant "if x is in a, then x
//             is in the window a[lo : hi+1]" is preserved.
//
//  HONESTY / SCOPE BANNER  (read before trusting this file):
//    Binary search splits cleanly into a CLEAN half and an ESCALATION half:
//
//      * FOUND half  (return mid  =>  a[mid] == x):  CLEAN.
//        When the function returns an index, the post `a[?i] == x` is an immediate
//        consequence of the rule that fired (`if a[mid]==x: return mid`). This is
//        discharged by the bundled tier (a single index read + an Int equality).
//
//      * NOT-PRESENT half  (return -1  =>  x is in NO position of a):  ESCALATION.
//        Concluding "-1 is correct" requires proving x occurs at NO index of the
//        whole sorted list -- a UNIVERSALLY QUANTIFIED / inductive membership
//        predicate over the list, combined with sortedness. The bundled
//        simplification tier (exact-halving + map-extensionality) does NOT discharge
//        a quantified array-membership VC. This is the kit's documented ESCALATION
//        case for "recursive data structures ... inductively defined predicates
//        (often mu)". See knowledge/sources.md: OOPSLA'20 (unified fixpoint
//        reasoning over inductive data structures) and LICS'19 (Matching mu-Logic).
//
//    Lemmas/obligations tagged  // [ESCALATION BOUNDARY]  are STATED (so the claims
//    are well-formed and the obligations are explicit) but are NOT derivable from
//    the bundled tier. Marking them [trusted] would be DISHONEST; they are left as
//    explicit open obligations, NOT admitted. This file is "constructed, not
//    machine-checked" -- the strongest honest label.
// =============================================================================

requires "mini-python.k"

module MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON-SYNTAX
  // Program variables (a, x, lo, hi, mid, i) are lowercase => lex as Id, never
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

  // ---- sortedness: a clean inductive Bool function (fully definable). This is
  //  the PRECONDITION of (SEARCH): binary search is only correct on a sorted list.
  syntax Bool ::= isSorted(List) [function, total]
  rule isSorted(.List)                          => true
  rule isSorted(ListItem(_))                    => true
  rule isSorted(ListItem(X:Int) ListItem(Y:Int) L)
       => X <=Int Y andBool isSorted(ListItem(Y) L)

  // ---- membership over a CONTIGUOUS WINDOW [lo, hi] of the list --------------
  //  inWindow(L, lo, hi, x)  ==  "x occurs at some position p with lo <= p <= hi".
  //  Defined inductively by scanning the window. This is the predicate the loop
  //  invariant narrows; the FOUND case reads off a single index from it, the
  //  NOT-PRESENT case must reason about it being FALSE over the whole list.
  syntax Bool ::= inWindow(List, Int, Int, Int) [function, total]
  rule inWindow(_:List, LO:Int, HI:Int, _:Int) => false
    requires LO >Int HI                                   // empty window
  rule inWindow(L:List, LO:Int, HI:Int, X:Int)
       => ((L [ LO ]):>Int ==Int X) orBool inWindow(L, LO +Int 1, HI, X)
    requires LO <=Int HI andBool 0 <=Int LO andBool HI <Int size(L)

  // ---- whole-list membership is the window over [0, size-1] -----------------
  //  inList(L, x)  ==  "x occurs at some index of L"  ==  inWindow(L, 0, size-1, x).
  syntax Bool ::= inList(List, Int) [function, total]
  rule inList(L:List, X:Int) => inWindow(L, 0, size(L) -Int 1, X)

  // ===========================================================================
  //  BUNDLED-TIER SIMPLIFICATION (same shape as examples/sum-up) ---------------
  // ===========================================================================
  // Map extensionality, to reduce a post-store cell #Equals to a scalar/value one
  // (closes the post-store cell equality for the `result`/`out` binding).
  rule { M:Map [ K <- V ] #Equals M:Map [ K <- V' ] } => { V #Equals V' }
    [simplification]

  // ===========================================================================
  //  [ESCALATION BOUNDARY] obligations -- STATED, not bundled-derivable.
  //  These are the membership / sortedness facts the NOT-PRESENT half needs. They
  //  require an inductive list theory with a quantified membership predicate;
  //  /verify routes them to OOPSLA'20 / LICS'19 (see knowledge/sources.md).
  //  Marking them [simplification]/[trusted] would manufacture confidence the kit
  //  does not have, so they are left as explicit obligations, NOT admitted.
  // ===========================================================================
  // (M1) WINDOW-NARROWING (the loop step, found-direction pruning):
  //        for SORTED L, if a[mid] < x then x cannot occur in a[lo : mid],
  //        so inWindow(L, lo, hi, x) == inWindow(L, mid+1, hi, x);
  //        symmetrically a[mid] > x prunes the upper half:
  //        inWindow(L, lo, hi, x) == inWindow(L, lo, mid-1, x).
  //      -- this is the crux that preserves "if x in L then x in window". It needs
  //      sortedness + a quantified-membership cut on the discarded sub-window.
  //      Provable only with an inductive isSorted/inWindow theory. [ESCALATION BOUNDARY]
  //
  // (M2) EMPTY-WINDOW => NOT PRESENT (the exit / -1 direction):
  //        when the loop exits with lo > hi, the invariant gives
  //        inList(L, x) == inWindow(L, lo, hi, x), and an empty window
  //        (lo > hi) means inWindow == false, hence inList(L, x) == false:
  //        x occurs at NO index of L. This UNIVERSALLY-QUANTIFIED "x is absent"
  //        conclusion is exactly what the bundled tier cannot discharge.
  //      [ESCALATION BOUNDARY]
  //
  // (Intentionally NOT written as `rule ... [simplification]` and NOT tagged
  //  [trusted]: the honest deliverable names them as open obligations. See
  //  FINDINGS.md #6 and PROOF.md §4 VC-M1/VC-M2.)
endmodule

module MINI-PYTHON-SPEC
  imports VERIFICATION

  // ===========================================================================
  //  (LOOP) -- the narrowing-window circularity.
  //  At the head of `while lo <= hi`, list A (constant -- never written), counter
  //  pair (LO, HI), target X. The loop either RETURNS an index it found, or
  //  shrinks the window and recurses. The invariant carried in `requires`:
  //      0 <= LO  and  HI < size(A)        -- window indices in range
  //      isSorted(A)                       -- the precondition, still true
  //      (inList(A, X) -> inWindow(A, LO, HI, X))   -- NARROWING-WINDOW invariant:
  //                  if X is in A at all, it is in the current window [LO, HI].
  //  The loop ends in one of two post-states:
  //      * FOUND:    ?r = some index ?i with A[?i] == X        (CLEAN)
  //      * NOTFOUND: ?r = -1 and X is in no position of A       (ESCALATION: M2)
  //  Each iteration computes MID = (LO+HI)//2 and case-splits on A[MID] vs X:
  //      A[MID]==X  -> return MID            (FOUND, clean: A[MID]==X by the read)
  //      A[MID]< X  -> LO := MID+1           (prune lower half; needs M1)
  //      A[MID]> X  -> HI := MID-1           (prune upper half; needs M1)
  //  Window strictly shrinks each step because LO <= MID <= HI (so MID+1 > LO and
  //  MID-1 < HI): this is the TERMINATION measure HI-LO+1 (partial correctness here;
  //  see FINDINGS "Note"). The shrink keeps the indices in range -> no IndexError.
  // ===========================================================================
  // SPEC-PROVENANCE:
  // - claim: (LOOP) narrowing-window loop circularity for binary search.
  // - from_prompt: P1 in PROMPTS.md: "Write `binary_search(a, x)` returning the index of `x` in a sorted list, or `-1` if absent. Iterative. Self-contained." => `binary_search(a,x)` should return some index whose value is `x` when present in a sorted, totally ordered list, and `-1` when absent.
  // - from_code: The code narrows `[lo, hi]` around `mid = (lo + hi) // 2`, returning on equality and moving either boundary otherwise.
  // - conflicts/findings: Sortedness and total order are real preconditions; duplicate winner semantics are underspecified, and the not-present proof half is escalation-bounded.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k>
      while lo <= hi : INDENT
        mid = ( lo + hi ) // 2
        if a [ mid ] == x : INDENT
          return mid
        DEDENT else : INDENT
          if a [ mid ] < x : INDENT
            lo = mid + 1
          DEDENT else : INDENT
            hi = mid - 1
          DEDENT
        DEDENT
      DEDENT
      return -1
    => ?r:Int ... </k>
    <store>
      a   |-> A:List
      x   |-> X:Int
      lo  |-> (LO:Int  => ?_:Int)
      hi  |-> (HI:Int  => ?_:Int)
      mid |-> (_:Int   => ?_:Int)
    </store>
    requires 0 <=Int LO andBool HI <Int size(A)
     andBool isSorted(A)
     andBool (inList(A, X) impliesBool inWindow(A, LO, HI, X))
    ensures  (?r ==Int -1 andBool notBool inList(A, X))           // NOTFOUND: [ESC M2]
     orBool  (0 <=Int ?r andBool ?r <Int size(A)
              andBool (A [ ?r ]):>Int ==Int X)                    // FOUND: clean
    [all-path]

  // ===========================================================================
  //  (SEARCH) -- the function contract.
  //  binary_search(A, X) returns -1 if X is absent from the sorted list A, else an
  //  index ?i with A[?i] == X. Reuses (LOOP) at entry {LO := 0, HI := size(A)-1};
  //  its precondition holds because at entry the window is the WHOLE list, so the
  //  membership invariant `inList(A,X) -> inWindow(A,0,size-1,X)` is `inList ->
  //  inList`, trivially true (the analogue of the sum example's "1 <= N+1 from
  //  N>=0"). PRECONDITION: isSorted(A) -- the unstated sortedness requirement the
  //  source silently assumes (FINDINGS.md #3). NOTE the empty-list case `A = .List`
  //  has size 0, so HI = -1, lo <= hi is 0 <= -1 = false, loop never runs, return
  //  -1, and inList(.List, X) = inWindow(.List,0,-1,X) = false -- correct by the
  //  empty-window base rule (no escalation needed for the empty list itself).
  // ===========================================================================
  // SPEC-PROVENANCE:
  // - claim: (SEARCH) function contract for found/absent behavior under sortedness.
  // - from_prompt: P1 in PROMPTS.md: "Write `binary_search(a, x)` returning the index of `x` in a sorted list, or `-1` if absent. Iterative. Self-contained." => `binary_search(a,x)` should return some index whose value is `x` when present in a sorted, totally ordered list, and `-1` when absent.
  // - from_code: The code narrows `[lo, hi]` around `mid = (lo + hi) // 2`, returning on equality and moving either boundary otherwise.
  // - conflicts/findings: Sortedness and total order are real preconditions; duplicate winner semantics are underspecified, and the not-present proof half is escalation-bounded.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k>
      def binary_search ( a , x ) : INDENT
        lo , hi = 0 , len ( a ) - 1
        while lo <= hi : INDENT
          mid = ( lo + hi ) // 2
          if a [ mid ] == x : INDENT
            return mid
          DEDENT else : INDENT
            if a [ mid ] < x : INDENT
              lo = mid + 1
            DEDENT else : INDENT
              hi = mid - 1
            DEDENT
          DEDENT
        DEDENT
        return -1
      DEDENT
      out = binary_search ( A:List , X:Int )
    => .K ... </k>
    <funcs> .Map => ?_:Map </funcs>
    <store> out |-> (_:KResult => ?r:Int) </store>
    <stack> .List </stack>
    requires isSorted(A)
    ensures  (?r ==Int -1 andBool notBool inList(A, X))           // NOTFOUND: [ESC M2]
     orBool  (0 <=Int ?r andBool ?r <Int size(A)
              andBool (A [ ?r ]):>Int ==Int X)                    // FOUND: clean
    [all-path]
endmodule
