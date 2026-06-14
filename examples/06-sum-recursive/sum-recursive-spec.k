// =============================================================================
//  sum-recursive-spec.k  -- verification of sum_recursive(n) as K `claim`s checkable
//  by kprove.
//
//    kompile mini-python.k --backend haskell
//    kast    --backend haskell sum-recursive-spec.k   // confirm claims parse (1 AST)
//    kprove  sum-recursive-spec.k                       // expected result: #Top
//
//  THE RECURSION SHAPE -- the new teaching payload vs. the sum-up / sum-down loops.
//  There is no loop, hence NO loop-invariant claim. The circularity is on the
//  RECURSIVE CALL'S CONTRACT. K's reachability prover uses every claim in the
//  module as a coinduction hypothesis, so:
//
//    (REC) -- the contract of a call `sum_recursive(N)` -- DISCHARGES ITS OWN
//             recursive call `sum_recursive(N-1)`. This is the exact analog of the
//             loop examples' (LOOP) claim discharging its own loop back-edge; here
//             the back-edge is a recursive call, and guardedness is provided by the
//             (call) step taken before the hypothesis is reused.
//    (SUM) -- the user-facing function contract. Its proof files the `def` and then
//             reduces the call by (REC) used as a lemma.
//
//  Closed form:  sum_recursive(N) = 0 + 1 + ... + N = N*(N+1)/2   for N >= 0.
//  Recursive-step VC:  N + (N-1)*N/2  =  N*(N+1)/2     (exact: (N-1)*N is even).
//  Base-case VC:       N == 0  =>  N*(N+1)/2 = 0       (Z3, zero factor).
// =============================================================================

requires "mini-python.k"

module MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON-SYNTAX
  // Program variables (n, result) are lowercase, so they lex as Id and never
  // clash with K's (uppercase/?-prefixed) logical variables. No [token] needed.
endmodule

module VERIFICATION
  imports MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON
  imports MAP-SYMBOLIC
  imports K-EQUAL

  // Map extensionality: needed to close the (SUM) post-store implication, since
  // execution produces the result binding via STORE[result <- V]. (Cf. Lesson 1.22.)
  rule { M:Map [ K <- V ] #Equals M:Map [ K <- V' ] } => { V #Equals V' }
    [simplification]

  // VC-EXACT: exact halving of an (always-even) product of consecutive integers.
  // The recursive step equates  N + (N-1)*N/2  with  N*(N+1)/2  under truncating
  // /Int; both (N-1)*N and N*(N+1) are products of consecutive integers, hence
  // even, so each /Int 2 is exact. (Same lemma family as the sum-up loop example;
  // here the product being halved is (N-1)*N, i.e. X*(X+1) at X = N-1.)
  rule (X:Int *Int (X +Int 1)) /Int 2 *Int 2 => X *Int (X +Int 1)
    [simplification]
  rule ((A:Int +Int B:Int) *Int C:Int) /Int 2 *Int 2 => (A +Int B) *Int C
    requires ((A +Int B) *Int C) modInt 2 ==Int 0
    [simplification]
endmodule

module MINI-PYTHON-SPEC
  imports VERIFICATION

  // (REC) -- the recursion circularity (the analog of a loop-invariant claim).
  //   Evaluating a call `sum_recursive(N)` at the head of <k> -- with the function
  //   already filed in <funcs> -- reduces to the value N*(N+1)/2 and threads the
  //   continuation CONT through unchanged, leaving <store> and <stack> net
  //   unchanged (the call pushes a frame and resets the scope; return pops and
  //   restores). Generalized over the symbolic argument N with side condition
  //   N >= 0.  K uses this claim as its own coinduction hypothesis, so it
  //   discharges the inner recursive call `sum_recursive(N-1)` (its precondition
  //   N-1 >= 0 follows from N >= 1 on the recursive branch).
  // SPEC-PROVENANCE:
  // - claim: (REC) recursive-call circularity for `sum_recursive(N)`.
  // - from_prompt: P1 in PROMPTS.md: "Let's write a very simple Python program which calculates the sum of numbers from 1 to n. Let's call it sum_recursive. It takes an input integer n...." => `sum_recursive(n)` should compute `1 + ... + n` recursively for non-negative, non-bool integers, with invalid inputs rejected.
  // - from_code: The code validates type/bool/negative cases and then uses the base case `n == 0` plus recursive case `n + sum_recursive(n-1)`.
  // - conflicts/findings: Here the validation guards are positive findings: they enforce the domain FVK needs. The real residual issue is Python recursion depth for large `n`.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k> sum_recursive ( N:Int ) ~> CONT:K
     => N *Int (N +Int 1) /Int 2 ~> CONT </k>
    <funcs>
      ... sum_recursive |-> def sum_recursive ( n ) : INDENT
            if n == 0 : INDENT return 0 DEDENT
            return n + sum_recursive ( n - 1 )
          DEDENT ...
    </funcs>
    <store> STORE </store>
    <stack> STK:List </stack>
    requires N >=Int 0
    [all-path]

  // (SUM) -- the function contract (user-facing).
  //   Defining sum_recursive and calling it on a non-negative N stores N*(N+1)/2.
  //   Proof: (def) files the body (witnessing <funcs> .Map => ?_:Map), then the
  //   call `result = sum_recursive(N)` reduces by (REC) used as a lemma, and the
  //   assignment lands result |-> N*(N+1)/2 (closed via map-extensionality).
  // SPEC-PROVENANCE:
  // - claim: (SUM) user-facing function contract `N*(N+1)/2` on the validated domain.
  // - from_prompt: P1 in PROMPTS.md: "Let's write a very simple Python program which calculates the sum of numbers from 1 to n. Let's call it sum_recursive. It takes an input integer n...." => `sum_recursive(n)` should compute `1 + ... + n` recursively for non-negative, non-bool integers, with invalid inputs rejected.
  // - from_code: The code validates type/bool/negative cases and then uses the base case `n == 0` plus recursive case `n + sum_recursive(n-1)`.
  // - conflicts/findings: Here the validation guards are positive findings: they enforce the domain FVK needs. The real residual issue is Python recursion depth for large `n`.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k>
      def sum_recursive ( n ) : INDENT
        if n == 0 : INDENT return 0 DEDENT
        return n + sum_recursive ( n - 1 )
      DEDENT
      result = sum_recursive ( N:Int )
    => .K ... </k>
    <funcs> .Map => ?_:Map </funcs>
    <store> result |-> (_:Int => N *Int (N +Int 1) /Int 2) </store>
    <stack> .List </stack>
    requires N >=Int 0
    [all-path]
endmodule
