----------------------------------------------------------
--Author: Brandy Stigler
--Purpose: minset examples for Sebastian
--Date: 5-4-09
--
--Input files: 	seb1.st and seb2.st
--		Make sure they are in the same directory
--		as the current file.
--Library file:	PolynomialDynamicalSystems.m2
--		Make sure it is in the same directory 
--		as the current file.
--To run the data in the input files,
--uncomment the appropriate WT line.
--Output:	Displayed in the M2 session.
----------------------------------------------------------

needs "PolynomialDynamicalSystems.m2"

------------------------------------------
--Uncomment whichever file you wish to run
------------------------------------------

--WT = {"seb1.st"};		--not bad
--WT = {"seb2.st"};		--not good
WT = {"seb1.st","seb2.st"};	--perfect

-------------------------------------------
--Computing and displaying minsets and fncs
-------------------------------------------

P = 2;
N = 4;
K = ZZ/P;
T = readTSData(WT, {}, K);
R = K[makeVars N];
FD = apply(N, i->functionData(T,i+1));
MR = apply(FD, f->minRep(f,R));
PD = apply(MR, m->if m=!=0 then primaryDecomposition m else 0);
VL = apply(PD, l->
    apply(l, m->if m=!=0 then flatten entries gens m else {})
);
FS = apply(N, i->
	if VL_i != {} 
	then apply(VL_i, l->findFunction(functionData(T,i+1),l)) 
	else findFunction(functionData(T,i+1),gens R)
);

H = new HashTable from 
	apply(N, i->((gens R)_i, 
	new HashTable from 
		apply(#VL_i, j->VL_i_j=>FS_i_j)
	));

print "\nThe following display shows the minimal sets and associated functions for each variable.\n"  
print H

---------------------
end
---------------------

Desired functions
f1 = x1+x2+1
f2 = x1*x3
f3 = x2*x4
f4 = x1+x4

Associated minimal sets
x1: {x1,x2}
x2: {x1,x3}
x3: {x2,x4}
x4: {x1,x4}

To see the state space* of these functions, go to

http://dvd.vbi.vt.edu/visualizer/new_dvd11.pl

Plug in the functions, set #nodes = 4 and #states = 2
Check "State space graph" and click "Generate"

Please let me know if you have questions using this site.

-------------------------------------------
*State space = directed graph G representing the evaluation of 
the functions on all possible states

i.e., G=(V,E) with 
	V := set of 2^4=16  4-tuples (states)
	E := (s, f(s)) where s is a state and f=(f1,f2,f3,f4)

