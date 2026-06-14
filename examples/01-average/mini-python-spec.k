// =============================================================================
//  mini-python-spec.k  --  verification of average(nums) as K `claim`s checkable
//  by kprove.
//
//    kompile mini-python.k --backend haskell
//    kast    --backend haskell mini-python-spec.k    // confirm claims parse
//    kprove  mini-python-spec.k                       // GOAL: #Top  (see caveat)
//
//  TWO claims (average now sums with an EXPLICIT `while` loop, so -- unlike the
//  old builtin-`sum()` version -- there IS a loop circularity):
//
//    (LOOP) the loop-invariant claim = the circularity. K's reachability prover
//           uses every claim in the module as a coinduction hypothesis, so (LOOP)
//           discharges ITS OWN loop. Invariant: total = listsum(nums[0:i)). The
//           step VC  total_new = total + nums[i]  is DEFINITIONAL/CLEAN -- it is
//           exactly the unfold equation of the spec fold `listsum`. This is the
//           crucial difference from the builtin-`sum()` version, whose single VC
//           was a TRUNCATING-FOLD divisibility fact (an [ESCALATION BOUNDARY]).
//           Here the loop is ESCALATION-FREE.
//    (AVG)  the function contract. Reuses (LOOP) as a lemma at {T:=0, I:=0}, then
//           divides by the length.
//
//  HONESTY / SCOPE BANNER (read before trusting this file):
//    * PRECONDITION  size(NUMS) >= 1  is LOAD-BEARING. Drop it and average([])
//      divides by zero (n = len([]) = 0) -- the headline bug, FINDINGS.md #1. It is
//      the missing precondition the code never states.
//    * `listsum(L, lo, hi)` is a SPEC-ONLY abstraction (a clean inductive range
//      fold), NOT a language construct. It is the list-sum analogue of the sum-up
//      example's closed form, and of isSorted/bag in examples/insertion-sort: spec
//      vocabulary, declared [function], used only in `requires`/`ensures`. We give
//      it a complete set of defining equations below; its loop-step unfold equation
//      is what makes (LOOP)'s step VC clean.
//    * The ONLY residual obligation is the [function, total] TOTALITY of `listsum`
//      (that the recursion is well-founded / defined on every (L,lo,hi) -- a
//      structural induction on hi-lo). Everything ELSE -- the loop step, the loop
//      exit, the call layer, the division side condition -- is discharged by the
//      bundled tier (Z3 + the spec fold's own rewrite equations + map
//      extensionality). That single totality obligation is the lone
//      [ESCALATION BOUNDARY]; it is STATED, NOT admitted [trusted]. See PROOF.md §4
//      and FINDINGS.md #5. Contrast: the builtin-`sum()` version's boundary was a
//      DIVISIBILITY fact entangled with truncating /Int -- strictly harder.
//    * This file is "constructed, not machine-checked" -- the strongest honest
//      label (the MVP does not run the toolchain).
// =============================================================================

requires "mini-python.k"

module MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON-SYNTAX
  // Program variables (nums, total, i, n, result) are lowercase => lex as Id,
  // never clashing with K's uppercase/?-prefixed logical variables. No [token]s.
endmodule

