--*********************
--File Name: func.m2
--Author: Elena S. Dimitrova
--Original Date: 8/16/2009
--Descritpion: Generates file functs.txt that contains for each local polynomial all distinct normal forms and the corresponding proportion wrt all normal forms. Takes multiple time series data and generates 5*(number of variables) PDS models normalized wrt G. bases under monomial orderings defined by weight vectors that are randomly selected from the G. fan of the ideal of data points.
--Input: Field characteristic; number of variables; time series files
--Output: File functs.txt that contains for each local polynomial all distinct normal forms and the corresponding proportion wrt all normal forms.
--********************* 

load "PolynomialDynamicalSystems.m2"
needsPackage "Points"

pp = 5; --Field characteristic (MUST come as input)
kk = ZZ/pp; --Field
nn = 4; --Number of variables (MUST come as input)


--WT={"ecoli1-1-1-1.txt", "ecoli1-1-1-2.txt"};
WT={"test-1.txt"};

--TS is a hashtable of time series data WITH KO data
TS = readTSData(WT, {}, kk);

--FD is a list of hashtables, where each contains the input-vectors/output pairs for each node
FD = apply(nn, II->functionData(TS, II+1));

--IN is a matrix of input vectors
IN = matrix keys first FD;

allNFs={};
functs={};
allFuncts={};

k=10;

--Sample randomly from the G. fan
setRandomSeed processID();
apply(k*nn, J -> (
m=k*nn;
w={};
w={random(0,m)};
apply(nn-2, II->(w=append(w,random(0,m=m-w#II));
));
w=append(w,m-w#(nn-2));

prms=permutations w;
pn=random (#prms);
w=prms#pn;


--Rr is a polynomial ring in nn variables; can declare a term order here
Rr = kk[vars(53..52+nn), Weights => w];

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

));

allCounts={};
FF={};
apply(nn, JJ->(
s={};
apply(#allNFs, II->(
s=append(s, allNFs#II#JJ);
));


--Count how many times a normal form is repeated for each local polynomial

st={};
apply(#s, i->(st=append(st,sub(s#i,ring s#0))));

s=st;
st=set st;
st=toList st;

fns={};
c=0;

apply(#st, i->(
apply(#s, j->(if st#i==s#j then c=c+1)),
fns=append(fns,{st#i,c});
c=0;
)); 

FF=append(FF,fns);
));

--For each local polynomial f_i, print f_i={all distinct normal forms and the corresponding proportion wrt all normal forms}
file = openOut "toy-functs-3-1200.txt";
apply(nn, i->(file << "f" << i+1 << " = {" << endl; apply(FF#i, q->(file << toString q#0 << "   " << toString ((q#1)/(#allNFs*1.)) << endl)); file << "}" << endl));
file << close;

end
----------------------------------------------------- end of file---------------------------------------------------