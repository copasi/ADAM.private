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
    polys := for f in L list P f;
    varlist := for x in gens R list hashTable {
        "id" => toString x, 
        "name" => toString x, 
        "states" => {0,1}};
    updateRules := hashTable for i from 0 to numgens R - 1 list (
        f := P (L#i);
        (toString R_i) => hashTable {
            "polynomialFunction" => toString f,
            "possibleInputVariables" => (rsort support f)/toString
            }
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
load "read-logical-formulae.m2"
filename = "~/Google Drive/ADAM_redesign/BOOLEAN_MODELS_Bformat/Influenza_A_Virus.model"
M = createModelFromLogicalFormulas(filename, "Influenza_A_Virus.model")
checkModel M
prettyPrintJSON M


prefix = "~/Google Drive/ADAM_redesign/BOOLEAN_MODELS_Bformat/"
outfix = "~/src/reinhard/ADAM/exampleJSON/BooleanModels/"
files = readDirectory prefix
fileprefixes = for f in files list (
    if not match(".model$", f) then continue;
    substring(f, 0, #f-6)
    )
for f in drop(fileprefixes,2) do (
    M = createModelFromLogicalFormulas(prefix|f|".model", f);
    << "creating " << (outfix|f|".json") << endl;
    (outfix|f|".json") << prettyPrintJSON M << endl << close
    )
