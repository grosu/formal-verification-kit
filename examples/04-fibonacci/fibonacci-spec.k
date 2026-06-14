// =============================================================================
//  fibonacci-spec.k  -- verification of fib(n) as K `claim`s checkable by kprove.
//
//    kompile mini-python.k --backend haskell
//    kast    --backend haskell fibonacci-spec.k   // confirm claims parse (1 AST)
//    kprove  fibonacci-spec.k                       // expected result: #Top
//
//  STATUS: constructed, not machine-checked (the kit's MVP does not run the
//  toolchain). Everything below is built to be kprove-checkable.
//
//  THE SHAPE.  fib(n) is an ITERATIVE loop (a count-up `while`), so -- like the
//  sum-up / sum-down examples and UNLIKE sum-recursive -- it is verified by a
//  LOOP-INVARIANT circularity, NOT a recursive-call contract. What is new here is
//  the POSTCONDITION VOCABULARY: the quantity computed is itself defined by a
//  RECURRENCE, so we introduce a SPEC-ONLY recursive symbol `fib(Int) [function]`
//  (NOT a language construct -- it never appears in mini-python.k; it is pure spec
//  vocabulary, exactly the "spec-only abstraction function" idea from
//  knowledge/k-framework.md). The loop invariant couples the two running program
//  values to consecutive Fibonacci numbers:  prev = fib(I),  curr = fib(I+1).
//
//  THE INDUCTIVE STEP IS DEFINITIONAL.  The body does prev, curr = curr, prev+curr.
//  Under the invariant that is  fib(I), fib(I+1)  =>  fib(I+1), fib(I)+fib(I+1).
//  By fib's OWN defining rule fib(I+2) = fib(I) + fib(I+1) (for I+2 > 1, i.e.
//  I >= 0), the new pair is exactly fib(I+1), fib((I+1)+1). So the step VC is
//  discharged by UNFOLDING fib's defining equation -- no nonlinear arithmetic, no
//  exact-halving lemma (contrast sum-up, whose step needed division-by-even). The
//  only arithmetic VC is the trivial guard bookkeeping, handled by Z3.
// =============================================================================

requires "mini-python.k"

module MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON-SYNTAX
  // Program variables (prev, curr, i, n, result) are lowercase, so they lex as Id
  // and never clash with K's (uppercase/?-prefixed) logical variables. No [token]
  // declarations are required.
endmodule

