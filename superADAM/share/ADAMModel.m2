
--TODO today: (9/9/14)
-- DONE --  1. add parameter values to limitCycles code
--  2. allow specialization of a model with parameters?
--DONE --  3. make sure "variables", "parameters" are lists, in the right order.
--  4. work on checkModel: it should handle more things, including parameters.  And checking updateRules...
--  5. polynomials: should call "addPolynomials" if needed?  NO...?
--  6. speed up JSON input for the two large files?
--  7. for going from TT to polys, do we need to add in ki^p-ki = 0?  Probably...


newPackage(
    "ADAMModel",
    Version => "0.1", 
    Date => "",
    Authors => {{Name => "Franziska Hinkelmann", 
            Email => "", 
            HomePage => ""},
        {Name => "Mike Stillman", 
            Email => "", 
            HomePage => ""}
        },
    Headline => "ADAM Model management",
    PackageExports => {"solvebyGB", "JSON", "LogicalFormulas"},
    DebuggingMode => true
    )

export {
    "Model", 
    "model",
    "modelFromJSONHashTable",
    "checkModel",
    "parseModel", 
    "polynomials", 
    "findLimitCycles", 
    "polyFromTransitionTable",
    "transformModel",
    "toMutable",
    "toImmutableModel"
    }

Model = new Type of HashTable

model = method(Options => {
        "description" => "", 
        "version" => "0.0",
        "variables" => null,
        "parameters" => {},
        "updateRules" => null,
        "simlab" => null
        })
