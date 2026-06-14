// =============================================================================
//  is-even-odd-spec.k  -- verification of is_even(n) / is_odd(n) as K `claim`s
//  checkable by kprove.
//
//    kompile mini-python.k --backend haskell
//    kast    --backend haskell is-even-odd-spec.k   // confirm claims parse (1 AST)
//    kprove  is-even-odd-spec.k                       // expected result: #Top
//
//  THE MUTUAL-RECURSION SHAPE -- the new teaching payload vs. the single-recursion
//  sum-recursive example. There is no loop, hence NO loop-invariant claim. As in
//  sum-recursive the circularity is on the RECURSIVE CALL'S CONTRACT -- but here
//  the recursion is MUTUAL, so there are TWO contracts, and each is used as the
//  coinduction hypothesis for the OTHER's recursive call:
//
//    (EVEN) -- the contract of a call `is_even(N)`: reduces to `N mod 2 == 0`.
//              Its recursive branch calls `is_odd(N-1)`, discharged by (ODD).
//    (ODD)  -- the contract of a call `is_odd(N)`:  reduces to `N mod 2 == 1`.
//              Its recursive branch calls `is_even(N-1)`, discharged by (EVEN).
//
//  K's reachability prover treats EVERY claim in the module as a coinduction
//  hypothesis, so (EVEN) and (ODD) are BOTH available while proving EITHER. That is
//  precisely what mutual recursion needs: proving (EVEN) reuses (ODD) on its inner
//  call, and proving (ODD) reuses (EVEN) on its inner call. The circularity now
//  SPANS TWO CLAIMS that discharge each other (vs. the single self-discharging
//  (REC) in sum-recursive). Guardedness is paid, in each, by the (call) step taken
//  before the OTHER hypothesis is reused.
//
//    (EVENFN) / (ODDFN) -- the user-facing function contracts. Each files BOTH
//              defs (the two functions are mutually dependent, so both must be in
//              <funcs>) and then reduces the call by (EVEN)/(ODD) used as a lemma.
//
//  Spec-only evenness predicate.  The postcondition uses the builtin `modInt`:
//      is_even(N)  =>  N modInt 2 ==Int 0          (N >= 0)
//      is_odd(N)   =>  N modInt 2 ==Int 1          (N >= 0)
//  i.e. evenness is expressed as `N modInt 2 ==Int 0`, a spec-only predicate built
//  from the K builtin (no custom inductive symbol needed). The VCs the proof emits
//  about modInt are PURE-ARITHMETIC parity facts about a single fresh step
//  (mod-shift by 1), NOT an induction over N -- the induction is carried by the
//  CIRCULARITY, not by the predicate. See the [simplification] lemmas below and the
//  VC table / [ESCALATION BOUNDARY] discussion in PROOF.md.
// =============================================================================

requires "mini-python.k"

module MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON-SYNTAX
  // Program variables (n, r) are lowercase, so they lex as Id and never clash with
  // K's (uppercase/?-prefixed) logical variables. No [token] needed.
endmodule

