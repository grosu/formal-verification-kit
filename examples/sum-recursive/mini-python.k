// =============================================================================
//  mini-python.k
//  "mini Python": a MINIMAL K semantics for exactly the fragment of Python used
//  by the (in-domain) core of sum_recursive(n). Constructs covered, and NOTHING
//  else: integer literals and names; + ; - ; == ; assignment x = e ;
//  if (NO else) ; function def ; return ; (recursive) function call.
//  NO while, NO += , NO <= , NO < (this program uses none of those).
//
//  Adapted from K Tutorial Lesson 1.22 and the sum-up example: we keep the proven
//  <k>/<store>/<funcs>/<stack> configuration, the call/return machinery, and the
//  Bot/Bots list construction. RECURSION NEEDS NO NEW MACHINERY -- the same
//  stack-based call/return handles a function that calls itself: each recursive
//  call pushes its own frame, and <funcs> is FRAMED (never reset by a call), so
//  the definition persists and the self-call re-finds it.  This is the one real
//  difference from the sum-up/sum-down loop examples: there is no `while`, and the
//  recursion is carried entirely by call/return + the (REC) circularity in the
//  spec file.
//
//  GUARD-LAYER NOTE (the one modeling decision).  The real sum_recursive also has
//  type guards (`isinstance` / `raise TypeError`) and a value guard
//  (`if n < 0: raise ValueError`). On the VERIFIED DOMAIN (n a non-negative int,
//  not a bool) every one of those guards is a no-op -- it passes and falls through
//  -- so the *value* semantics of the function is EXACTLY the reduced body modeled
//  here:
//        def sum_recursive(n):
//            if n == 0: return 0
//            return n + sum_recursive(n - 1)
//  The raise/isinstance layer (Python exceptions) is deliberately NOT modeled --
//  exceptions are an escalation case for this kit -- because it ENFORCES the
//  precondition n >= 0 rather than affecting the in-domain value. That guard layer
//  is turned into a (positive) finding instead; see SPEC.md / FINDINGS.md. The
//  `__main__` I/O block is likewise outside the verified core and not modeled.
//
//  INDENTATION NOTE.  As in the sum-up example, a suite is modeled as the
//  token-bracketed block  Suite ::= "INDENT" Stmt "DEDENT"  (K's parser is not
//  whitespace-sensitive). Displayed Python indentation corresponds 1-1 to
//  INDENT ... DEDENT here; this affects only layout, never semantics.
// =============================================================================

