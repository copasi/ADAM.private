
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
    "polynomials", 
    "findLimitCycles", 
    "parseModel", 
    "checkModel",
    "addPolynomials",
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
        "updateRules" => null
        })
model String := opts -> (name) -> (
    model := new Model from {
        {"name", name},
        {"description", opts#"description"},
        {"version", opts#"version"},
        {"variables", opts#"variables"},
        {"parameters", opts#"parameters"},
        {"updateRules", opts#"updateRules"},
        symbol cache => new CacheTable
        };
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
    if keys H1 =!= keys H2 then return false;
    for k in keys H1 do (
        if k === cache then continue;
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

-- parseModel: takes a string (usually the contents of a file), and returns
-- a "Model", if everything works, or an ErrorPacket
parseModel = method()
parseModel String := (str) -> (
    M := parseJSON str;
    if instance(M, ErrorPacket) then return M;
    if not M#?"model" then return errorPacket "internal error: input is not a Model ot ErrorPacket";
    mod := M#"model";
    model(mod#"name", 
        "description" => mod#"description",
        "version" => mod#"version",
        "variables" => mod#"variables",
        "parameters" => if mod#?"parameters" then mod#"parameters" else {},
        "updateRules" => mod#"updateRules"
        )
    )


toJSON Model := (M) -> toJSON new HashTable from {("model", new HashTable from M)}

prettyPrintJSON Model := (M) -> (
    prettyPrintJSON new HashTable from {"model" => M}
    )

polynomials = method()
polynomials(Model,Ring) := (M, R) -> (
    varnames := vars M;
    for x in varnames list value M#"updateRules"#x#"polynomialFunction"
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
--transformer#(true,"bool") = notImplemented

transformer#(true,"poly") = (updatexi, M) -> (
    R := ring M;
    if updatexi#?"polynomialFunction" then (
        updatexi#"polynomialFunction" = toString value updatexi#"polynomialFunction";
    ) else if updatexi#?"transitionTable" then (
        possibles := updatexi#"possibleInputVariables";
        tt := updatexi#"transitionTable";
        updatexi#"polynomialFunction" = 
            toString polyFromTransitionTable(possibles, tt, R);
    ))
--    else if updatexi#"booleanFunction" then (
--        F := polyFromBooleanFunction(updatexi#"booleanFunction");
--        updatexi#"polynomialFunction" = polyFromTransitionTable(...,F,R);
--      )

transformer#(true,"tt") = (updatexi, M) -> (
    R := ring M;
    if updatexi#?"transitionTable" then return;
    if updatexi#?"polynomialFunction" then (
        possibles := updatexi#"possibleInputVariables";
        F := value updatexi#"polynomialFunction";
        updatexi#"transitionTable" = 
            transitionTable(possibles/value, F)
        )
    )

transformer#(false,"poly") = (updatexi,M) -> remove(updatexi,"polynomialFunction")
transformer#(false,"tt") = (updatexi,M) -> remove(updatexi,"transitionTable")
transformer#(false,"bool") = (updatexi,M) -> remove(updatexi,"booleanFunction")

transformModel = method()
transformModel(Boolean, String, ErrorPacket) := (add, type, M) -> M
transformModel(Boolean, String, Model) := (add, type, M) -> (
    if not transformer#?(add,type) then (
        addstr := if add then "add" else "remove";
        packet := "error: cannot " | addstr | " transition functions of type: "|type;
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

-----------------------------------------------------------------------

removeFromModel = method()
removeFromModel(String, Model) := (keyname, M) -> (
    M1 := toMutable M;
    update := M1#"updateRules";
    for k in keys update do (k, remove(update#k, keyname));
    toImmutableModel M1
    )

changeUpdate = method()
changeUpdate(Model, HashTable) := (M, newUpdateRules) -> (
    Mnew := model(M#"name", 
        "description" => M#"description",
        "version" => M#"version",
        "variables" => M#"variables",
        "updateRules" => newUpdateRules);
    Mnew.cache.ring = ring M;
    Mnew
    )

attachToUpdate = method()
attachToUpdate(Model, Function) := (M, fcn) -> (
    -- M is a model
    -- fcn is a function which takes (M, xi, hashtable), and returns something of the form
    --  "newFieldName" => String
    -- for example: fcn might return "polynomialFunction" => "x2+x3*x4".
    -- Action: a model M is returned, which for each variable, has its update table info modified by
    --   adding in this field and value.
    newUpdateRules := hashTable for xi in vars M list (
        H := M#"updateRules"#xi;
        newpair := fcn(M, xi, H);
        if newpair === null then xi => H
        else xi => hashTable append(pairs H, newpair)
        );
    changeUpdate(M, newUpdateRules)
    )


addPolynomials = method()
addPolynomials ErrorPacket := (M) -> M
addPolynomials Model := (M) -> (
    fcn := (M,xi,H) -> (
        if H#?"polynomialFunction" then return null; -- already exists
        g := polyFromTransitionTable(  
            H#"possibleInputVariables",
            H#"transitionTable",
            ring M);
        "polynomialFunction" => toString g
        );
    attachToUpdate(M, fcn)
    )

makeTT = method()
makeTT(RingElement, List) := (F, varAndInputs) -> (
    -- NOT WRITTEN YET!!
    -- F is a polynomial in a poly ring with some large number of vars, possibly.
    -- varAndInputs has the form:
    -- {{x3, {0,1}}, {x7, {0,1,2}}, {x4, {1,3,4}}}
    -- transition tables are created from this info.
    vars := varAndInputs/first; -- these are each strings of form "xi"
    varAndInputs/last/set
    )
transitionTableFromPolynomial = method()
transitionTableFromPolynomial(Model, String) := (M, var) -> (
    Fs := polynomials M;
    inputvars := M#"updateRules"#var#"possibleInputVariables";
    inputnums := M#"variables"#var#"possibleInputVariables";
    F := M#"updateRules"#var#"polynomialFunction";
    
    -- Now make a list of all input values
    )
{*
removePolynomials = method()
removePolynomials ErrorPacket := (M) -> M
removePolynomials Model := (M) -> (
    rules := M#"updateRules";
    newrules := hashTable for r in keys rules list (
        H := new MutableHashTable from rules#r;
        remove(H, "polynomialFunction");
        r => new HashTable from H
        );
    changeUpdate(M, newrules)
    )
removeUpdate = method()
removeUpdate(ErrorPacket, String) := (M, updateType) -> M
removeUpdate(Model, String) := (M,str) -> (
    if str =!= "polynomialFunction" and str =!= "transitionTable" and str =!= "logicalFormulas"
    then return errorPacket ("internal error: unknown update type: "|str);
    rules := M#"updateRules";
    newrules := hashTable for r in keys rules list (
        H := new MutableHashTable from rules#r;
        remove(H, str);
        r => new HashTable from H
        );
    changeUpdate(M, newrules)
    )
*}


addPolys = method()
addPolys Model := (M) -> (
    -- for each update rule:
    --   if there is a polynomialFunction, use it
    --   else if there is a transition table, use that to compute poly.
    --   else if there is a boolean function, use that to compute poly.
    -- MES
    )

addTT = method()
addTT Model := (M) -> (
    -- for each update rule:
    --   if there is a transition table, use that.
    --   otherwise, if there is a poly, use that
    --   else if there is a bool fcn: make a poly, use that.
    -- MES
    )

{*
--L = {"x3", "x1"}
--p = 2
--vals = {0,1,0,1}
interpolate = method()
interpolate (List, ZZ, List) := (L, p, vals) -> (
  params := select( vals, l -> ( class value toString l ) === Symbol );
  R := ZZ/p[params / value][L / value ];
  --R := ZZ/p[L];
  n := #L;
  QR := R / ideal apply( gens R, x -> x^p-x) ;
  vals = apply(vals, l -> value toString l );
  X := set (0..p-1);
  inputs := sort toList X^**n;
  --print toString L;
  --print toString vals;
  --print toString inputs;

  pol := sum ( inputs, vals, (source, t) -> t* product( source, gens QR, (i, xi) -> 1 - (xi-i)^(p-1) ) );
  print toString pol
)
*}

addPolynomials Model := (M) -> (
    fcn := (M,xi,H) -> (
        if H#?"polynomialFunction" then return null; -- already exists
        g := polyFromTransitionTable(  
            H#"possibleInputVariables",
            H#"transitionTable",
            ring M);
        "polynomialFunction" => toString g
        );
    attachToUpdate(M, fcn)
    )


-------------------------------------------------------------------------    

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

   sample2 = ///{"model": {
         "name": "Sample2 for testing",
         "description": "",
         "version": "1.0",
         "variables": [
             {
                 "name": "variable1",
                 "id": "x1",
                 "states": ["0", "1"]
             },
             {
                 "name": "variable2",
                 "id": "x2",
                 "states": ["0", "1"]
             },
             {
                 "name": "variable3",
                 "id": "x3",
                 "states": ["0", "1"]
             },
             {
                 "name": "variable4",
                 "id": "x4",
                 "states": ["0", "1"]
             },
             {
                 "name": "variable5",
                 "id": "x5",
                 "states": ["0", "1"]
             }
         ],
         "updateRules": {
             "x1": { 
                 "possibleInputVariables": ["x2","x3", "x1"],
                 "transitionTable": [[[0, 0, 0], 1], [[0, 0, 1], 0], [[0, 1, 0], 0], [[0, 1, 1], 0], 
                 [[1, 0, 0], 1], [[1, 0, 1], 1], [[1, 1, 0], 0], [[1, 1, 1], 0]]
             },
             "x2": { 
                 "possibleInputVariables": ["x1","x2"],
                 "polynomialFunction": "x1+1"
             },
             "x3": { 
                 "possibleInputVariables": ["x1","x2"],
                 "polynomialFunction": "x1+x2"
             },
             "x4": { 
                 "possibleInputVariables": ["x1","x4"],
                 "polynomialFunction": "x1+x4"
             },
             "x5": { 
                 "possibleInputVariables": ["x2","x5"],
                 "polynomialFunction": "x2+x2*x5+x5"
             }
         }
     }}
    ///
   
TEST ///
{*
  restart
*}
  debug needsPackage "ADAMModel"
  M = parseModel sample2

  M1 = transformModel(true, "poly", M)
  M2 = transformModel(true, "poly", M1)
  assert(M1 == M2)
  M3 = transformModel(false, "tt", M2)
  M4 = transformModel(true, "tt", M3)

  N1 = transformModel(false, "poly", M4)  
  N2 = transformModel(false, "tt", M4)  
  N3 = transformModel(true, "poly", N1)
  N4 = transformModel(true, "tt", N2)
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
  M1 = addPolynomials M
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

  M1 = transformModel(true,"poly",M)
  assert(M == M1);
  
///

TEST ///
restart
    debug needsPackage "ADAMModel"
    str = get "../../exampleJSON/BooleanModels/Keratinocyte.json";
    M = parseModel str
    M1 = transformModel(true,"tt",M)
    M2 = transformModel(false,"poly",M)
    M3 = transformModel(true,"tt",M2)
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
