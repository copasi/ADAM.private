---------------------------------------------------
-- Be sure to restart M2 before reloading this file
---------------------------------------------------

---------------------------------------------------
-- Example for Elena 
-- (1) to compute an input Grobner basis for Gfan
-- (2) to compute normal forms for each output of Gfan
-- Author: Brandy Stigler
-- Date: 1-31-06
-- Modified by: Elena Dimitrova
---------------------------------------------------

load "PolynomialDynamicalSystems.m2"
needsPackage "Points"

p = 3;
k = ZZ/p;
n = 3;

WT = {"data1.st"};
--WT = {"data1.st","data4.st"};
--WT = {"FF5.txt"};


--TS is a hashtable of time series data WITH NO KO DATA
TS = readTSData(WT, {}, k);


--FD is a list of hashtables, where each contains the input-vectors/output pairs for each node
FD = apply(n, i->functionData(TS, i+1));


--IN is a matrix of input vectors
IN = matrix keys first FD;


--R is a polynomial ring in n variables; can declare a term order here
R = k[a..c, MonomialOrder=>Lex];


--SM is a list of standard monomials
--LT is an ideal of leading terms
--GB is a list of Grobner basis elements - THIS IS WHAT YOU WANT FOR GFAN
(SM, LT, GB) = points(transpose IN, R);


--F is a list of interpolating functions, one for each node 
F = apply(n, i->findFunction(FD_i, gens R));


--The next lines are for myself to have a list G of GBs
--You will get a list from Gfan
--S = k[x3,x2,x1, MonomialOrder=>Lex];
--(SM1, LT1, GB1) = points(transpose IN, S);
use R;
G = {matrix{GB}};
--G = {matrix{GB,matrix{apply(GB1, g->sub(g,R))}};


--Let G be your list of GBs
--To compute normal forms for each GB, use the following code
--NFi is the remainder of fi wrt each GB in G
--NF1 = apply(G, gb->(F_0)%gb);
--NF2 = apply(G, gb->(F_1)%gb);
--NF3 = apply(G, gb->(F_2)%gb);

--or more slick code is
NF = apply(n, i->apply(G, gb->(F_i)%gb));


--Below is the code to print the generators of GB, one per line
file = openOut "func.txt";
--file << toString F_0 << endl;
--file << toString F_1 << endl;
--file << toString F_2 << endl;
--file << toString F_3 << endl;
--file << toString F_4 << endl;

apply(NF, g-> file << toString g << endl);
file << "{";
apply(GB, g-> file << toString g << ",");
file << "}";
file << close;


--file = openOut "NF.txt";
--apply(NF, g-> file << toString g << endl);
--file << close;


end

---------------------------------------------------
-- end of file
---------------------------------------------------
