-- to add to this:
--   1. correctness check: a version which creates an expression with NOT, OR, AND, and then evaluates it
--      at all points
--   2. Parser for polynomials along the same lines
--   3. If possible, the parser should not give an M2 error
--   4. Char > 2 expressions should be do-able in this manner too, once we know what we want
--
-- Create a new model from a file, with one line per function
-- 
newPackage(
        "LogicalFormulas",
        Version => "0.1", 
        Date => "",
        Authors => {{Name => "", 
                  Email => "", 
                  HomePage => ""}},
        Headline => "translation of logical formulas to polynomials",
        DebuggingMode => false
        )

needsPackage "Parsing"
debug Core

export {idenParser,
    makeLFParser,
    makeBoolParser,
    makeEnvironment,
    "Not",
    "Or",
    "And"
    }

-- Some code which perhaps should be in Parser.m2
alphanum = set characters "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
alphanumParser = Parser (c -> if alphanum#?c then new Parser from (b -> if b === null then c))

digits = set characters "0123456789"    
digitParser = Parser (c -> if digits#?c then new Parser from (b -> if b === null then c))

idenParser = (env) -> (
    a -> (
        v := concatenate a; 
        if env#?v then env#v else ("parse error: unknown variable '"|v|"'")
        )
    ) % letterParser @ (+alphanumParser)
binOp = (op, parser, fcn) -> fcn % parser @ +(last % op @ parser)
unOp = (op, parser, fcn) -> fcn % op @ parser

-- Code specific to our situation
makeEnvironment = method()
makeEnvironment Ring := (R) -> (
    V := gens(R, CoefficientRing => ZZ);
    hashTable for v in V list (toString v) => v
    )

fcnNot = a -> if class a#1 === String then a#1 else 1-a#1
fcnOr = a -> (
    a1 := deepSplice a; 
    if any(a, x -> instance(x,String)) then (
        strs := select(1, a1, x -> instance(x,String));
        strs#0
        )
    else 1 - times apply(a1, x -> 1-x)
    )
fcnAnd = a -> (
    a1 := deepSplice a; 
    if any(a, x -> instance(x,String)) then (
        strs := select(1, a1, x -> instance(x,String));
        strs#0
        )
    else times a1
    )

makeLFParser = method()
makeLFParser Ring := (R) -> (
    env := makeEnvironment R; -- all variables of R, and of coefficient rings of R
    idenP := idenParser env;
    exprP1:= null;
    exprP := futureParser symbol exprP1;
    parenP := (a -> a#1#0) % ("(" @ exprP @ ")");
    expr2 := ((a -> a_R) % NNParser) 
      | idenP 
      | parenP 
      | unOp("!", idenP, fcnNot) 
      | unOp("!", parenP, fcnNot);
    exprP1 = expr2 | binOp("|", expr2, fcnOr) | binOp("&", expr2, fcnAnd);
    exprP1 : nonspaceAnalyzer
    )

boolNot = a -> if class a#1 === String then a#1 else {Not, a#1}
boolOr = a -> (
    a1 := deepSplice a; 
    if any(a, x -> instance(x,String)) then (
        strs := select(1, a1, x -> instance(x,String));
        strs#0
        )
    else prepend(Or, toList a1)
    )
boolAnd = a -> (
    a1 := deepSplice a; 
    if any(a, x -> instance(x,String)) then (
        strs := select(1, a1, x -> instance(x,String));
        strs#0
        )
    else prepend(And, toList a1)
    )

makeBoolParser = method()
makeBoolParser Ring := (R) -> (
    env := makeEnvironment R; -- all variables of R, and of coefficient rings of R
    idenP := idenParser env;
    exprP1:= null;
    exprP := futureParser symbol exprP1;
    parenP := (a -> a#1#0) % ("(" @ exprP @ ")");
    expr2 := ((a -> a_R) % NNParser) 
      | idenP 
      | parenP 
      | unOp("!", idenP, boolNot) 
      | unOp("!", parenP, boolNot);
    exprP1 = expr2 | binOp("|", expr2, boolOr) | binOp("&", expr2, boolAnd);
    exprP1 : nonspaceAnalyzer
    )

end

restart

TEST ///
{*
  restart
*}

  needsPackage "LogicalFormulas"

  makeBooleanRing = (n) -> (
      A := ZZ/2[for i from 1 to n list ("x"|toString i)];
      I := for x in gens A list x^2+x;
      B := A/I;
      B
      );
  R = makeBooleanRing 104
  A = ZZ/2[x1,x2,x3,x4]
  R = A/(ideal for x in gens A list x^2+x)
  env = makeEnvironment R
  P = makeLFParser R
  Q = makeBoolParser R
  P "1"
  P "x3|1"
  P "x3|0"
  P "x3"
  P "x3&1"
  P "x3&0"
  P "x1"
  P "! x1"
  P "!x5"
  P "(!x3)"
  P "(x4)"
  P "!(x2)"
  P "!(!x2)"
  P "(x1|(x2|x1)|!x3)"
  P "(x1|(x2&!x1)|!x3)"
  P "(x1&x2&x3&!x4)"
  P "x1|x1"

  Q "x1"  
  Q "!x1"
  Q "x1|x2|x3"

///

TEST ///
  str = "(x79 & x84 & x97 &  !(x75 & x92)) | (x80 & x84 & x97 &  !(x75 & x92)) | (x96 & x84 & x97 &  !(x75 & x92)) | (x102 & x84 & x97 &  !(x75 & x92)) | (x87 & x84 & x97 &  !(x75 & x92)) | (x89 & x69 & x97 &  !(x75 & x92)) | (x90 & x84 & x97 &  !(x75 & x92)) | (x93 & x84 & x97 &  !(x75 & x92))"
  str = "(" | str | ")#"
  
  A = ZZ/2[x1,x2,x3,x4]
  R = A/(ideal for x in gens A list x^2+x)
  env = new HashTable from for x in gens R list (toString x) => x
  assert(readExpr(0,"x3 | (!x4)",env) == (2, x3))
  assert(readExpr(7,"x3 | (!x4)",env) == (9, x4))
  assert(readExpr(0, "xy3 | (!x4)",env) === (0, null))
  readExpr(0, "!x3", env)
///
beginDocumentation()

end

doc ///
Key
  LogicalFormulas
Headline
Description
  Text
  Example
Caveat
SeeAlso
///

doc ///
Key
Headline
Usage
Inputs
Outputs
Consequences
Description
  Text
  Example
  Code
  Pre
Caveat
SeeAlso
///

TEST ///
-- test code and assertions here
-- may have as many TEST sections as needed
///


