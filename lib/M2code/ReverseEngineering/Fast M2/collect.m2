pp = 2; --Field characteristic (MUST come as input)
kk = ZZ/pp; --Field
nn = 3; --Number of variables (MUST come as input)
Rr = kk[vars(53..52+nn)];
--Rr = kk[a,b,c,d,e,f,g,h,i,j,k];


FF={};
apply(100, i->(f=openIn ("NF-A-"|i|".txt");
nf=get f; 
FF=append(FF, nf);
));


--apply(#s, i->(st=append(st,sub(poly s#i),ring poly(s#0)))));
--apply(#s, i->(st=append(st,poly s#i) ));


--For each local polynomial f_i, print f_i={all distinct normal forms and the corresponding proportion wrt all normal forms}
file = openOut "functs-cell.txt";
apply(nn, i->(file << "f" << i+1 << " = {" << endl; 
apply(FF#i, q->(file << toString q#0 << "   " << toString ((q#1)/(#FF*1.)) << endl)); 
file << "}" << endl));
file << close;