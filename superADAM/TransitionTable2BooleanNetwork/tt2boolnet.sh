#! /bin/bash

################
## construct truth table files in the necessary format
###################3

#reading
inputfile="$1";
k="0";
while read line; do
    if [ "$line" = "num_functions" ]; then method="n"; k="0"; fi
    if [ "$method" = "n" ] && [ "$k" = "1" ]; then numfun=$(($line)); fi
    #
    if [ "$line" = "function" ]; then method="f"; k="0"; fi
    if [ "$method" = "f" ] && [ "$k" = "1" ]; then index="$(($line))"; fi
    #
    if [ "$line" = "inputs" ]; then method="i"; k="0"; fi
    if [ "$method" = "i" ] && [ "$k" = "1" ]; then INPUTS[index]="$line"; TT[index]="$line"; fi
    #
    #echo "${#line}";
    if [ "$line" = "truth_table" ]; then method="tt"; k="0"; fi
    if [ "$method" = "tt" ] && (("$k">=1)) && ((${#line}>0)); then TT[index]="${TT[$index]}
$line"; fi
    #echo "k= $k" ; 
    k="$(($k+1))";   
done < "$inputfile"


#########
## does not work if there are more than 26 variables
#########
for ((i=1;i<="$numfun";i++)); do
    num_inputs=`echo "${INPUTS[$i]}"  | wc -w`
    if (("$num_inputs">26)); then echo "ONLY WORKS UP TO 26 VARIABLES"; exit; fi
done

#creating files
#echo "num=$numfun"

for ((i=1;i<="$numfun";i++)); do 
    echo "${TT[$i]}" > "$inputfile"."$i";
done


basename="$inputfile"; 
#########
## create Boolean function for each file that contains a truth table
#########

## get inputs that show up in each file
for ((varindex=1;varindex<="$numfun";varindex++)); do
ttfile="$basename.$varindex"
allvars=`head -1 "$ttfile"`; 
numvars=`echo "$allvars"|wc -w`; 
#get variables that show up in the function
k="0";
for i in ${allvars[@]}; do 
    vars["$k"]="$i"; k="$(($k+1))"; #echo "$i $k"; 
done

#read truth table from file
k="0"; numlines="0"; truthtable="";
while read line; do
    if ((k>0)) && [ "${line:((${#line}-1))}" != "0" ]; then   
        truthtable=`printf "$truthtable
$line"`; numlines="$(($numlines+1))";
    fi
    k="$(($k+1))"
done <"$ttfile"


#check if it is a constant function
if (($numvars==0)); 
    then BF[varindex]=$(($truthtable)); 
    continue; 
fi

#create file necessary for qm code
truthtable=`printf "$numvars
$numlines$truthtable"`;
echo "$truthtable"> "$ttfile"
#cat "$ttfile"
#echo "${vars[0]}"
#echo "${vars[1]}"
#echo "${vars[2]}"
#echo "${vars[3]}"

#use qm code to generate Boolean function
F=`./quinemccluskey-master/qm "$ttfile" |grep F| cut -f1 --complement -d"="`
IFS=" + "; read -ra NF <<< "$F"

#use original notation of variables (qm uses ABC..., NOT x1, x2,...)
letters="ABCDEFGHIJKLMNOPQRSTUVWXYZ";
REDNF="";
for TERM in "${NF[@]}"; do
  for (( i=0; i<${#letters}; i++ )); do
    x="${letters:$i:1}";
    TERM=`echo "$TERM"|sed "s/$x"\'"/"\!"${vars[$i]} \& /g"`
    TERM=`echo "$TERM"|sed "s/$x/${vars[$i]} \& /g"`
  done
  TERM=`echo "$TERM"| head -c -4`
  REDNF=`echo "$REDNF | ($TERM)"`
done
REDNF=`echo "$REDNF"| tail -c +4`
BF[varindex]="$REDNF";
done

#echo Boolean functions and remove temp files
for ((i=1;i<=$numfun;i++)); do
     rm "$basename.$i"; 
     echo "${BF[$i]}";
done