module VERIFICATION
  imports MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON
  imports MAP-SYMBOLIC
  imports K-EQUAL

  // ===========================================================================
  //  SPEC-ONLY ABSTRACTION (used only inside the claims; not part of the language)
  // ===========================================================================
  // listsum(L, lo, hi) = sum of the elements L[lo], L[lo+1], ..., L[hi-1]
  //   (the half-open range L[lo:hi)). A clean inductive range fold over Int. The
  //   loop invariant is total = listsum(nums, 0, i); the whole-list sum is
  //   listsum(nums, 0, size(nums)).
  //
  //   Defining equations (a "fold from the high end", so the unfold matches the
  //   loop, which appends nums[i] at the high end each step):
  //     - empty / inverted range  (hi <= lo):                listsum = 0
  //     - non-empty range, peel the LAST element  (lo < hi): listsum(L,lo,hi)
  //                                = listsum(L, lo, hi-1) +Int L[hi-1]
  //   The second equation, read right-to-left at hi := i+1, is EXACTLY the loop
  //   step  total + nums[i] = listsum(nums, 0, i+1)  -- the clean step VC. The
  //   first equation, at lo = hi = i = 0, gives the loop's entry value 0.
  syntax Int ::= listsum(List, Int, Int) [function, total]

  rule listsum(_:List, LO:Int, HI:Int) => 0
    requires HI <=Int LO                                            // empty range
  rule listsum(L:List, LO:Int, HI:Int)
         => listsum(L, LO, HI -Int 1) +Int L [ HI -Int 1 ]
    requires LO <Int HI                                             // peel the last
    [simplification]

  // ===========================================================================
  //  BUNDLED-TIER SIMPLIFICATION (same shape as examples/sum-up) ---------------
  // ===========================================================================
  // Map extensionality, to reduce the post-store cell #Equals to a scalar one (the
  // result/total bindings are produced as STORE[x <- V]). (Cf. Lesson 1.22.)
  rule { M:Map [ K <- V ] #Equals M:Map [ K <- V' ] } => { V #Equals V' }
    [simplification]

  // Loop-step unfold of the fold, oriented for the prover (right-to-left of the
  // peel-the-last equation): appending nums[I] to total = listsum(nums,0,I) yields
  // total for listsum(nums,0,I+1). This is the CLEAN, DEFINITIONAL step VC -- pure
  // fold unfolding, NO division, NO truncation, NO nonlinearity. It is the heart of
  // why the loop here is escalation-FREE (unlike the builtin-`sum()` version).
  rule listsum(L:List, LO:Int, I:Int) +Int L [ I:Int ] => listsum(L, LO, I +Int 1)
    requires LO <=Int I andBool 0 <=Int I andBool I <Int size(L)
    [simplification]
endmodule

module MINI-PYTHON-SPEC
  imports VERIFICATION

  // ===========================================================================
  //  (LOOP) -- the loop invariant = the circularity.  ESCALATION-FREE.
  //  From any state with total = T, i = I, n = N (= size(nums)), nums = NUMS, and
  //  0 <= I <= N, running the loop adds  listsum(NUMS, I, N) = sum of nums[I:N)  to
  //  total and leaves i = N. Generalized over the accumulator T and counter I (not
  //  pinned to entry values 0, 0). Side condition  0 <= I <= N  is the load-bearing
  //  bound (cf. sum-up's I <= N+1): outside it the body never runs yet the fold is
  //  non-zero, so the invariant would be false.
  //
  //  Crucially the step VC  total + nums[i] = listsum(nums, 0, i+1)  is DEFINITIONAL
  //  (the fold's own unfold equation in VERIFICATION), NOT a truncating-division
  //  fact -- so this circularity discharges with the bundled tier alone.
  // ===========================================================================
  // SPEC-PROVENANCE:
  // - claim: (LOOP) running-sum loop circularity over `total`, `i`, and `nums`.
  // - from_prompt: P1 in PROMPTS.md: "Write `average(nums)` returning the arithmetic mean of a non-empty list of numbers. Self-contained: sum with your own `while` loop and divide by `l..." => `average(nums)` should compute the arithmetic mean on the intended non-empty numeric-list domain; the loop should sum all elements and divide by the length.
  // - from_code: The code initializes `total = 0`, iterates `while i < len(nums)`, accumulates `total += nums[i]`, and returns `total / len(nums)`.
  // - conflicts/findings: `average([])` raises `ZeroDivisionError`; the K model uses `/Int` while Python `/` is true division, so the float/int gap is reported rather than hidden.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k>
      while i < n : INDENT
        total = total + nums [ i ]
        i = i + 1
      DEDENT => .K ...
    </k>
    <store>
      total |-> (T:Int => T +Int listsum(NUMS, I, N))
      i     |-> (I:Int => N)
      n     |-> N:Int
      nums  |-> NUMS:List
    </store>
    requires 0 <=Int I andBool I <=Int N andBool N ==Int size(NUMS)
    [all-path]

  // ===========================================================================
  //  (AVG) -- the function contract.
  //  Defining average and calling it on a NON-EMPTY Int list NUMS terminates with
  //  result = listsum(NUMS, 0, size(NUMS)) /Int size(NUMS), i.e. the integer mean.
  //  The precondition  size(NUMS) >= 1  is the missing precondition that averts
  //  division by zero (FINDINGS.md #1) and discharges the division side condition.
  //
  //  The result is stated CONSTRUCTIVELY (the exact quotient) rather than as the
  //  relational  R * len = sum : because the loop now establishes total = the FULL
  //  fold listsum(NUMS,0,size) EXACTLY (clean, escalation-free), the only remaining
  //  arithmetic is the single /Int, whose value we name directly. (On the integer-
  //  mean domain -- size divides sum -- this equals the relational form
  //  R * size = sum; the int-vs-float gap is FINDINGS.md #3.)
  // ===========================================================================
  // SPEC-PROVENANCE:
  // - claim: (AVG) function contract: sum all elements and divide by `len(nums)` on `len(nums) >= 1`.
  // - from_prompt: P1 in PROMPTS.md: "Write `average(nums)` returning the arithmetic mean of a non-empty list of numbers. Self-contained: sum with your own `while` loop and divide by `l..." => `average(nums)` should compute the arithmetic mean on the intended non-empty numeric-list domain; the loop should sum all elements and divide by the length.
  // - from_code: The code initializes `total = 0`, iterates `while i < len(nums)`, accumulates `total += nums[i]`, and returns `total / len(nums)`.
  // - conflicts/findings: `average([])` raises `ZeroDivisionError`; the K model uses `/Int` while Python `/` is true division, so the float/int gap is reported rather than hidden.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k>
      def average ( nums ) : INDENT
        total = 0
        i = 0
        n = len ( nums )
        while i < n : INDENT
          total = total + nums [ i ]
          i = i + 1
        DEDENT
        return total / n
      DEDENT
      result = average ( NUMS:List )
    => .K ... </k>
    <funcs> .Map => ?_:Map </funcs>
    <store> result |-> (_:KResult => listsum(NUMS, 0, size(NUMS)) /Int size(NUMS)) </store>
    <stack> .List </stack>
    requires size(NUMS) >=Int 1
    [all-path]
endmodule
