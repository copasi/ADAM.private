load "ADAM.m2"
loadPackage "PolynomialDynamicalSystems"

allDirs = () ->
    select(readDirectory ".", f -> isDirectory f and f != "." and f != "..")

makeTSJSON = method()
makeTSJSON String := (dirname) -> (
    strs := lines get (dirname|"/readme.txt");
    if #strs < 4 then 
        return errorPacket("expected at least 4 lines in file " | dirname|"/readme.txt");
    desc := strs#0;
    prime := value strs#1;
    numvars := value strs#2;
    experiments := for s in drop(strs,3) list (
        e := value s;
        if not(instance(e,Sequence) or #e != 2 or not instance(e#0, List) or not instance(e#1, String))
        then return errorPacket("expected "|s|" to be of form ({knockouts}, filename)")
        else (e#0, dirname|"/"|e#1)
        );
    << "writing " << (dirname|"/timeseries.json") << endl;
    (dirname|"/timeseries.json") << makeTimeSeriesJSON(desc, prime, numvars, experiments) << endl << close;
    )
makeTSJSON List := (dirnames) -> (
    if #dirnames == 0 then dirnames = allDirs();
    dirnames/makeTSJSON;
    )

end
restart
load "make-json.m2"
allDirs()
makeTSJSON "gepasi"
makeTSJSON "lactose"
makeTSJSON {}
M2 make-json.m2 --silent -e "makeTSJSON{}" -e "exit 0"
