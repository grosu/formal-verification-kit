// =============================================================================
//  mini-python.k
//  "mini Python (+ lists)": a MINIMAL K semantics for EXACTLY the fragment of
//  Python used by insertion_sort(a). Constructs covered (and nothing else):
//    - integer literals and names;
//    - len(e) ;
//    - index READ   e[e] ;
//    - index ASSIGN x[e] = e ;
//    - arithmetic + and - ;
//    - comparisons < , > , >= ;
//    - short-circuit `and` ;
//    - assignment x = e ;
//    - while ; function def ; return ; function call.
//  NO `if`, NO `*`/`/`, NO `or`/`not`, NO slices, NO exceptions, NO `list()`.
//
//  IN-PLACE VARIANT (from PROMPTS.md P1):
//    The prompt asks for in-place sorting. This version sorts the parameter list
//    `a` IN PLACE (nested while-loops + index assignment) and `return a`. There is
//    NO `list()` here. The behavioral consequence -- the input is MUTATED -- is
//    the central contract point reported in FINDINGS.md #4.
//
//  Adapted from the kit's reference example examples/sum-up/mini-python.k (itself
//  from K Tutorial Lesson 1.22): same
//  <k>/<store>/<funcs>/<stack> configuration, the same call/return machinery, and
//  the same Bot/Bots shared-klabel list trick -- here GENERALIZED from Int
//  arguments to arbitrary value (KResult) arguments, because insertion_sort is
//  called on a LIST value, not an Int.
//
//  ELEMENT-SORT MODELING DECISION (faithful restriction, see FINDINGS.md #1):
//    The source is generic over the element type; we model elements as Int, so
//    `<` / `>` / `>=` are K's total order on Int. This is the analogue of the
//    sum example restricting to Int. The genericity gap (and the real
//    total-order precondition it hides -- e.g. NaN / incomparable types) is
//    reported as a Finding, not modeled away silently.
//
//  LIST = VALUE SORT, and how IN-PLACE MUTATION is modeled here:
//    K's `List` is an immutable VALUE sort, not a heap reference. An index-assign
//    `a[i] = v` rebinds the program variable `a` to a NEW List value in <store>.
//    Python instead mutates a shared list OBJECT, so the caller's binding sees the
//    change (aliasing). We capture this faithfully WITHOUT a heap by NOT pushing a
//    fresh-store frame that hides the parameter: the mutated final `a` is `return`ed
//    and the caller binds the returned value to `out`, so `out` denotes the same
//    final sequence Python's mutated-in-place list would. The aliasing identity
//    `insertion_sort(x) is x` (the returned object IS the input object) is a
//    REFERENCE-level fact about Python objects that a value-sort model cannot
//    express; it is reported as FINDINGS.md #4, NOT modeled. The VALUE-level
//    contract (the returned/mutated sequence is a sorted permutation of the input
//    sequence) IS what (SORT) states and is faithful.
//
//  INDENTATION NOTE: as in the reference example, a suite is modeled as the
//    INDENT...DEDENT token-bracketed block a real Python tokenizer would emit;
//    K's parser is not whitespace-sensitive. Affects layout only, not semantics.
//
//  BUILTIN NAMES: list operations `size(L)`, element access `L[I]`, and update
//    `L [ I <- V ]` are from K's `LIST` module / domains.md. The MVP does not run
//    the toolchain (artifacts are "constructed, not machine-checked"); confirm the
//    exact builtin spellings against your K's domains.md at `kprove` time.
// =============================================================================

