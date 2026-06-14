// =============================================================================
//  tree-height-spec.k  --  verification of tree_height.py (NOW SELF-CONTAINED:
//  it defines its OWN helper max2) as K `claim`s checkable by kprove.
//
//    kompile mini-python.k --backend haskell
//    kast    --backend haskell tree-height-spec.k    // confirm claims parse
//    kprove  tree-height-spec.k                        // expected: #Top (proved parts)
//
//  THREE claims -- TWO function contracts (max2 and tree_height) + the recursion
//  circularity that proves the second. Specifying EVERY function, the helper too:
//
//    (MAX2)   -- the helper contract: max2(X, Y) => the larger of X, Y. A clean,
//                NON-recursive, bundled-tier-clean proof. A nice demonstration that
//                a self-contained helper gets its OWN verified contract (its own
//                reachability claim), not a hand-wave. Discharged entirely by Z3.
//
//    (REC)    -- the recursion circularity for tree_height, the analog of the
//                sum-recursive (REC). K uses every claim in the module as a
//                coinduction hypothesis, so (REC) DISCHARGES ITS OWN TWO recursive
//                child calls (BRANCHING recursion): tree_height(left(T)) and
//                tree_height(right(T)). Guardedness is paid by the (call) step.
//                The post-value uses the inductive height MEASURE `h(T)` and MAX2.
//
//    (HEIGHT) -- the user-facing tree_height contract; its proof files both `def`s
//                and reduces the call by (REC) used as a lemma (and (MAX2) for the
//                combine step).
//
//  HONEST SCOPE -- the recursive-DATA-STRUCTURE frontier. The per-node step and
//  (MAX2) are bundled-tier clean. But the STRUCTURAL-INDUCTION PRINCIPLE over the
//  `Tree` datatype -- the rule that LIFTS "(base) holds for `none`" + "(step) holds
//  for `node(V,L,R)` given it holds for L and R" up to "holds for EVERY finite
//  Tree" -- is the [ESCALATION BOUNDARY] (route to LICS'19 / OOPSLA'20). It is
//  STATED below as an explicit obligation, NOT admitted as [trusted] (which would
//  manufacture confidence the kit does not have). See SPEC.md / FINDINGS.md / PROOF.md.
//
//  Height measure (inductive, over the Tree value sort):
//      h(none)         = 0
//      h(node(_,L,R))  = 1 + max2(h(L), h(R))
//  so the closed form returned by tree_height(T) is exactly h(T).
// =============================================================================

requires "mini-python.k"

module MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON-SYNTAX
  // Program variables (x, y, t, result) are lowercase, so they lex as Id and never
  // clash with K's (uppercase/?-prefixed) logical variables. No [token] needed.
endmodule

