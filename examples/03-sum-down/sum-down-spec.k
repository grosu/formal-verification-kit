// =============================================================================
//  sum-down-spec.k  -- verification of sum_to_n(n) as K `claim`s for kprove.
//
//    kompile mini-python.k --backend haskell
//    kast    --backend haskell sum-down-spec.k    // confirm claims parse (1 AST)
//    kprove  sum-down-spec.k                       // expected result: #Top
//
//  (LOOP) loop-invariant claim. K's reachability prover uses every claim in the
//         module as a coinduction hypothesis (a circularity), so (LOOP)
//         discharges ITS OWN loop -- this is the (LOOP) circularity of the proof.
//  (SUM)  the function contract. Its proof reuses (LOOP) as a lemma/circularity.
//
//  This program counts DOWN (i = n; while i >= 1: total += i; i -= 1), so the
//  loop's running sum, generalized over the counter I, is
//      sum_{k=1}^{I} k = I*(I+1)/2 ,
//  and the loop exits at i = 0.  Unlike the up-counting `sum` example, the guard
//  `i >= 1` compares to the CONSTANT 1, so `n` does not occur in (LOOP) at all --
//  the loop's effect depends only on `total` and `i` (encoded by the `...` map
//  frame in (LOOP)'s <store>).
//  At loop entry from the function, I = N, giving total = N*(N+1)/2.
// =============================================================================

requires "mini-python.k"

module MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON-SYNTAX
  // Program variables (total, i, n, sum_to_n, result) are lowercase, so they lex
  // as Id and never clash with K's (uppercase/?-prefixed) logical variables. No
  // [token] declarations are required.
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
  // The down-counting inductive step VC1 (peel the top term) is
  //     I + cf(I-1) = cf(I),  where  cf(J) = J*(J+1)/2,
  // and cf(I-1) = (I-1)*((I-1)+1)/2 matches the X*(X+1)/2 shape with X = I-1, so
  // the same exact-halving lemmas the up-counting example needed apply here:
  // the division is by a SYMBOLIC even product under truncating /Int, which Z3
  // will not equate on its own.
  rule (X:Int *Int (X +Int 1)) /Int 2 *Int 2 => X *Int (X +Int 1)
    [simplification]
  rule ((A:Int +Int B:Int) *Int C:Int) /Int 2 *Int 2 => (A +Int B) *Int C
    requires ((A +Int B) *Int C) modInt 2 ==Int 0
    [simplification]
endmodule

module MINI-PYTHON-SPEC
  imports VERIFICATION

  // (LOOP) -- the down-counting loop invariant = the circularity.
  //   From any state with total = T, i = I and I >= 0, running the loop
  //   adds  sum_{k=1}^{I} k = I*(I+1)/2  to total and leaves i = 0.
  //   `n` (and anything else in scope) is framed out by `...`: this loop's
  //   effect is independent of n.  Side condition I >= 0 is load-bearing: drop
  //   it and for I <= -2 the body still never runs (so the true added sum is 0)
  //   but the closed form I*(I+1)/2 is positive -- the claim would be FALSE.
  // SPEC-PROVENANCE:
  // - claim: (LOOP) count-down loop circularity with remaining-work closed form.
  // - from_prompt: P1 in PROMPTS.md: "Let's write a very simple Python program which calculates the sum of numbers from 1 to n. Let's call it sum. It takes an input integer n. Let's do..." => `sum_to_n(n)` should compute `1 + ... + n` using a decreasing counter on the intended non-negative domain.
  // - from_code: The code initializes `total = 0`, `i = n`, loops while `i >= 1`, accumulates `total += i`, decrements `i`, and returns `total`.
  // - conflicts/findings: For negative inputs the loop never runs and returns `0`; FVK records the missing `n >= 0` precondition. The stdin wrapper is outside the verified core.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k>
      while i >= 1 : INDENT total += i  i -= 1 DEDENT => .K ...
    </k>
    <store>
      total |-> (T:Int => T +Int I *Int (I +Int 1) /Int 2)
      i     |-> (I:Int => 0)
      ...
    </store>
    requires I >=Int 0
    [all-path]

  // (SUM) -- the function contract.
  //   Defining sum_to_n and calling it on a non-negative N stores N*(N+1)/2.
  //   The body sets total = 0, i = n (= N), then runs the loop; applying (LOOP)
  //   at {T := 0, I := N} (its side condition 0 <= N is exactly the precondition)
  //   gives total = N*(N+1)/2, which `return` delivers to `result`.
  // SPEC-PROVENANCE:
  // - claim: (SUM) function contract `N*(N+1)/2` for `N >= 0`.
  // - from_prompt: P1 in PROMPTS.md: "Let's write a very simple Python program which calculates the sum of numbers from 1 to n. Let's call it sum. It takes an input integer n. Let's do..." => `sum_to_n(n)` should compute `1 + ... + n` using a decreasing counter on the intended non-negative domain.
  // - from_code: The code initializes `total = 0`, `i = n`, loops while `i >= 1`, accumulates `total += i`, decrements `i`, and returns `total`.
  // - conflicts/findings: For negative inputs the loop never runs and returns `0`; FVK records the missing `n >= 0` precondition. The stdin wrapper is outside the verified core.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k>
      def sum_to_n ( n ) : INDENT
        total = 0
        i = n
        while i >= 1 : INDENT total += i  i -= 1 DEDENT
        return total
      DEDENT
      result = sum_to_n ( N:Int )
    => .K ... </k>
    <funcs> .Map => ?_:Map </funcs>
    <store> result |-> (_:Int => N *Int (N +Int 1) /Int 2) </store>
    <stack> .List </stack>
    requires N >=Int 0
    [all-path]
endmodule