module VERIFICATION
  imports MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON
  imports MAP-SYMBOLIC
  imports K-EQUAL
  imports INT

  // ---- SPEC-ONLY recursive symbol: the mathematical Fibonacci function --------
  //   This is spec VOCABULARY, not a language construct. It does NOT appear in
  //   mini-python.k and the program never calls it; it exists only so the claims
  //   can name the quantity fib(n) computes. Declared [function] (total on its
  //   declared domain -- see the ESCALATION BOUNDARY note below), [smtlib] so the
  //   prover can carry it as an uninterpreted symbol constrained by its three
  //   defining [simplification] rules.
  syntax Int ::= fib(Int) [function, total, smtlib(fib)]

  // fib's DEFINING rules (fib(0)=0, fib(1)=1, fib(N)=fib(N-1)+fib(N-2) for N>1).
  // These are the ONLY facts about fib the proof uses; the inductive-step VC is
  // discharged by unfolding the third rule (read right side as fib((N-2)) at the
  // shifted index). Stated as [simplification] so kprove rewrites with them
  // wherever a fib term appears in a side condition.
  rule fib(0) => 0                                    [simplification]
  rule fib(1) => 1                                    [simplification]
  rule fib(N:Int) => fib(N -Int 1) +Int fib(N -Int 2)
    requires N >Int 1                                 [simplification]

  // Map extensionality: needed to close the (FIB) post-store implication, since
  // execution produces the result binding via STORE[result <- V]. (Cf. Lesson 1.22.)
  rule { M:Map [ K <- V ] #Equals M:Map [ K <- V' ] } => { V #Equals V' }
    [simplification]
endmodule

module MINI-PYTHON-SPEC
  imports VERIFICATION

  // (LOOP) -- the loop invariant = the circularity.
  //   From any state with prev = fib(I), curr = fib(I+1), i = I, n = N, and the
  //   soundness side condition 0 <= I <= N, running the loop reaches
  //   prev = fib(N), curr = fib(N+1), i = N. K's reachability prover uses every
  //   claim in the module as a coinduction hypothesis (a circularity), so (LOOP)
  //   DISCHARGES ITS OWN loop -- this is the circularity of the proof.
  //
  //   COUPLED two-variable invariant: the two running values track consecutive
  //   Fibonacci numbers. The inductive step is DEFINITIONAL: the body sends
  //   (fib(I), fib(I+1)) to (fib(I+1), fib(I)+fib(I+1)) = (fib(I+1), fib(I+2))
  //   by fib's third defining rule. The side condition 0 <= I keeps that unfold
  //   valid (I+2 > 1); I <= N keeps the counter in range.
  //   The coupling is stated in the LHS store: prev starts at fib(I), curr at
  //   fib(I+1). Those entry values are the heart of the invariant.
  // SPEC-PROVENANCE:
  // - claim: (LOOP) coupled-accumulator loop circularity relating `prev`,`curr` to consecutive Fibonacci values.
  // - from_prompt: P1 in PROMPTS.md: "Write `fib(n)` returning the n-th Fibonacci number (fib(0)=0, fib(1)=1) with an iterative `while` loop and two running values. Self-contained — no..." => `fib(n)` should return the nth Fibonacci number for `n >= 0`, with `fib(0)=0` and `fib(1)=1`.
  // - from_code: The code uses coupled accumulators `prev` and `curr` and advances them in a `while i < n` loop.
  // - conflicts/findings: For negative inputs the loop does not run and the implementation returns `0`, so FVK records the missing `n >= 0` precondition.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k>
      while i < n : INDENT prev , curr = curr , prev + curr  i = i + 1 DEDENT => .K ...
    </k>
    <store>
      prev |-> (fib(I) => fib(N))
      curr |-> (fib(I +Int 1) => fib(N +Int 1))
      i    |-> (I:Int => N)
      n    |-> N:Int
    </store>
    requires 0 <=Int I andBool I <=Int N
    [all-path]

  // (FIB) -- the function contract.
  //   Defining fib and calling it on a non-negative N stores fib(N).
  //   Proof: (def) files the body (witnessing <funcs> .Map => ?_:Map); the call
  //   inits prev=0=fib(0), curr=1=fib(1), i=0; then (LOOP) is used as a lemma at
  //   entry I = 0 (its side condition 0 <= 0 <= N follows from N >= 0), reaching
  //   prev = fib(N); `return prev` delivers it; result |-> fib(N).
  // SPEC-PROVENANCE:
  // - claim: (FIB) function contract `result = fib(N)` for `N >= 0`.
  // - from_prompt: P1 in PROMPTS.md: "Write `fib(n)` returning the n-th Fibonacci number (fib(0)=0, fib(1)=1) with an iterative `while` loop and two running values. Self-contained — no..." => `fib(n)` should return the nth Fibonacci number for `n >= 0`, with `fib(0)=0` and `fib(1)=1`.
  // - from_code: The code uses coupled accumulators `prev` and `curr` and advances them in a `while i < n` loop.
  // - conflicts/findings: For negative inputs the loop does not run and the implementation returns `0`, so FVK records the missing `n >= 0` precondition.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k>
      def fib ( n ) : INDENT
        prev = 0
        curr = 1
        i = 0
        while i < n : INDENT prev , curr = curr , prev + curr  i = i + 1 DEDENT
        return prev
      DEDENT
      result = fib ( N:Int )
    => .K ... </k>
    <funcs> .Map => ?_:Map </funcs>
    <store> result |-> (_:Int => fib(N)) </store>
    <stack> .List </stack>
    requires N >=Int 0
    [all-path]
endmodule