module VERIFICATION
  imports MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON
  imports MAP-SYMBOLIC
  imports K-EQUAL

  // Map extensionality: needed to close the function-contract post-store
  // implication, since execution produces the result binding via STORE[r <- V].
  // (Cf. Lesson 1.22.) Here V is a Bool.
  rule { M:Map [ K <- V ] #Equals M:Map [ K <- V' ] } => { V #Equals V' }
    [simplification]

  // ---- parity mod-shift lemmas (the only arithmetic the mutual step needs) ----
  // The recursive step of (EVEN) reduces `is_even(N)` (N >= 1) to `is_odd(N-1)`,
  // whose contract value is `(N-1) modInt 2 ==Int 1`; the VC is then
  //     ( (N-1) modInt 2 ==Int 1 )  ==  ( N modInt 2 ==Int 0 )    for N >= 1.
  // Symmetrically for (ODD). Both are the single-step parity fact "subtracting 1
  // flips the parity bit", i.e. (N-1) mod 2 = 1 - (N mod 2) on N >= 1. These are
  // LINEAR-after-mod facts about ONE decrement -- Z3 with the lemmas below closes
  // them WITHOUT induction on N (the induction lives in the circularity).
  //
  // VC-EVEN-STEP:  for N >= 1,  (N-1) modInt 2 ==Int 1  <->  N modInt 2 ==Int 0
  rule (N:Int -Int 1) modInt 2 ==Int 1 => N modInt 2 ==Int 0
    requires N >=Int 1
    [simplification]
  // VC-ODD-STEP:   for N >= 1,  (N-1) modInt 2 ==Int 0  <->  N modInt 2 ==Int 1
  rule (N:Int -Int 1) modInt 2 ==Int 0 => N modInt 2 ==Int 1
    requires N >=Int 1
    [simplification]
endmodule

module MINI-PYTHON-SPEC
  imports VERIFICATION

  // The shared two-function definition prelude both contracts (and both function
  // claims) reason under. is_even and is_odd are MUTUALLY dependent, so the spec
  // always carries BOTH in <funcs>.
  //   def is_even(n): if n == 0: return True   ; return is_odd(n - 1)
  //   def is_odd(n):  if n == 0: return False  ; return is_even(n - 1)

  // ===========================================================================
  //  (EVEN) -- is_even's recursion circularity. Coinduction hypothesis for ODD.
  //   Evaluating a call `is_even(N)` at the head of <k> -- with BOTH functions
  //   already filed in <funcs> -- reduces to the Bool `N modInt 2 ==Int 0`,
  //   threading CONT unchanged, <store>/<stack> net unchanged. Side condition
  //   N >= 0. On the recursive branch (N >= 1) the inner call is `is_odd(N-1)`,
  //   discharged by the (ODD) claim used as the coinduction hypothesis (its
  //   precondition N-1 >= 0 follows from N >= 1).
  // ===========================================================================
  // SPEC-PROVENANCE:
  // - claim: (EVEN) recursive-call circularity for `is_even(N)`.
  // - from_prompt: P1 in PROMPTS.md: "Write two mutually recursive functions for n>=0: `is_even(n)` and `is_odd(n)` (is_even(0)=True, is_odd(0)=False; is_even(n)=is_odd(n-1), is_odd(n)=..." => `is_even` and `is_odd` should decide parity for non-negative integers using mutual recursion.
  // - from_code: The code uses the prompt's base cases and calls the opposite function on `n-1` in the recursive branch.
  // - conflicts/findings: For negative inputs the recursion moves away from the base case and ends in `RecursionError`; FVK records `n >= 0` as load-bearing for termination.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k> is_even ( N:Int ) ~> CONT:K
     => ( N modInt 2 ==Int 0 ) ~> CONT </k>
    <funcs>
      ... is_even |-> def is_even ( n ) : INDENT
            if n == 0 : INDENT return true DEDENT
            return is_odd ( n - 1 )
          DEDENT
          is_odd |-> def is_odd ( n ) : INDENT
            if n == 0 : INDENT return false DEDENT
            return is_even ( n - 1 )
          DEDENT ...
    </funcs>
    <store> STORE </store>
    <stack> STK:List </stack>
    requires N >=Int 0
    [all-path]

  // ===========================================================================
  //  (ODD) -- is_odd's recursion circularity. Coinduction hypothesis for EVEN.
  //   Symmetric to (EVEN): `is_odd(N)` reduces to `N modInt 2 ==Int 1`; on the
  //   recursive branch (N >= 1) the inner call is `is_even(N-1)`, discharged by
  //   the (EVEN) claim. THIS is the mutual-recursion crux: (EVEN) and (ODD)
  //   discharge each other's recursive call.
  // ===========================================================================
  // SPEC-PROVENANCE:
  // - claim: (ODD) recursive-call circularity for `is_odd(N)`.
  // - from_prompt: P1 in PROMPTS.md: "Write two mutually recursive functions for n>=0: `is_even(n)` and `is_odd(n)` (is_even(0)=True, is_odd(0)=False; is_even(n)=is_odd(n-1), is_odd(n)=..." => `is_even` and `is_odd` should decide parity for non-negative integers using mutual recursion.
  // - from_code: The code uses the prompt's base cases and calls the opposite function on `n-1` in the recursive branch.
  // - conflicts/findings: For negative inputs the recursion moves away from the base case and ends in `RecursionError`; FVK records `n >= 0` as load-bearing for termination.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k> is_odd ( N:Int ) ~> CONT:K
     => ( N modInt 2 ==Int 1 ) ~> CONT </k>
    <funcs>
      ... is_even |-> def is_even ( n ) : INDENT
            if n == 0 : INDENT return true DEDENT
            return is_odd ( n - 1 )
          DEDENT
          is_odd |-> def is_odd ( n ) : INDENT
            if n == 0 : INDENT return false DEDENT
            return is_even ( n - 1 )
          DEDENT ...
    </funcs>
    <store> STORE </store>
    <stack> STK:List </stack>
    requires N >=Int 0
    [all-path]

  // ===========================================================================
  //  (EVENFN) -- is_even's user-facing function contract.
  //   Defining BOTH functions and calling is_even on a non-negative N stores
  //   `N modInt 2 ==Int 0`. Proof: the two (def)s file both bodies (witnessing
  //   <funcs> .Map => ?_:Map), then `r = is_even(N)` reduces by (EVEN) used as a
  //   lemma, and the assignment lands r |-> (N modInt 2 ==Int 0) (closed via
  //   map-extensionality).
  // ===========================================================================
  // SPEC-PROVENANCE:
  // - claim: (EVENFN) user-facing contract for `is_even`.
  // - from_prompt: P1 in PROMPTS.md: "Write two mutually recursive functions for n>=0: `is_even(n)` and `is_odd(n)` (is_even(0)=True, is_odd(0)=False; is_even(n)=is_odd(n-1), is_odd(n)=..." => `is_even` and `is_odd` should decide parity for non-negative integers using mutual recursion.
  // - from_code: The code uses the prompt's base cases and calls the opposite function on `n-1` in the recursive branch.
  // - conflicts/findings: For negative inputs the recursion moves away from the base case and ends in `RecursionError`; FVK records `n >= 0` as load-bearing for termination.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k>
      def is_even ( n ) : INDENT
        if n == 0 : INDENT return true DEDENT
        return is_odd ( n - 1 )
      DEDENT
      def is_odd ( n ) : INDENT
        if n == 0 : INDENT return false DEDENT
        return is_even ( n - 1 )
      DEDENT
      r = is_even ( N:Int )
    => .K ... </k>
    <funcs> .Map => ?_:Map </funcs>
    <store> r |-> (_:Bool => N modInt 2 ==Int 0) </store>
    <stack> .List </stack>
    requires N >=Int 0
    [all-path]

  // ===========================================================================
  //  (ODDFN) -- is_odd's user-facing function contract (symmetric).
  // ===========================================================================
  // SPEC-PROVENANCE:
  // - claim: (ODDFN) user-facing contract for `is_odd`.
  // - from_prompt: P1 in PROMPTS.md: "Write two mutually recursive functions for n>=0: `is_even(n)` and `is_odd(n)` (is_even(0)=True, is_odd(0)=False; is_even(n)=is_odd(n-1), is_odd(n)=..." => `is_even` and `is_odd` should decide parity for non-negative integers using mutual recursion.
  // - from_code: The code uses the prompt's base cases and calls the opposite function on `n-1` in the recursive branch.
  // - conflicts/findings: For negative inputs the recursion moves away from the base case and ends in `RecursionError`; FVK records `n >= 0` as load-bearing for termination.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k>
      def is_even ( n ) : INDENT
        if n == 0 : INDENT return true DEDENT
        return is_odd ( n - 1 )
      DEDENT
      def is_odd ( n ) : INDENT
        if n == 0 : INDENT return false DEDENT
        return is_even ( n - 1 )
      DEDENT
      r = is_odd ( N:Int )
    => .K ... </k>
    <funcs> .Map => ?_:Map </funcs>
    <store> r |-> (_:Bool => N modInt 2 ==Int 1) </store>
    <stack> .List </stack>
    requires N >=Int 0
    [all-path]
endmodule
