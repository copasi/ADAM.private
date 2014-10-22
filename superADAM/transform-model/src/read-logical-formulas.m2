-- The purpose of this file is
--  input: a file with one logical formula per line, representing x1, x2, x3, ...
--   each logical formula involves variables xi, |, &, !, 0, 1, and parentheses, and spaces are ignored.
-- Output: a model json file

  makeBooleanRing = (n) -> (
      A := ZZ/2[for i from 1 to n list ("x"|toString i)];
      I := for x in gens A list x^2+x;
      B := A/I;
      B
      );

loadPackage "LogicalFormulas"
loadPackage "ADAMModel"

createModelFromLogicalFormulas = method()
createModelFromLogicalFormulas(String,String) := (filename,name) -> (
    L := select(lines get filename, s -> #s > 0);
    R := makeBooleanRing (#L);
    P := makeLFParser R;
    varlist := for x in gens R list hashTable {
        "id" => toString x, 
        "name" => toString x, 
        "states" => {0,1}};
    updateRules := for i from 0 to numgens R - 1 list hashTable (
        << "starting i=" << i << " " << L#i << endl;
        f := P (L#i);
        {"functions" => {hashTable {
            "target" => toString R_i,
            "booleanFunction" => L#i,
            "polynomialFunction" => toString f,
            "inputVariables" => (rsort support f)/toString
            }}}
        );
    model(name,
        "description" => "",
        "version" => "1.0",
        "variables" => varlist,
        "parameters" => {},
        "updateRules" => updateRules
        )
    )


end

restart
load "read-logical-formulas.m2"
filename = "~/Google Drive/ADAM_redesign/BOOLEAN_MODELS_Bformat/Influenza_A_Virus.model"
M = createModelFromLogicalFormulas(filename, "Influenza_A_Virus.model")
checkModel M
prettyPrintJSON M

-- to recreate the boolean models from the google drive, do the following:
-- fileprefixes#1 currently has a syntax error, which is why we ignore that one
restart
load "read-logical-formulas.m2"
prefix = "~/Google Drive/ADAM_redesign/BOOLEAN_MODELS_Bformat/"
outfix = "~/src/reinhard/ADAM/exampleJSON/BooleanModels/"
files = readDirectory prefix
fileprefixes = for f in files list (
    if not match(".model$", f) then continue;
    substring(f, 0, #f-6)
    )
for f in drop(fileprefixes,{1,1}) do (
    time M = createModelFromLogicalFormulas(prefix|f|".model", f);
    << "creating " << (outfix|f|".json") << endl;
    (outfix|f|".json") << prettyPrintJSON M << endl << close
    )

-- to check these:
for f in drop(fileprefixes,{1,1}) list parseJSON get (outfix|f|".json")
