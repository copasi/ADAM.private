#! /bin/bash

################
## construct truth table folders/files in the necessary format
## usage ./create_files.sh "../plantsim_models/sample.txt"
## use./create_files.sh "../plantsim_models/sample.txt" "1" to keep temporary folders 
###################3

#reading
inputfile="$1";
folder_existed="1";

mainfolder="$inputfile"_tempfolder

if [ ! -r "$mainfolder" ]; then
    folder_existed="0";
    mkdir "$mainfolder"
#else
#    echo "WARNING: temporary folder already exists"
fi

if [ ! -f "$inputfile" ]; then
    echo "ERROR: file does not exist. Exiting..."
    exit
fi


k="0"; index="0"
while read line; do
    if [ "$line" = "num_functions" ]; then method="n"; k="0"; fi
    if [ "$method" = "n" ] && [ "$k" = "1" ]; then numfun=$(($line)); fi
    #
    if [ "$line" = "num_states" ]; then method="ns"; k="0"; fi
    if [ "$method" = "ns" ] && [ "$k" = "1" ]; then numstates="$line"; fi
    #
    if [ "$line" = "var_names" ]; then method="vn"; k="0"; fi
    if [ "$method" = "vn" ] && [ "$k" = "1" ]; then varnames="$line"; fi
    #
    if [ "$line" = "function" ]; then method="f"; k="0"; fi
    if [ "$method" = "f" ] && [ "$k" = "1" ]; then TARGET[index]="$line"; index="$(($index+1))"; fi
    #
    if [ "$line" = "inputs" ]; then method="i"; k="0"; fi
    if [ "$method" = "i" ] && [ "$k" = "1" ]; then I[index]="$line"; fi
    #
    #echo "${#line}";
    if [ "$line" = "truth_table" ]; then method="tt"; k="0"; fi
    if [ "$method" = "tt" ] && [ "$line" != "" ] && (("$k">=1)) && ((${#line}>1)); then TT[index]="${TT[$index]}
$line"; fi
    #echo "k= $k" ; 
    k="$(($k+1))";   
done < "$inputfile"


##find max num of states
arr_numstates=($numstates)
maxstates=0;
for i in "${arr_numstates[@]}"; do
    if (("$i">"$maxstates")); then maxstates="$i"; fi
done

##write info to file
echo "$inputfile" > "$mainfolder/model.csv"
echo "$numfun Nodes" >> "$mainfolder/model.csv"
echo "$maxstates States" >> "$mainfolder/model.csv"
echo ""  >> "$mainfolder/model.csv"

arr_varnames=($varnames)
for ((i=1;i<="$numfun";i++)); do
    echo "AbrevName: ${arr_varnames[$(($i-1))]}" >> "$mainfolder/model.csv"
    echo "States: ${arr_numstates[$(($i-1))]}" >> "$mainfolder/model.csv"
    echo "Table: Tables/${arr_varnames[$(($i-1))]}.csv" >> "$mainfolder/model.csv"
    echo ""  >> "$mainfolder/model.csv"
done

##find all edges
num_edges=0;
ALLEDGES="";
for ((j=1;j<="$numfun";j++)); do
    xj="${TARGET[$(($j-1))]}"
    INPUTS="${I[$j]}"; INPUTS=($INPUTS)
    for xi in "${INPUTS[@]}"; do
        if [ "$xj" != "$xi" ]; then 
            num_edges="$(($num_edges+1))";
            ALLEDGES="$ALLEDGES
Start: $xi
End: $xj
"
        fi
    done
done

echo "$num_edges Edges"  >> "$mainfolder/model.csv"
echo "$ALLEDGES"  >> "$mainfolder/model.csv"

if [ ! -r "$mainfolder/Tables" ]; then
    mkdir "$mainfolder/Tables"
#else
#    echo "WARNING: Tables folder already exists"
fi

for ((j=1;j<="$numfun";j++)); do
    xj="${TARGET[$(($j-1))]}"    
    echo "SPEED:" > "$mainfolder/Tables/$xj.csv"
    echo "${I[$j]} $xj${TT[$j]}" >> "$mainfolder/Tables/$xj.csv";
done

echo "$mainfolder/model.csv"   | ./src/MFVSfixedpoints

##if [ "$folder_existed" = "1" ] && [ "$2" != "1" ]; then rm -r "$mainfolder/Tables" "$mainfolder/model.csv"; fi
if [ "$2" != "1" ]; then rm -r "$mainfolder"; fi