model String := opts -> (name) -> (
    parts := {{"name", name},
        {"description", opts#"description"},
        {"version", opts#"version"},
        {"variables", opts#"variables"},
        {"parameters", opts#"parameters"},
        {"updateRules", opts#"updateRules"},
        {"simlab", opts#"simlab"},
        symbol cache => new CacheTable
        };
    parts = select(parts, x -> x#1 =!= null);
    model := new Model from parts;
    checkModel model;
    model.cache.ring = ring model;
    model
    )
parameters = method()
parameters Model := (M) -> (
    -- returns a list of strings
    M#"parameters"/(x -> x#"id")//toList
    )
vars Model := (M) -> (
    -- returns a list of strings
    M#"variables"/(x -> x#"id")//toList
    )
char Model := (M) -> (
     p := M#"variables"/(x -> #x#"states")//max;
     while not isPrime p do p = p+1;
     p
    )
ring Model := (M) -> (
    if not M.cache.?ring then M.cache.ring = (
        paramnames := parameters M;
        varnames := vars M;
        p := char M;
        kk := if #paramnames == 0 then ZZ/p else ZZ/p[paramnames];
        R1 := kk[varnames];
        I1 := ideal for x in gens R1 list x^p-x;
        R1/I1);
    M.cache.ring
    )

-- The following is used for testing purposes
ErrorPacket == Model := (M,N) -> false
Model == ErrorPacket := (M,N) -> false
ErrorPacket == ErrorPacket := (M,N) -> checkEqual(M,N)
Model == Model := (M,N) -> checkEqual(M,N)

-- whereNotEqual: gives error, with first place where they differ
whereNotEqual = method()
whereNotEqual(String,String) := (s,t) -> 
    if s != t then error("strings: "|s|" and "|t|" differ")
whereNotEqual(List,List) := (L1,L2) -> (
    if #L1 != #L2 then error("lists: "|toString L1|" and "|toString L2| " differ in length");
    for i from 0 to #L1 - 1 do (
        whereNotEqual(L1#i, L2#i);
        );
    )
whereNotEqual(HashTable,HashTable) := (H1,H2) -> (
    k1 := sort delete(symbol cache, keys H1);
    k2 := sort delete(symbol cache, keys H2);
    if k1 =!= k2 then error("keys: "|toString k1|" and "|toString k2| " differ");
    for k in k1 do (
        whereNotEqual(H1#k, H2#k);
        );
    )
whereNotEqual(Thing,Thing) := (a,b) -> if a =!= b then error("differ: \n  "|toString a|"\n  "|toString b);
    
checkEqual = method()
checkEqual(String,String) := (s,t) -> s == t
checkEqual(List,List) := (L1,L2) -> (
    if #L1 != #L2 then return false;
    for i from 0 to #L1 - 1 do (
        if not checkEqual(L1#i, L2#i) then return false;
        );
    true
    )
checkEqual(HashTable,HashTable) := (H1,H2) -> (
    k1 := sort delete(symbol cache, keys H1);
    k2 := sort delete(symbol cache, keys H2);
    if k1 =!= k2 then return false;
    for k in k1 do (
        if not checkEqual(H1#k, H2#k) then return false;
        );
    true
    )
checkEqual(Thing,Thing) := (a,b) -> a === b

    

checkModel = method()
checkModel Model := (M) -> (
    result := M#?"variables";
    if not result then return false;
    vars := M#"variables";
    for f in vars do (
        if not f#?"id" or not instance(f#"id", String) then return false;
        if not f#?"states" or not instance(f#"states", List) then return false;
        );
    if not M#?"updateRules" then return false;
    -- also to check:
    ---- updateRules has one key for each variable.
    ---- that updateRule#xi should be a hash table, with "possibleInputVariables" as key
    ----   which should be a list of some id's of the variables
    ----   and should have either: polynomialFunction, transitionTable, or ...
    result
    )

modelFromJSONHashTable = method()
modelFromJSONHashTable HashTable := (M) -> (
    if instance(M, ErrorPacket) then return M;
    if not M#?"model" then return errorPacket "internal error: input is not a Model ot ErrorPacket";
    mod := M#"model";
    model(mod#"name", 
        "description" => mod#"description",
        "version" => mod#"version",
        "variables" => mod#"variables",
        "parameters" => if mod#?"parameters" then mod#"parameters" else {},
        "updateRules" => mod#"updateRules",
        "simlab" => if mod#?"simlab" then mod#"simlab" else null
        )
    )

-- parseModel: takes a string (usually the contents of a file), and returns
-- a "Model", if everything works, or an ErrorPacket
parseModel = method()
parseModel String := (str) -> (
    M := parseJSON str;
    modelFromJSONHashTable M
    )

toJSON Model := (M) -> toJSON new HashTable from {("model", new HashTable from M)}

prettyPrintJSON Model := (M) -> (
    prettyPrintJSON new HashTable from {"model" => M}
    )

polynomials = method()
polynomials(Model,Ring) := (M, R) -> (
    -- first: make sure that polynomial functions are present
    -- then: returns a list of list of polynomials
    for x in M#"updateRules" list (
        for f in x#"functions" list (
            if not f#?"polynomialFunction"
            then error "internal error: polynomial not found"
            else (
                g := value f#"polynomialFunction";
                if ring g =!= R then promote(g,R) else g
            )
        )
    )
polynomials(Model) := (M) -> (
    R := ring M;
    varnames := vars M;
    use R;
    matrix(R, {for x in varnames list value M#"updateRules"#x#"polynomialFunction"})
    )
polynomials(Model,List) := (M,parameterValues) -> (
    R := ring M;
    varnames := vars M;
    use R;
    m := matrix(R, {for x in varnames list value M#"updateRules"#x#"polynomialFunction"});
    kk := coefficientRing R;
    base := ring ideal kk;
    if base =!= ZZ then (
        p := char kk;
        R1' := (coefficientRing kk)(monoid R);
        I1' := ideal for x in gens R1' list x^p-x;
        R1 := R1'/I1';
        phi := map(R1, R, (generators R1) | parameterValues);
        m = phi m;
        );
    m
    )

toArray = method()
toArray List := (L) -> new Array from (L/toArray)
toArray Thing := (L) -> L

findLimitCycles = method()
findLimitCycles(Model, List, ZZ) := (M, parameterValues, limitCycleLength) -> 
    findLimitCycles(M, parameterValues, {limitCycleLength})
findLimitCycles(Model, List, List) := (M, parameterValues, limitCycleLengths) -> (
    PDS := polynomials(M, parameterValues);
    H := for len in limitCycleLengths list (
        limitcycles := gbSolver(PDS, len);
        len => toArray limitcycles
        );
    hashTable H
    )

polyFromTransitionTable = method()
polyFromTransitionTable(List, List, Ring) := (inputvars, transitions, R) -> (
    << "starting interpolation: " << #inputvars << endl;
    p := char R;
    n := #inputvars;
    X := set (0..p-1);
    inputs := sort toList X^**n;
    time result := sum for t in transitions list (
        input := t#0; -- a list
        output := t#1; -- a value
        if output == 0 then continue else
        output * product for i from 0 to n-1 list (
            x := R_(inputvars#i);
            1 - (x-input#i)^(p-1)
        ));
    if result == 0 then 0_R else result -- this is just being careful...
    )

transformer = new MutableHashTable;
--transformer#("add","bool") = notImplemented

transformer#("add","poly") = (updatexi, M) -> (
    R := ring M;
    if updatexi#?"polynomialFunction" then (
        updatexi#"polynomialFunction" = toString value updatexi#"polynomialFunction";
        ) 
    else if updatexi#?"transitionTable" then (
        possibles := updatexi#"possibleInputVariables";
        tt := updatexi#"transitionTable";
        updatexi#"polynomialFunction" = 
            toString polyFromTransitionTable(possibles, tt, R);
        )
    else if updatexi#?"booleanFunction" then (
        P := makeLFParser R;
        F := P updatexi#"booleanFunction";
        updatexi#"polynomialFunction" = toString F;
        )
    )

transformer#("add","tt") = (updatexi, M) -> (
    R := ring M;
    if updatexi#?"transitionTable" then return;
    if updatexi#?"booleanFunction" then (
        possibles := updatexi#"possibleInputVariables";
        Q := makeBoolParser R;
        formula := Q updatexi#"booleanFunction";
        updatexi#"transitionTable" = 
            transitionTable(possibles, formula);
        )
    else if updatexi#?"polynomialFunction" then (
        possibles = updatexi#"possibleInputVariables";
        F := value updatexi#"polynomialFunction";
        updatexi#"transitionTable" = 
            transitionTable(possibles/value, F);
        )
    )

transformer#("remove","poly") = (updatexi,M) -> remove(updatexi,"polynomialFunction")
transformer#("remove","tt") = (updatexi,M) -> remove(updatexi,"transitionTable")
transformer#("remove","bool") = (updatexi,M) -> remove(updatexi,"booleanFunction")

transformModel = method()
transformModel(String, String, ErrorPacket) := (add, type, M) -> M
transformModel(String, String, Model) := (add, type, M) -> (
    if not transformer#?(add,type) then (
        packet := "error: cannot " | add | " transition functions of type: "|type;
        return errorPacket packet
        );
    f := transformer#(add,type);
    M1 := toMutable M;
    -- At this point, we loop through and run the function
    update := M1#"updateRules";
    for k in keys update do f(update#k, M);
    -- Finally, we return the new model
    toImmutableModel M1
    )

toMutable = method()
toMutable HashTable := (H) -> new MutableHashTable from (
    for k in keys H list k => toMutable H#k
    )
toMutable BasicList := (L) -> apply(L, toMutable)
toMutable CacheTable := (F) -> F
toMutable RingElement := (F) -> F
toMutable Ring := (F) -> F
toMutable String := (F) -> F
toMutable Thing := (x) -> x

toImmutable = method()
toImmutable HashTable := (H) -> new HashTable from (
    for k in keys H list k => toImmutable H#k
    )
toImmutable BasicList := (L) -> apply(L, toImmutable)
toImmutable CacheTable := (F) -> F
toImmutable RingElement := (F) -> F
toImmutable Ring := (F) -> F
toImmutable String := (F) -> F
toImmutable Thing := (x) -> x

toImmutableModel = method()
toImmutableModel HashTable := (H) -> new Model from toImmutable H

TEST ///
{*
  restart
*}
  needsPackage "ADAMModel"
  needsPackage "JSON"

  str = exampleJSON#0

  M = parseModel str
  result = findLimitCycles(M,{},{1,2,3})
  ans = new HashTable from {1 => [[[0,1,1]]], 2 => [], 3 => []}
  assert(result === ans)
///

   sample2 = ///{
"model": {
  "description": "",
  "name": "Sample2 for testing",
  "version": "1.0",
  "parameters": [],
  "variables": [
      {
      "id": "x1",
      "name": "variable1",
      "states": ["0","1"]
      },
      {
      "id": "x2",
      "name": "variable2",
      "states": ["0","1"]
      },
      {
      "id": "x3",
      "name": "variable3",
      "states": ["0","1"]
      },
      {
      "id": "x4",
      "name": "variable4",
      "states": ["0","1"]
      },
      {
      "id": "x5",
      "name": "variable5",
      "states": ["0","1"]
      }
    ],
  "updateRules": [
      {
      "functions": [
          {
          "inputVariables": ["x2","x3","x1"],
          "transitionTable": [
              [[0,0,0],1],
              [[0,0,1],0],
              [[0,1,0],0],
              [[0,1,1],0],
              [[1,0,0],1],
              [[1,0,1],1],
              [[1,1,0],0],
              [[1,1,1],0]           
            ],
           "polynomialFunction": "x1+x2+x3"
          }
        ],
      "target": "x1"
      },
      {
      "functions": [
          {
          "inputVariables": ["x1","x2"],
          "polynomialFunction": "x1+1"
          }
        ],
      "target": "x2"
      },
      {
      "functions": [
          {
          "inputVariables": ["x1","x2"],
          "polynomialFunction": "x1+x2"
          }
        ],
      "target": "x3"
      },
      {
      "functions": [
          {
          "inputVariables": ["x1","x4"],
          "polynomialFunction": "x1+x4"
          }
        ],
      "target": "x4"
      },
      {
      "functions": [
          {
          "inputVariables": ["x2","x5"],
          "polynomialFunction": "x2+x2*x5+x5"
          }
        ],
      "target": "x5"
      }
    ]
  }
}
///
   
TEST ///
{*
  restart
*}
  debug needsPackage "ADAMModel"
  M = parseModel sample2

  ring M
  vars M
  polynomials(M, ring M)


  M1 = transformModel("add", "poly", M)
  M2 = transformModel("add", "poly", M1)
  assert(M1 == M2)
  M3 = transformModel("remove", "tt", M2)
  M4 = transformModel("add", "tt", M3)

  N1 = transformModel("remove", "poly", M4)  
  N2 = transformModel("remove", "tt", M4)  
  N3 = transformModel("add", "poly", N1)
  N4 = transformModel("add", "tt", N2)
  assert(N3 == N4)
  assert(M3 != M2)
///

///
{*
  restart
*}

  debug needsPackage "ADAMModel"
  str = get "../../exampleJSON/SecondVersion1-Model.json"
  M = parseModel str
  prettyPrintJSON M
  M1 = transformModel("add","poly",M)
  prettyPrintJSON M1

  findLimitCycles(M1,{},{1,2,3})
  toJSON M1
  polynomials M1
  R = ring M
  R === ring M

///

TEST ///
  -- Test transformModel
{*
  restart
*}
  needsPackage "ADAMModel"
  needsPackage "JSON"

  str = exampleJSON#0
  M = parseModel str
  mM = toMutable M
  peek mM
  M1 = toImmutableModel mM
  mM#"updateRules"#"x1"#"polynomialFunction" = "x1+x2"
  M2 = toImmutableModel mM
  assert(M == M1)
  assert(M != M2)
  assert(M1 != M2)

  M1 = transformModel("add","poly",M)
  assert(M == M1);
  
///

TEST ///
{*
restart
*}
    debug needsPackage "ADAMModel"
    str = get (currentDirectory()|"../../exampleJSON/BooleanModels/Keratinocyte.json");
    M = parseModel str
    -- these have boolean and polys
    -- test: bool --> poly
    M1 = transformModel("remove","poly",M)
    M2 = transformModel("add","poly",M1)
    whereNotEqual(M,M2)
    assert(M == M2)

    -- test bool --> transition table
    --  matches poly --> transition table
    T1 = transformModel("add","tt",M1);
    T2 = transformModel("remove","bool",T1)

    T3 = transformModel("remove","bool",M2)
    T4 = transformModel("add","tt",T3)    
    T5 = transformModel("remove","poly",T4)

    assert(T2 == T5)

    -- test bool --> poly, and transition --> poly have same value
    -- This test is messed up MES
    S1 = transformModel("add","poly",M1) -- bool --> poly
    S2 = transformModel("remove","bool",S1) -- just tt from bool
    S3 = transformModel("add","tt",S2)
    
///
end

beginDocumentation()

doc ///
Key
  Model
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