module MINI-PYTHON-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  // ---- expressions ----------------------------------------------------------
  syntax IExp ::= Id | Int
                | "(" IExp ")"            [bracket]
                > Id "(" IExps ")"        [strict(2)]         // call (binds tightest)
                > IExp "+" IExp           [seqstrict, left]   // addition    (n + ...)
                | IExp "-" IExp           [seqstrict, left]   // subtraction (n - 1)

  syntax BExp ::= Bool
                | IExp "==" IExp          [seqstrict]         // equality test (n == 0)

  // Argument/parameter lists. The shared klabel(exps) Bot/Bots construction makes
  // Ints (evaluated args, a KResult) and Ids (parameters) BOTH subsorts of the
  // strict IExps list, so `IS:Ints` is a legal call argument, the seqstrict arg
  // list cools to an Ints KResult, and `.Bots` is the shared empty terminator
  // usable as both `.Ids` and `.Ints`.  (Cf. K Tutorial Lesson 1.22.)
  syntax Bot
  syntax Bots  ::= List{Bot,  ","}        [klabel(exps)]
  syntax Ints  ::= List{Int,  ","}        [klabel(exps)] | Bots   // evaluated args
  syntax Ids   ::= List{Id,   ","}        [klabel(exps)] | Bots   // parameters
  syntax IExps ::= List{IExp, ","}        [klabel(exps), seqstrict] | Ints | Ids

  syntax KResult ::= Int | Bool | Ints

  // ---- statements -----------------------------------------------------------
  // Suite-headed/leaf statements bind TIGHTER than sequencing (the `>` block),
  // and a Suite is itself a Stmt, so an INDENT...DEDENT block is self-delimiting
  // and the parser knows where an if/def body ends.
  syntax Stmt ::= Id "=" IExp                       [strict(2)]   // assignment
                | "if" BExp ":" Suite                             // if  (NO else)
                | "def" Id "(" Ids ")" ":" Suite                  // function def
                | "return" IExp                     [seqstrict]   // return
                | Id "(" IExps ")"                  [strict(2)]   // call stmt
                | Suite
                > Stmt Stmt                          [left]        // sequencing

  // A suite (indented block); see the INDENTATION NOTE above.
  syntax Suite ::= "INDENT" Stmt "DEDENT"
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports INT
  imports BOOL
  imports MAP
  imports LIST

  configuration
    <k> $PGM:Stmt </k>
    <store> .Map  </store>     // program variables  Id |-> Int
    <funcs> .Map  </funcs>     // function table      Id |-> (def ...)
    <stack> .List </stack>     // call stack of saved (continuation, store)

  // ---- expressions ----------------------------------------------------------
  rule <k> X:Id => V ... </k>
       <store> ... X |-> V ... </store>

  rule <k> I1:Int + I2:Int => I1 +Int I2 ... </k>
  rule <k> I1:Int - I2:Int => I1 -Int I2 ... </k>
  rule <k> I1:Int == I2:Int => I1 ==Int I2 ... </k>

  // ---- statement sequencing (newline) ---------------------------------------
  rule <k> S1:Stmt S2:Stmt => S1 ~> S2 ... </k>

  // ---- suite unwrapping -----------------------------------------------------
  rule <k> INDENT S:Stmt DEDENT => S ... </k>

  // ---- assignment -----------------------------------------------------------
  rule <k> X:Id = I:Int => .K ... </k>
       <store> STORE => STORE [ X <- I ] </store>

  // ---- if  (NO else): run the suite if the guard is true, skip it if false ---
  //   The program uses early-return guards (`if n == 0: return 0`), so an `if`
  //   with no else suffices: a false guard simply falls through to the next
  //   statement (the recursive `return`).
  rule <k> if true  : S:Suite => S  ... </k>
  rule <k> if false : _:Suite => .K ... </k>

  // ---- function definition --------------------------------------------------
  rule <k> def FNAME:Id ( ARGS:Ids ) : BODY:Suite => .K ... </k>
       <funcs> FS => FS [ FNAME <- def FNAME ( ARGS ) : BODY ] </funcs>

  // ---- function call (args already evaluated to Ints by strict(2)) ----------
  //   Recursion-ready with NO extra machinery: <funcs> is matched/framed (not
  //   reset), so a self-call re-finds the same definition; <store> is reset to a
  //   fresh scope and the caller's (continuation, store) is pushed on <stack>.
  rule <k> FNAME:Id ( IS:Ints ) ~> CONT => #makeBindings(ARGS, IS) ~> BODY </k>
       <funcs> ... FNAME |-> def FNAME ( ARGS:Ids ) : BODY:Suite ... </funcs>
       <store> STORE => .Map </store>
       <stack> .List => ListItem(state(CONT, STORE)) ... </stack>

  // ---- return ---------------------------------------------------------------
  rule <k> return I:Int ~> _ => I ~> CONT </k>
       <stack> ListItem(state(CONT, STORE)) => .List ... </stack>
       <store> _ => STORE </store>

  rule <k> return I:Int ~> .K => I </k>
       <stack> .List </stack>

  // ---- parameter binding -----------------------------------------------------
  syntax KItem ::= #makeBindings(Ids, Ints)
                 | state(continuation: K, store: Map)

  rule <k> #makeBindings(.Ids, .Ints) => .K ... </k>
  rule <k> #makeBindings((I:Id, IDS:Ids) => IDS, (IN:Int, INTS:Ints) => INTS) ... </k>
       <store> STORE => STORE [ I <- IN ] </store>
endmodule
