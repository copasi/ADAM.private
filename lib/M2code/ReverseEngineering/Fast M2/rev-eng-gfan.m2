--*********************
--File Name: rev-eng-gfan.m2
--Author: Elena S. Dimitrova
--Original Date: 10/21/2014
--Modified: 3/9/2015
--Descritpion: Generates file sample-output-gfan.txt that contains for each local polynomial all distinct normal forms and the corresponding proportion wrt all normal forms. Takes multiple time series data and generates k*(number of variables) PDS models normalized wrt G. bases under monomial orderings defined by weight vectors that are randomly selected from the G. fan of the ideal of data points.
--Input: Field characteristic; number of variables; time series files
--Output: File sample-output-gfan.txt that contains for each local polynomial all distinct normal forms and the corresponding proportion wrt all normal forms.
--********************* 

load "PolynomialDynamicalSystems.m2"
needsPackage "Points"


--TS is a hashtable of time series data WITH NO KO DATA
TS = readTSDataFromJSON get "3-node.json";

pp = char ring TS; --Field characteristic (MUST come as input)
kk = ring TS; --Field
nn = numColumns TS; --Number of variables (MUST come as input)

k=10; --k*(number of variables) is the number of PDS models normalized wrt G. bases

--FD is a list of hashtables, where each contains the input-vectors/output pairs for each node
FD = apply(nn, II->functionData(TS, II+1));

--IN is a matrix of input vectors
IN = matrix keys first FD;

allNFs={};
functs={};
allFuncts={};

--Sample randomly from the G. fan
setRandomSeed processID();
--apply(5*nn, J -> (
--Choose method for picking a random weight vector: the first excludes some points in the middle of the G. fan, the second include more than necessary of them, so they balance each other.
wch=random(0,1);
if wch==0 then(
m=1000*nn;
w={random(0,m)};
apply(nn-2, II->(w=append(w,random(0,m=m-w#II));
));
w=append(w,m-w#(nn-2));
permw={};
apply(nn, i->(
r=random(0,#w-1);
permw=append(permw, w#r);
w=drop(w,{r,r});));
) else (permw= apply(nn, i->random nn););

print permw;

--Rr is a polynomial ring in nn variables; can declare a term order here
Rr = kk[vars(53..52+nn), Weights => permw];

--SM is a list of standard monomials
--LT is an ideal of leading terms
--GB is a list of Grobner basis elements - THIS IS WHAT YOU WANT FOR GFAN
(SM, LT, GB) = points(transpose IN, Rr);

--F is a list of interpolating functions, one for each node 
FF = apply(nn, II->findFunction(FD_II, gens Rr));

use Rr;

GG = {matrix{GB}};

NF = apply(nn, II->apply(GG, gb->(FF_II)%gb));

temp={};
temp=apply(nn, II->append(temp,NF#II#0));
allNFs=append(allNFs,flatten temp);

fl = "NF-A-"|J|".txt";
file = openOut fl;
--file << "{";
apply(#allNFs, i->(file << toString allNFs#i; if i<#allNFs-1 then file << ","));
--file << "}";
file << close;
--));

end
----------------------------------------------------- end of file---------------------------------------------------


apply(nn, JJ->(
s={};
apply(k*nn, II->(
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
if el==toString ssort#(II+1) then c=c+1 else (fns=append(fns,{value el,c/(k*nn*1.0)}), el=toString ssort#(II+1), c=1); ));
fns=append(fns,{value el,c/(k*nn*1.0)});
FF=append(FF,fns);
));

A=createRevEngJSONOutputModel FF;
B=toHashTable A;
C=prettyPrintJSON B;
"sample-output-gfan.txt" << C << endl << close


