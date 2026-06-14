// =============================================================================
//  mini-python-spec.k  -- verification of factorial(n) as K `claim`s checkable
//  by kprove.
//
//    kompile mini-python.k --backend haskell
//    kast    --backend haskell mini-python-spec.k   // confirm claims parse (1 AST)
//    kprove  mini-python-spec.k                       // expected result: #Top
//
//  THE RECURSION SHAPE -- same as the sum-recursive sibling: no loop, hence NO
//  loop-invariant claim; the circularity is on the RECURSIVE CALL'S CONTRACT. K's
//  reachability prover uses every claim in the module as a coinduction hypothesis,
//  so:
//
//    (REC) -- the contract of a call `factorial(N)` -- DISCHARGES ITS OWN recursive
//             call `factorial(N-1)`. The back-edge is the recursive call;
//             guardedness is provided by the (call) step taken before the
//             hypothesis is reused.
//    (FACT) -- the user-facing function contract. Its proof files the `def` and
//             then reduces the call by (REC) used as a lemma.
//
//  THE NEW PAYLOAD vs. sum-recursive: NO POLYNOMIAL CLOSED FORM.
//  ---------------------------------------------------------------------------
//  sum_recursive(N) had the closed form N*(N+1)/2, a polynomial; its step VC
//  ( N + (N-1)*N/2 = N*(N+1)/2 ) closed via an exact-halving [simplification]
//  lemma over /Int. factorial has NO polynomial (or any algebraic) closed form:
//  n! grows faster than every polynomial and is not expressible as a fixed-degree
//  arithmetic term. The kit's reachability-and-circularities primer §7 names this
//  exact case ("factorial's N!/(I-1)!") as needing "a recursively-defined symbol
//  and its own simplification lemmas." So we introduce a SPEC-ONLY recursive
//  function symbol  fact(Int) [function]  -- spec vocabulary, NOT a language
//  construct -- with the defining rules
//        fact(0) = 1
//        fact(N) = N *Int fact(N -Int 1)   for N >Int 0
//  and state the postcondition as  result |-> fact(N)  rather than a closed form.
//
//  Recursive-step VC:  N *Int fact(N -Int 1)  =  fact(N)   for N >Int 0.
//  This discharges by fact's OWN DEFINING RULE (definitional unfolding): the rule
//  `fact(N) => N *Int fact(N -Int 1) requires N >Int 0` rewrites the RHS to the LHS
//  syntactically -- NO exact-halving lemma, NO nonlinear arithmetic over /Int is
//  needed (factorial uses no division at all). This is strictly SIMPLER at the VC
//  tier than sum-recursive's halving lemma; the difficulty moved entirely into
//  *defining* the spec symbol, which is the honest cost of "no closed form."
//  Base-case VC:  N == 0  =>  fact(N) = 1  -- by fact's base rule fact(0) = 1.
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
  imports INT

  // ---- spec-only recursive function symbol -----------------------------------
  // `fact` is VERIFICATION-module vocabulary only: it is the mathematical n! used
  // to STATE the postcondition. It is NOT part of mini-python (the language the
  // program is written in); the program never names it. It mirrors factorial's own
  // recursion, which is exactly why the recursive-step VC discharges by unfolding.
  syntax Int ::= fact(Int) [function, total]

  rule fact(0) => 1
  rule fact(N:Int) => N *Int fact(N -Int 1)   requires N >Int 0

  // Map extensionality: needed to close the (FACT) post-store implication, since
  // execution produces the result binding via STORE[result <- V]. (Cf. Lesson 1.22.)
  rule { M:Map [ K <- V ] #Equals M:Map [ K <- V' ] } => { V #Equals V' }
    [simplification]

  // NOTE -- deliberately NO exact-halving / division lemma here (unlike the
  // sum-recursive and sum-up examples). factorial uses no /Int; the only nonlinear
  // fact the proof needs -- the recursive step  N *Int fact(N-1) = fact(N)  -- is
  // discharged by the *defining rule* of `fact` above (definitional unfolding),
  // not by a bespoke arithmetic [simplification] lemma.
endmodule

module MINI-PYTHON-SPEC
  imports VERIFICATION

  // (REC) -- the recursion circularity (the analog of a loop-invariant claim).
  //   Evaluating a call `factorial(N)` at the head of <k> -- with the function
  //   already filed in <funcs> -- reduces to the value fact(N) and threads the
  //   continuation CONT through unchanged, leaving <store> and <stack> net
  //   unchanged (the call pushes a frame and resets the scope; return pops and
  //   restores). Generalized over the symbolic argument N with side condition
  //   N >= 0.  K uses this claim as its own coinduction hypothesis, so it
  //   discharges the inner recursive call `factorial(N-1)` (its precondition
  //   N-1 >= 0 follows from N >= 1 on the recursive branch).
  // SPEC-PROVENANCE:
  // - claim: (REC) recursive-call circularity for `factorial(N)`.
  // - from_prompt: P1 in PROMPTS.md: "Write a Python function `factorial(n)` that returns n factorial (n! = 1·2·…·n, with 0! = 1) for a non-negative integer n. Use recursion. Add a few..." => `factorial(n)` should return `n!` for non-negative integers, with `0! = 1`.
  // - from_code: The code raises on `n < 0`, returns `1` at `n == 0`, and otherwise returns `n * factorial(n-1)`.
  // - conflicts/findings: The negative guard is a positive finding, but `bool` values slip through as integers and deep recursion hits Python recursion limits.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k> factorial ( N:Int ) ~> CONT:K
     => fact ( N ) ~> CONT </k>
    <funcs>
      ... factorial |-> def factorial ( n ) : INDENT
            if n == 0 : INDENT return 1 DEDENT
            return n * factorial ( n - 1 )
          DEDENT ...
    </funcs>
    <store> STORE </store>
    <stack> STK:List </stack>
    requires N >=Int 0
    [all-path]

  // (FACT) -- the function contract (user-facing).
  //   Defining factorial and calling it on a non-negative N stores fact(N).
  //   Proof: (def) files the body (witnessing <funcs> .Map => ?_:Map), then the
  //   call `result = factorial(N)` reduces by (REC) used as a lemma, and the
  //   assignment lands result |-> fact(N) (closed via map-extensionality).
  // SPEC-PROVENANCE:
  // - claim: (FACT) user-facing function contract `result = fact(N)` for `N >= 0`.
  // - from_prompt: P1 in PROMPTS.md: "Write a Python function `factorial(n)` that returns n factorial (n! = 1·2·…·n, with 0! = 1) for a non-negative integer n. Use recursion. Add a few..." => `factorial(n)` should return `n!` for non-negative integers, with `0! = 1`.
  // - from_code: The code raises on `n < 0`, returns `1` at `n == 0`, and otherwise returns `n * factorial(n-1)`.
  // - conflicts/findings: The negative guard is a positive finding, but `bool` values slip through as integers and deep recursion hits Python recursion limits.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k>
      def factorial ( n ) : INDENT
        if n == 0 : INDENT return 1 DEDENT
        return n * factorial ( n - 1 )
      DEDENT
      result = factorial ( N:Int )
    => .K ... </k>
    <funcs> .Map => ?_:Map </funcs>
    <store> result |-> (_:Int => fact ( N )) </store>
    <stack> .List </stack>
    requires N >=Int 0
    [all-path]
endmodule
