--*********************
--File Name: Discretize.m2
--Author: Elena S. Dimitrova
--Original Date: 3/8/2009
--Last modified: 1/20/2016
--Descritpion: Booleanizes the input data based on our discretization method. 
--Input: JSON time series file
--Output: Files named "JSON-ts-output.txt" with booleanized data.
--********************* 

loadPackage "PolynomialDynamicalSystems"
needsPackage "Points"

discretizeTS = method(Options=>{characteristic=>2})
discretizeTS(String) := opts -> (TS) -> (

TSjson = readTSDataFromJSON get TS;

levels=2; --will change
m={};
discrm={};
count={};

mat=TSjson.WildType;
apply(#mat, s -> (m = append(m, entries mat#s); count=append(count, #(entries mat#s))));

m=transpose flatten m;

for j from 0 to #m-1 do (dis={}; msort=sort m#j; d=0;
 for i from 1 to #msort-1 do (if d<abs(msort#(i)-msort#(i-1)) then (d=msort#(i-1)) );
apply(#msort, s->(if m#j#s <= d then dis=append(dis, 0) else dis=append(dis, 1)));
discrm=append(discrm, dis);

);
c=0;
for f from 0 to 0 do (
fl="Discr-ts.txt"; file=openOut fl;
for i from 0 to count#f-1 do (
for j from 0  to #((transpose discrm)#(c+i))-1 do (
file<<(transpose discrm)#(c+i)#j<<" ";);
file << endl; );
c=c+count#f;
file<<close;);
out=makeTimeSeriesJSON("output discretization", levels, #m, {{{}, "Discr-ts.txt"}});
"JSON-ts-output.json" << out << endl << close;
removeFile toString file;
)

end
----------------------------------------------------- end of file---------------------------------------------------