module MINI-PYTHON-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  // ---- expressions ----------------------------------------------------------
  // Values are Int, Bool, or List (declared as KResult below). Precedence runs
  // from tightest (indexing / len) to loosest (`and`), matching Python. NOTE: no
  // `list(e)` here -- the in-place version never copies.
  syntax Exp ::= Id | Int
               | "(" Exp ")"            [bracket]
               | "len"  "(" Exp ")"     [strict]            // len(e)
               | Exp "[" Exp "]"        [seqstrict]         // index read  e[e]
               > Exp "-" Exp            [seqstrict, left]   // arithmetic
               | Exp "+" Exp            [seqstrict, left]
               > Exp "<"  Exp           [seqstrict, non-assoc]   // comparisons
               | Exp ">"  Exp           [seqstrict, non-assoc]
               | Exp ">=" Exp           [seqstrict, non-assoc]
               > Exp "and" Exp          [strict(1)]         // SHORT-CIRCUIT: left only
               | Id "(" Exps ")"        [strict(2)]         // function call (expr)

  // Argument / parameter lists. Shared klabel(exps) Bot/Bots construction (as in
  // the reference example) makes Vals (evaluated args, a KResult) and Ids
  // (parameters) BOTH subsorts of the strict Exps list, so the seqstrict arg list
  // cools to a Vals KResult and `.Bots` is the single shared empty terminator.
  // GENERALIZATION vs the sum example: evaluated args are Vals = List{KResult},
  // not List{Int}, so a LIST value is a legal argument.
  syntax Bot
  syntax Bots ::= List{Bot,     ","}    [klabel(exps)]
  syntax Vals ::= List{KResult, ","}    [klabel(exps)] | Bots   // evaluated args
  syntax Ids  ::= List{Id,      ","}    [klabel(exps)] | Bots   // parameters
  syntax Exps ::= List{Exp,     ","}    [klabel(exps), seqstrict] | Vals | Ids

  syntax KResult ::= Int | Bool | List | Vals

  // ---- statements -----------------------------------------------------------
  // Suite-headed/leaf statements bind TIGHTER than sequencing (the `>` block), and
  // a Suite is itself a Stmt, so INDENT...DEDENT is self-delimiting and the parser
  // knows where a while/def body ends.
  syntax Stmt ::= Id "=" Exp                       [strict(2)]    // x = e
                | Id "[" Exp "]" "=" Exp           [strict(2,3)]  // x[i] = e
                | "while" Exp ":" Suite                           // while
                | "def" Id "(" Ids ")" ":" Suite                  // function def
                | "return" Exp                     [strict]       // return
                | Id "(" Exps ")"                  [strict(2)]     // call stmt
                | Suite
                > Stmt Stmt                          [left]        // sequencing

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
    <store> .Map  </store>     // program variables  Id |-> Value (Int or List)
    <funcs> .Map  </funcs>     // function table      Id |-> (def ...)
    <stack> .List </stack>     // call stack of saved (continuation, store)

  // ---- expressions ----------------------------------------------------------
  rule <k> X:Id => V ... </k>
       <store> ... X |-> V ... </store>

  rule <k> len(L:List) => size(L) ... </k>

  // NOTE: no `list()` rule -- the in-place version never copies (see header).

  // index read: in-bounds element access (out-of-bounds is intentionally stuck =
  // Python IndexError; the loop invariants guarantee indices stay in range).
  rule <k> L:List [ I:Int ] => L [ I ] ... </k>
    requires 0 <=Int I andBool I <Int size(L)

  rule <k> I1:Int + I2:Int => I1 +Int I2 ... </k>
  rule <k> I1:Int - I2:Int => I1 -Int I2 ... </k>

  rule <k> I1:Int <  I2:Int => I1  <Int I2 ... </k>
  rule <k> I1:Int >  I2:Int => I1  >Int I2 ... </k>
  rule <k> I1:Int >= I2:Int => I1 >=Int I2 ... </k>

  // short-circuit `and`: evaluate left (strict(1)); only then look at the right.
  // Faithful here because both operands are comparisons (Bool). Returns the right
  // operand unevaluated, to be evaluated next at the head of <k>.
  rule <k> true  and B:Exp => B     ... </k>
  rule <k> false and _:Exp => false ... </k>

  // ---- statement sequencing & suite unwrapping ------------------------------
  rule <k> S1:Stmt S2:Stmt => S1 ~> S2 ... </k>
  rule <k> INDENT S:Stmt DEDENT => S ... </k>

  // ---- assignment -----------------------------------------------------------
  rule <k> X:Id = V:KResult => .K ... </k>
       <store> STORE => STORE [ X <- V ] </store>

  // index assignment  x[i] = v  (target x is a name bound to a List value).
  // THIS is the in-place mutation: it rebinds `x` to the updated List value in
  // <store>. (In Python the same statement mutates the shared list object; the
  // value-sort model reflects the resulting SEQUENCE faithfully -- see header.)
  rule <k> X:Id [ I:Int ] = V:KResult => .K ... </k>
       <store> ... X |-> (L:List => L [ I <- V ]) ... </store>
    requires 0 <=Int I andBool I <Int size(L)

  // ---- while  (fresh guard copy at the head; frozen copy survives in #whileLoop)
  syntax KItem ::= #whileLoop(Exp, Suite)

  rule <k> while B:Exp : S:Suite => B ~> #whileLoop(B, S) ... </k>
  rule <k> true  ~> #whileLoop(B:Exp, S:Suite) => S ~> while B : S ... </k>
  rule <k> false ~> #whileLoop(_:Exp, _:Suite) => .K ... </k>

  // ---- function definition --------------------------------------------------
  rule <k> def FNAME:Id ( ARGS:Ids ) : BODY:Suite => .K ... </k>
       <funcs> FS => FS [ FNAME <- def FNAME ( ARGS ) : BODY ] </funcs>

  // ---- function call (args already evaluated to Vals by strict(2)) ----------
  rule <k> FNAME:Id ( VS:Vals ) ~> CONT => #makeBindings(ARGS, VS) ~> BODY </k>
       <funcs> ... FNAME |-> def FNAME ( ARGS:Ids ) : BODY:Suite ... </funcs>
       <store> STORE => .Map </store>
       <stack> .List => ListItem(state(CONT, STORE)) ... </stack>

  // ---- return ---------------------------------------------------------------
  rule <k> return V:KResult ~> _ => V ~> CONT </k>
       <stack> ListItem(state(CONT, STORE)) => .List ... </stack>
       <store> _ => STORE </store>

  rule <k> return V:KResult ~> .K => V </k>
       <stack> .List </stack>

  // ---- parameter binding ----------------------------------------------------
  syntax KItem ::= #makeBindings(Ids, Vals)
                 | state(continuation: K, store: Map)

  rule <k> #makeBindings(.Ids, .Vals) => .K ... </k>
  rule <k> #makeBindings((X:Id, IDS:Ids) => IDS, (V:KResult, VS:Vals) => VS) ... </k>
       <store> STORE => STORE [ X <- V ] </store>
endmodule
