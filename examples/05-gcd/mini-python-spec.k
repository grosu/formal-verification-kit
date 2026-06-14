// =============================================================================
//  mini-python-spec.k  -- verification of gcd(a, b) as K `claim`s for kprove.
//
//    kompile mini-python.k --backend haskell
//    kast    --backend haskell mini-python-spec.k    // confirm claims parse (1 AST)
//    kprove  mini-python-spec.k                       // see PROOF.md for expected
//
//  THE SHAPE IS DIFFERENT FROM sum-up. The sum loop carried an *accumulator* and a
//  polynomial closed form. The gcd loop carries NO accumulator: the postcondition
//  is a PRESERVED RELATION, not a value built up. The relation is the number-
//  theoretic identity
//
//        gcd(a, b)  is invariant across one loop iteration, because
//        gcd(a, b)  =  gcd(b, a mod b)              (the Euclid identity)
//
//  so the loop reaches a state where b = 0, at which point gcd(a, 0) = a, the
//  returned value. We introduce a SPEC-ONLY symbol `gcd` to STATE this contract
//  (result = gcd(A, B)); it is verification vocabulary, NOT a language construct.
//
//  HONEST SCOPE -- the Euclid identity gcd(a,b) = gcd(b, a mod b) is the crux of
//  preservation and is BEYOND the bundled simplification tier (it is an inductive
//  number-theoretic fact, not linear arithmetic / division-by-even). It is STATED
//  as an explicit [ESCALATION BOUNDARY] obligation below and routed to the sources;
//  it is NOT faked as [trusted]. The CONTROL-FLOW parts (the loop terminating at
//  b = 0, the base value gcd(a,0) = a, termination via strictly-decreasing b) are
//  clean and inside the fragment. See PROOF.md for which VCs land where.
// =============================================================================

requires "mini-python.k"

module MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON-SYNTAX
  // Program variables (a, b, t, result) are lowercase, so they lex as Id and
  // never clash with K's (uppercase/?-prefixed) logical variables. No [token]
  // declarations are required.
endmodule

