// =============================================================================
//  mini-python-spec.k  -- verification of sum(n) as K `claim`s checkable by kprove.
//
//    kompile mini-python.k --backend haskell
//    kast    --backend haskell mini-python-spec.k    // confirm claims parse (1 AST)
//    kprove  mini-python-spec.k                       // expected result: #Top
//
//  (LOOP) loop-invariant claim. K's reachability prover uses every claim in the
//         module as a coinduction hypothesis (a circularity), so (LOOP)
//         discharges ITS OWN loop -- this is the (LOOP) circularity of the proof.
//  (SUM)  the function contract. Its proof reuses (LOOP) as a lemma/circularity.
//
//  Running sum, two equal closed forms (we use the first; Z3-friendlier):
//      sum_{k=I}^{N} k = (I+N)*(N-I+1)/2  =  (N*(N+1) - (I-1)*I)/2
//  At I = 1 both equal N*(N+1)/2.
// =============================================================================

requires "mini-python.k"

module MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON-SYNTAX
  // Program variables (s, i, n, sum, result) are lowercase, so they lex as Id
  // and never clash with K's (uppercase/?-prefixed) logical variables. No
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
  // Unlike Lesson 1.22's down-counting loop (a single product, no simplifications
  // needed), the up-counting invariant divides a SYMBOLIC product and the
  // inductive step equates two distinct products under Euclidean /Int, so these
  // are needed -- not merely held in reserve.
  rule (X:Int *Int (X +Int 1)) /Int 2 *Int 2 => X *Int (X +Int 1)
    [simplification]
  rule ((A:Int +Int B:Int) *Int C:Int) /Int 2 *Int 2 => (A +Int B) *Int C
    requires ((A +Int B) *Int C) modInt 2 ==Int 0
    [simplification]
endmodule

module MINI-PYTHON-SPEC
  imports VERIFICATION

  // (LOOP) -- the loop invariant = the circularity.
  //   From any state with i = I, s = S, n = N and I <= N+1, running the loop
  //   adds  sum_{k=I}^{N} k = (I+N)*(N-I+1)/2  to s and leaves i = N+1.
  claim
    <k>
      while i <= n : INDENT s += i  i += 1 DEDENT => .K ...
    </k>
    <store>
      s |-> (S:Int => S +Int (I +Int N) *Int (N -Int I +Int 1) /Int 2)
      i |-> (I:Int => N +Int 1)
      n |-> N:Int
    </store>
    requires I <=Int N +Int 1
    [all-path]

  // (SUM) -- the function contract.
  //   Defining sum and calling it on a non-negative N stores N*(N+1)/2.
  claim
    <k>
      def sum ( n ) : INDENT
        s = 0
        i = 1
        while i <= n : INDENT s += i  i += 1 DEDENT
        return s
      DEDENT
      result = sum ( N:Int )
    => .K ... </k>
    <funcs> .Map => ?_:Map </funcs>
    <store> result |-> (_:Int => N *Int (N +Int 1) /Int 2) </store>
    <stack> .List </stack>
    requires N >=Int 0
    [all-path]
endmodule