module VERIFICATION
  imports MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON
  imports MAP-SYMBOLIC
  imports K-EQUAL
  imports INT

  // ===========================================================================
  //  Spec-only abstraction functions over the Tree value sort -- "spec vocabulary,
  //  not language constructs" (cf. isSorted/bag in insertion-sort). They give the
  //  spec a clean way to talk about a Tree's structure and its height.
  // ===========================================================================

  // Selectors / predicate mirroring Python's `t[1]`, `t[2]`, `t is None` on the
  // verified domain (a well-formed Tree). Total on `Tree`.
  syntax Bool ::= isNone(Tree) [function, total]
  rule isNone(none)          => true
  rule isNone(node(_, _, _)) => false                                  [simplification]

  syntax Tree ::= left(Tree)  [function]
                | right(Tree) [function]
  rule left(node(_, L, _))  => L
  rule right(node(_, _, R)) => R
  // (left/right are intentionally PARTIAL: undefined on `none`, exactly as `t[1]`
  //  is never reached on the None branch -- the `if t is None: return 0` guard.)

  // The HEIGHT MEASURE -- the inductive closed form tree_height computes.
  //   h(none) = 0 ;  h(node(_,L,R)) = 1 + max2(h(L), h(R))
  // This `max2Int` is the MATH max used in the measure; the program's max2 function
  // is proved (by (MAX2)) to compute exactly this, which is what links the two
  // contracts.
  syntax Int ::= max2Int(Int, Int) [function, total]
  rule max2Int(A, B) => A requires A >Int B                            [simplification]
  rule max2Int(A, B) => B requires notBool (A >Int B)                 [simplification]

  syntax Int ::= h(Tree) [function]
  rule h(none)          => 0
  rule h(node(_, L, R)) => 1 +Int max2Int(h(L), h(R))                 [simplification]

  // Map extensionality: to close the (HEIGHT) post-store implication that pins
  // `result` (execution produces it via STORE[result <- V]). (Cf. Lesson 1.22.)
  rule { M:Map [ K <- V ] #Equals M:Map [ K <- V' ] } => { V #Equals V' }
    [simplification]

  // ===========================================================================
  //  [ESCALATION BOUNDARY] -- the structural-induction principle over `Tree`.
  //
  //  (T-IND)  To conclude  (REC) holds for EVERY finite Tree T, from:
  //             - base:  (REC) holds at T = none, and
  //             - step:  (REC) holds at T = node(V,L,R) GIVEN it holds at L and R,
  //           one needs the induction principle for the inductive sort `Tree`
  //           (the least-fixpoint / initial-algebra reasoning of Matching mu-Logic).
  //           The kit's bundled tier (Z3 linear arith + the simplification lemmas
  //           above) does the base and the per-node STEP cleanly; it does NOT supply
  //           the lifting from base+step to "all trees". That is the documented
  //           recursive-data-structure escalation (LICS'19 / OOPSLA'20).
  //
  //  Intentionally NOT written as `rule ... [trusted]`: admitting it would fake
  //  confidence. It is named here as an OPEN obligation and routed to the papers
  //  (see knowledge/sources.md). The base case and per-node step ARE discharged.
  // ===========================================================================
endmodule

module MINI-PYTHON-SPEC
  imports VERIFICATION

  // ===========================================================================
  //  (MAX2) -- the helper contract.  max2(X, Y) returns the larger of X and Y.
  //    A clean, NON-recursive, BUNDLED-TIER-CLEAN proof: one `if x > y` branch,
  //    each arm returns a parameter, closed-form post-value is max2Int(X, Y).
  //    No circularity, no induction -- discharged entirely by Z3 case-split on
  //    `X > Y`. This is the demonstration that a self-contained helper gets its
  //    OWN verified reachability claim.
  // ===========================================================================
  // SPEC-PROVENANCE:
  // - claim: (MAX2) helper contract for maximum of two integers.
  // - from_prompt: P1 in PROMPTS.md: "Write `tree_height(t)` for a binary tree (`None`, or a `(value, left, right)` tuple), recursively. Use your own `max2` helper (no `max`). Self-cont..." => `tree_height(t)` should return the height of a finite well-formed binary tree; helper `max2` should return the larger of two heights.
  // - from_code: The code represents empty trees as `None`, non-empty trees as `(value,left,right)`, computes child heights recursively, and uses `max2`.
  // - conflicts/findings: Deep degenerate trees hit Python recursion limits, and malformed tuple shapes are outside the verified domain.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k> max2 ( X:Int , Y:Int ) ~> CONT:K
     => max2Int(X, Y) ~> CONT </k>
    <funcs>
      ... max2 |-> def max2 ( x , y ) : INDENT
            if x > y : INDENT return x DEDENT
            else : INDENT return y DEDENT
          DEDENT ...
    </funcs>
    <store> STORE </store>
    <stack> STK:List </stack>
    [all-path]

  // ===========================================================================
  //  (REC) -- the recursion circularity for tree_height (the analog of a loop
  //    invariant; cf. sum-recursive's (REC)). Evaluating a call tree_height(T) at
  //    the head of <k> -- with BOTH functions already filed in <funcs> -- reduces
  //    to the inductive measure h(T), threading the continuation through, leaving
  //    <store>/<stack> net unchanged.
  //
  //    K uses this claim as its own coinduction hypothesis, so it discharges BOTH
  //    recursive CHILD calls tree_height(left(T)) and tree_height(right(T))
  //    (BRANCHING recursion -- two back-edges, each earned by its own (call) step).
  //    The combine step `1 + max2(.., ..)` uses (MAX2) as a lemma and the measure
  //    equation h(node(V,L,R)) = 1 + max2Int(h(L), h(R)).
  //
  //    NOTE on scope: per the [ESCALATION BOUNDARY] (T-IND) above, the lift of the
  //    base + per-node step to "all finite trees" needs Tree structural induction.
  //    The base (T = none) and the step (T = node(V,L,R), assuming (REC) at L,R)
  //    are bundled-tier clean; the LIFT is the open obligation.
  // ===========================================================================
  // SPEC-PROVENANCE:
  // - claim: (REC) recursive tree-height circularity.
  // - from_prompt: P1 in PROMPTS.md: "Write `tree_height(t)` for a binary tree (`None`, or a `(value, left, right)` tuple), recursively. Use your own `max2` helper (no `max`). Self-cont..." => `tree_height(t)` should return the height of a finite well-formed binary tree; helper `max2` should return the larger of two heights.
  // - from_code: The code represents empty trees as `None`, non-empty trees as `(value,left,right)`, computes child heights recursively, and uses `max2`.
  // - conflicts/findings: Deep degenerate trees hit Python recursion limits, and malformed tuple shapes are outside the verified domain.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k> tree_height ( T:Tree ) ~> CONT:K
     => h(T) ~> CONT </k>
    <funcs>
      ... max2 |-> def max2 ( x , y ) : INDENT
            if x > y : INDENT return x DEDENT
            else : INDENT return y DEDENT
          DEDENT
          tree_height |-> def tree_height ( t ) : INDENT
            if t is None : INDENT return 0 DEDENT
            return 1 + max2 ( tree_height ( t . left ) , tree_height ( t . right ) )
          DEDENT ...
    </funcs>
    <store> STORE </store>
    <stack> STK:List </stack>
    [all-path]

  // ===========================================================================
  //  (HEIGHT) -- the user-facing tree_height contract.
  //    Defining max2 and tree_height and calling tree_height on a well-formed tree
  //    T stores its height h(T). Proof: the two (def)s file both bodies (witnessing
  //    <funcs> .Map => ?_:Map), then `result = tree_height(T)` reduces by (REC) used
  //    as a lemma, and the assignment lands result |-> h(T) (closed via map ext.).
  // ===========================================================================
  // SPEC-PROVENANCE:
  // - claim: (HEIGHT) user-facing `tree_height` contract.
  // - from_prompt: P1 in PROMPTS.md: "Write `tree_height(t)` for a binary tree (`None`, or a `(value, left, right)` tuple), recursively. Use your own `max2` helper (no `max`). Self-cont..." => `tree_height(t)` should return the height of a finite well-formed binary tree; helper `max2` should return the larger of two heights.
  // - from_code: The code represents empty trees as `None`, non-empty trees as `(value,left,right)`, computes child heights recursively, and uses `max2`.
  // - conflicts/findings: Deep degenerate trees hit Python recursion limits, and malformed tuple shapes are outside the verified domain.
  // - scope: this example preserves the pre-repair source; a later FVK-guided coding iteration may use these findings to repair it.
  claim
    <k>
      def max2 ( x , y ) : INDENT
        if x > y : INDENT return x DEDENT
        else : INDENT return y DEDENT
      DEDENT
      def tree_height ( t ) : INDENT
        if t is None : INDENT return 0 DEDENT
        return 1 + max2 ( tree_height ( t . left ) , tree_height ( t . right ) )
      DEDENT
      result = tree_height ( T:Tree )
    => .K ... </k>
    <funcs> .Map => ?_:Map </funcs>
    <store> result |-> (_:KResult => h(T)) </store>
    <stack> .List </stack>
    [all-path]
endmodule
