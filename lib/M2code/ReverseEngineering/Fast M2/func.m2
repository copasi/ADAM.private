--*********************
--File Name: func.m2
--Author: Elena S. Dimitrova
--Original Date: 3/5/2009
--Descritpion: Generates file functs.txt that contains for each local polynomial all distinct normal forms and the corresponding proportion wrt all normal forms. Takes multiple time series data and generates 5*(number of variables) PDS models normalized wrt G. bases under monomial orderings defined by weight vectors that are randomly selected from the G. fan of the ideal of data points.
--Input: Field characteristic; number of variables; time series files
--Output: File functs.txt that contains for each local polynomial all distinct normal forms and the corresponding proportion wrt all normal forms.
--********************* 

load "PolynomialDynamicalSystems.m2"
needsPackage "Points"

kk = QQ; --Field
nn = 3; --Number of variables (MUST come as input)


--Sample randomly from the G. fan
setRandomSeed processID();

--Choose a random radius in [0,1]
m=10*nn;
onept={}; 

--Get 2 normal numbers
for j from 1 to 2 do(
x=random 1.; y=random 1.;
onept=append(onept, sqrt(-2*log(x))*cos(2*pi*y));
onept=append(onept, sqrt(-2*log(x))*sin(2*pi*y));
);
--Get the 3rd number
t=random 2;
if t==0 then onept=append(onept, sqrt(-2*log(x))*cos(2*pi*y)) else onept=append(onept, sqrt(-2*log(x))*sin(2*pi*y));

r=random 1.;
r=r^(1./nn);

q=0;
for j from 0 to nn-1 do (q=q+(onept#j)^2);
q=sqrt(q);
normpts={};
for j from 0 to nn-1 do (p=(onept#j)*r/q; normpts=append(normpts,p);
);


--Convert spherical to rectangular coordinates
rectcoords={};
apply(nn, i->(
j=1;
while abs(normpts#i)>j/m do j=j+1;
rectcoords=append(rectcoords, j-1); 
));

print rectcoords;

--Rr is a polynomial ring in nn variables; can declare a term order here
Rr = kk[vars(53..52+nn), Weights => rectcoords];

--Here one inserts the GB that oneGB.m2 calculated in the form
--I=ideal(x2*x3 + x1^2, x1*x2 + x3^2, x1^3-x3^3);
G=gb I;

--??? Some more work...



fl = "GrB"|J|".txt";
file = openOut fl;
apply(count, i->(file << i <<" "));
file << close;


end
----------------------------------------------------- end of file---------------------------------------------------