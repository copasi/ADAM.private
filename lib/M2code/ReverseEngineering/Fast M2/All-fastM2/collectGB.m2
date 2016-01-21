load "PolynomialDynamicalSystems.m2"
needsPackage "Points"


--TS is a hashtable of time series data WITH NO KO DATA
TS = readTSDataFromJSON get "Gepasi-2.json";

pp = char ring TS; --Field characteristic (MUST come as input)
kk = ring TS; --Field
nn = numColumns TS; --Number of variables (MUST come as input)

--k=10; --k*(number of variables) is the number of PDS models normalized wrt G. bases

--FD is a list of hashtables, where each contains the input-vectors/output pairs for each node
FD = apply(nn, II->functionData(TS, II+1));

--IN is a matrix of input vectors
IN = matrix keys first FD;

Rr = kk[vars(53..52+nn)];

-----------

allNFs={};
apply(1000, i->(f=openIn ("NF-A-"|i|".txt"); nf=value get f; allNFs=append(allNFs, nf)));

allCounts={};
FF={};
apply(nn, JJ->(
s={};
apply(1000, II->(
--apply(1, II->(
s=append(s,toString (allNFs#II#JJ));
--s=append(s,allNFs#II#JJ); --leave functions in the ring
));


--Count how many times a normal form is repeated for each local polynomial
ssort=rsort s;
fns={};
c=1;
el=toString ssort#0;
apply(#ssort-1, II->(
if el==toString ssort#(II+1) then c=c+1 else (fns=append(fns,{value el,c/(1000*1.0)}), el=toString ssort#(II+1), c=1); ));
fns=append(fns,{value el,c/(1000*1.0)});
FF=append(FF,fns);
));

A=createRevEngJSONOutputModel FF;
B=toHashTable A;
C=prettyPrintJSON B;
"sample-output-gfan.txt" << C << endl << close