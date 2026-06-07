// =============================================================================
//  mini-python.k
//  "mini Python": a MINIMAL K semantics for exactly the fragment of Python used
//  by sum(n). Constructs covered (and nothing else): integer literals and names;
//  + ; <= ; assignment x=e ; augmented assignment x+=e (== x=x+e on ints);
//  while ; function def ; return ; function call.  NO `if` is introduced.
//
//  Adapted from K Tutorial Lesson 1.22, which verifies this very sum function;
//  we keep its proven <k>/<store>/<funcs>/<stack> configuration and call/return
//  machinery, and its Bot/Bots list construction.
//
//  INDENTATION NOTE (the one modeling decision):
//    K's parser is not whitespace-sensitive, so it cannot apply Python's
//    off-side rule directly. A real Python tokenizer emits INDENT/DEDENT tokens
//    bracketing a suite; we model a suite exactly as that token-bracketed block:
//    Suite ::= "INDENT" Stmt "DEDENT". Displayed Python indentation therefore
//    corresponds 1-1 to INDENT ... DEDENT here. This affects only lexing/layout,
//    never the semantics of any construct.
//  += CAVEAT: the desugaring x += e => x = x + e is value-faithful only because
//    targets here are side-effect-free simple names; general Python evaluates a
//    += target once and dispatches to __iadd__.
// =============================================================================

module MINI-PYTHON-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  // ---- expressions ----------------------------------------------------------
  syntax IExp ::= Id | Int
                | "(" IExp ")"            [bracket]
                > IExp "+" IExp           [seqstrict, left]   // arithmetic +
                | Id "(" IExps ")"        [strict(2)]         // function call

  syntax BExp ::= Bool
                | IExp "<=" IExp          [seqstrict]         // comparison <=

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
  // and the parser knows where a while/def body ends.
  syntax Stmt ::= Id "=" IExp                       [strict(2)]   // assignment
                | Id "+=" IExp                                     // augmented
                | "while" BExp ":" Suite                          // while
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

  rule <k> I1:Int <= I2:Int => I1 <=Int I2 ... </k>

  // ---- statement sequencing (newline) ---------------------------------------
  rule <k> S1:Stmt S2:Stmt => S1 ~> S2 ... </k>

  // ---- suite unwrapping -----------------------------------------------------
  rule <k> INDENT S:Stmt DEDENT => S ... </k>

  // ---- assignment & augmented assignment ------------------------------------
  rule <k> X:Id = I:Int => .K ... </k>
       <store> STORE => STORE [ X <- I ] </store>

  // Python augmented assignment on ints:  x += e   ==>   x = x + e
  rule <k> X:Id += E:IExp => X = X + E ... </k>

  // ---- while  (only the `while` construct; no `if` is introduced) -----------
  //   Evaluate a FRESH copy of the guard at the head of <k>, keeping an
  //   UNEVALUATED copy frozen inside #whileLoop so it can be re-checked each
  //   iteration. The head and the frozen copy are distinct subterms, so heating
  //   the head never rewrites the frozen copy. Re-entry is to `while`, not `if`.
  syntax KItem ::= #whileLoop(BExp, Suite)

  rule <k> while B:BExp : S:Suite => B ~> #whileLoop(B, S) ... </k>
  rule <k> true  ~> #whileLoop(B:BExp, S:Suite) => S ~> while B : S ... </k>
  rule <k> false ~> #whileLoop(_:BExp, _:Suite) => .K ... </k>

  // ---- function definition --------------------------------------------------
  rule <k> def FNAME:Id ( ARGS:Ids ) : BODY:Suite => .K ... </k>
       <funcs> FS => FS [ FNAME <- def FNAME ( ARGS ) : BODY ] </funcs>

  // ---- function call (args already evaluated to Ints by strict(2)) ----------
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
