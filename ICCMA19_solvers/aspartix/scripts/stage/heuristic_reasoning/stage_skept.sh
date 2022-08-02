#-------------------------------------------
# call: sh ./stage_skept.sh <some_instance.lp> <arg>
#-------------------------------------------

#!/bin/sh

dir=$(dirname $0)

accept="UNSATISFIABLE"
reject="SATISFIABLE"

# Parameter: instance $1
if [ -z "$1" ] || [ ! -f $1 ]
then
	echo 'parameter missing or file does not exist'
	exit
fi

query=":- in($2)."

# echo "Running clingo to compute the ranges"
# compute the range maximal answer sets | select answer set | select answersets with <arg> in the range
    echo "#show out/1." | "$dir"/../../../clingo - "$dir"/heuristic_stage.lp $1 --heuristic=Domain --enum=domRec 0 2>/dev/null | grep 'range' | sed 's/)/)./g; s/range//g' > "$dir"/rangeListSkept.tmp 
    
    ## exit the script if clingo failed
    ex=$?
    if [[ $ex != 0 ]]; then
        exit
    fi
    
    #cat "$dir"/rangeListSkept.tmp
    
if grep -q "out("$2")\|undec("$2")" "$dir"/rangeListSkept.tmp; then
  echo "$reject" 
  exit 0
fi

# echo "Perform Reasoning with stable extensions"

while read p; do
  extension=$(echo "$p $query" | (sed 's/out([^()]*).//g; s/range//g') | "$dir"/../../../clingo - "$dir"/stable.lp $1 1 2>/dev/null) 
    # exist status of clingo
    ex=$?
    
    #echo "$ex"
    # no answer set
    if [[ $ex = 20 ]] ; then
        continue  
    fi    
    # has an answer set
    if [[ $ex = 10 ]] || [[ $ex = 30 ]] ; then
        echo "$reject"
        echo "$extension" | grep "in(" 
        exit 0    
    fi    

    if [[ $ex != 0 ]]; then
        exit 1
    fi
done < "$dir"/rangeListSkept.tmp

echo "$accept"
