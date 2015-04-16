--*********************
--File Name: gfan.m2
--Author: Elena S. Dimitrova
--Revised by Brandy Stigler
--Date: 2/24/15
--Description: Generates file sample-output-gfan.txt that contains for each local polynomial all distinct normal forms and the corresponding proportion wrt all normal forms. Takes multiple time series data and generates k*(number of variables) PDS models normalized wrt G. bases under monomial orderings defined by weight vectors that are randomly selected from the G. fan of the ideal of data points.
--Input: Field characteristic; number of variables; time series files
--Output: File sample-output-gfan.txt that contains for each local polynomial all distinct normal forms and the corresponding proportion wrt all normal forms.
--********************* 

needsPackage "PolynomialDynamicalSystems"
needsPackage "Points"

gfanRevEng = method(TypicalValue=>List, Options=>{Multiplier=>10, RandomSeed=>null})
gfanRevEng(TimeSeriesData) := opts -> (TS) -> (

    --TS is a hashtable of time series data WITH NO KO DATA
    --TS = readTSDataFromJSON get "../test/test1-input.json";
    
    pp := char ring TS; --Field characteristic (MUST come as input)
    kk := ring TS; --Field
    nn := numColumns TS; --Number of variables (MUST come as input)
    
    --k was originally set to 10, now allowed to be an optional argument
    k:=opts.Multiplier; --k*(number of variables) is the number of PDS models normalized wrt G. bases
    
    --FD is a list of hashtables, where each contains the input-vectors/output pairs for each node
    FD := apply(nn, II->functionData(TS, II+1));
    
    --IN is a matrix of input vectors
    IN := matrix keys first FD;
    
    ----allNFs:={};
    functs:={};
    allFuncts:={};

    R := kk[vars(53..52+nn)]; -- this is the polynomial ring into which we will place all normal forms
    FF := matrix{for i from 0 to nn-1 list findFunction(FD_i, gens R)};

    --Sample randomly from the G. fan
    if opts.RandomSeed =!= null then setRandomSeed opts.RandomSeed;
    m := k*nn;
    allNFs := for j from 1 to m list (
        w:={};
        w={random(0,m)};
        apply(nn-2, II->(w=append(w,random(0,m=m-w#II));
                ));
        w=append(w,m-w#(nn-2));
        prms:=permutations w;
        pn:=random (#prms);
        w=prms#pn;
        --Rr is a polynomial ring in nn variables; can declare a term order here
        Rr := kk[vars(53..52+nn), Weights => w];
        --SM is a list of standard monomials
        --LT is an ideal of leading terms
        --GB is a list of Grobner basis elements - THIS IS WHAT YOU WANT FOR GFAN
        (SM, LT, GB) := points(transpose IN, Rr);
        --F is a list of interpolating functions, one for each node 
        ----FF := apply(nn, II->findFunction(FD_II, gens Rr));
        use Rr;
        ----GG := {matrix{GB}};
        NF := sub(FF, vars Rr) % (forceGB matrix{GB}); -- one row matrix of all normal forms wrt this GB
        ----NF := apply(nn, II->apply(GG, gb->(sub(FF_II,Rr))%gb));
        ----temp:={};
        ----temp=apply(nn, II->append(temp,NF#II#0));
        flatten entries sub(NF,vars R)
        );
    ----allCounts:={};
    ----FS={};
    ----apply(nn, JJ->(
    for i from 0 to nn-1 list (
        ----s:={};
        ----apply(k*nn, II->(
        ----        s=append(s,toString (allNFs#II#i));
        ----        --s=append(s,allNFs#II#JJ); --leave functions in the ring
        ----        ));
        ------Count how many times a normal form is repeated for each local polynomial
        ----ssort:=rsort s;
        dist := tally(allNFs/(nfs -> nfs#i)); -- list of polynomials in R for node i
        for f in keys dist list {f, dist#f / (nn * k * 1.0)}
        )
 {*
        fns:={};
        c:=1;
        el:=toString ssort#0;
        apply(#ssort-1, II->(
                if el==toString ssort#(II+1) 
                then c=c+1 
                else (
                    fns=append(fns,{value el,c/(k*nn*1.0)}), el=toString ssort#(II+1), c=1); 
                ));
        fns=append(fns,{value el,c/(k*nn*1.0)});
        fns
        ---FS=append(FS,fns);
        );
 *}
)    
--A=createRevEngJSONOutputModel FF;
--B=toHashTable A;
--C=prettyPrintJSON B;
--"sample-output-gfan.txt" << C << endl << close

--NEED TO HANDLE ERROR PACKETS
    
end
----------------------------------------------------- end of file---------------------------------------------------