module VERIFICATION
  imports MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON
  imports MAP-SYMBOLIC
  imports K-EQUAL

  // ---------------------------------------------------------------------------
  //  SPEC-ONLY abstraction symbol -- the mathematical gcd. Used ONLY to STATE the
  //  contract (result = gcd(A, B)); it is NOT part of mini-Python's semantics and
  //  the program never mentions it. Declared total over nonnegative integers.
  // ---------------------------------------------------------------------------
  syntax Int ::= gcd(Int, Int) [function, total, smtlib(gcd)]

  // Map extensionality, to reduce a post-store cell #Equals to a scalar one
  // (closes the (GCD) post-store implication that pins `result`). (Cf. Lesson 1.22.)
  rule { M:Map [ K <- V ] #Equals M:Map [ K <- V' ] } => { V #Equals V' }
    [simplification]

  // ===========================================================================
  //  THE NUMBER-THEORETIC FACTS gcd needs.
  //
  //  (BASE) gcd(a, 0) = a            -- CLEAN. The loop-exit value. This is the
  //         definitional base case and is sound to supply (it is how the result
  //         is read off once b reaches 0). Bundled-dischargeable.
  rule gcd(A:Int, 0) => A  [simplification]

  //  (EUCLID) gcd(a, b) = gcd(b, a mod b)   for b =/= 0.
  //  ----------------------------------------------------------- [ESCALATION BOUNDARY]
  //  This is the crux of loop-PRESERVATION: it is what makes gcd(a,b) invariant
  //  across the swap `a, b = b, a % b`. It is an INDUCTIVE number-theoretic
  //  identity (proved from the divisibility lattice / Bezout), NOT a linear-
  //  arithmetic or division-by-even fact, so it is OUTSIDE the bundled tier.
  //
  //  It is STATED here as an open obligation so the (LOOP)/(GCD) claims are well
  //  formed and the structural proof composes -- but it is DELIBERATELY NOT given
  //  as a `[simplification]` rule and NOT marked `[trusted]`. Admitting it either
  //  way would manufacture confidence the kit does not have. /verify routes it to
  //  the sources (number-theory is not a matching-logic primitive; the inductive-
  //  reasoning machinery is the mu-logic line, LICS'19 / OOPSLA'20 in
  //  knowledge/sources.md). See PROOF.md (VC-EUCLID) and FINDINGS.md.
  //
  //      rule gcd(A:Int, B:Int) => gcd(B, A modInt B)
  //        requires B =/=Int 0
  //        [simplification]                       // <-- intentionally NOT enabled
  // ===========================================================================
endmodule

module MINI-PYTHON-SPEC
  imports VERIFICATION

  // ===========================================================================
  //  (LOOP) -- the loop circularity. NOT an accumulator invariant: the invariant
  //  is the PRESERVED RELATION  gcd(a, b).
  //
  //  From any state with a = A, b = B and B >= 0 (and A >= 0), running the loop
  //  reaches a = gcd(A, B), b = 0.  Generalized over BOTH a and b (not pinned to
  //  entry values); K's prover uses this claim as its own coinduction hypothesis,
  //  so it discharges ITS OWN loop -- replacing a hand-written invariant.
  //
  //  The post-value gcd(A,B) plays the role the classical invariant used to: each
  //  iteration rewrites (a,b) -> (b, a mod b), and gcd(b, a mod b) = gcd(a, b)
  //  [the (EUCLID) [ESCALATION BOUNDARY] fact], so gcd(a,b) is constant; the loop
  //  ends at b = 0 with a = gcd(A,B) [the (BASE) fact gcd(a,0) = a].
  // ===========================================================================
  // SPEC-PROVENANCE:
  // - claim: (LOOP) Euclidean preserved-relation loop circularity.
  // - from_prompt: P1 in PROMPTS.md: "Write `gcd(a, b)` returning the greatest common divisor of two non-negative integers via the Euclidean algorithm (`while b: a, b = b, a % b`). Self..." => `gcd(a,b)` should return the non-negative greatest common divisor of two non-negative integers.
  // - from_code: The code is Euclid's loop `while b: a, b = b, a % b` and then `return a`.
  // - conflicts/findings: The implementation accepts negative inputs; e.g. negative second arguments can produce a negative result, so FVK records the non-negativity precondition and...
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k>
      while b : INDENT a , b = b , a % b DEDENT => .K ...
    </k>
    <store>
      a |-> (A:Int => gcd(A, B))
      b |-> (B:Int => 0)
    </store>
    requires A >=Int 0 andBool B >=Int 0
    [all-path]

  // ===========================================================================
  //  (GCD) -- the function contract.
  //    Defining gcd and calling it on nonnegative A, B stores gcd(A, B).
  //    Precondition A >= 0 and B >= 0 (the verified domain -- see FINDINGS).
  //    The proof reuses (LOOP) as a lemma/circularity, instantiated at entry
  //    {a := A, b := B}; its side condition A,B >= 0 is exactly this precondition.
  // ===========================================================================
  // SPEC-PROVENANCE:
  // - claim: (GCD) function contract `result = gcd(A,B)` for `A,B >= 0`.
  // - from_prompt: P1 in PROMPTS.md: "Write `gcd(a, b)` returning the greatest common divisor of two non-negative integers via the Euclidean algorithm (`while b: a, b = b, a % b`). Self..." => `gcd(a,b)` should return the non-negative greatest common divisor of two non-negative integers.
  // - from_code: The code is Euclid's loop `while b: a, b = b, a % b` and then `return a`.
  // - conflicts/findings: The implementation accepts negative inputs; e.g. negative second arguments can produce a negative result, so FVK records the non-negativity precondition and...
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k>
      def gcd ( a , b ) : INDENT
        while b : INDENT a , b = b , a % b DEDENT
        return a
      DEDENT
      result = gcd ( A:Int , B:Int )
    => .K ... </k>
    <funcs> .Map => ?_:Map </funcs>
    <store> result |-> (_:Int => gcd(A, B)) </store>
    <stack> .List </stack>
    requires A >=Int 0 andBool B >=Int 0
    [all-path]
endmodule
