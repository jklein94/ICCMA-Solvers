#-------------------------------------------
# call: sh ./semi_cred.sh <some_instance.lp> <arg>
#-------------------------------------------

#!/bin/sh

dir=$(dirname $0)

accept="SATISFIABLE"
reject="UNSATISFIABLE"

# Parameter: instance $1
if [ -z "$1" ] || [ ! -f $1 ]
then
	echo 'parameter missing or file does not exist'
	exit
fi

query=":- not in($2)."

# echo "Running clingo to compute the ranges"
    # # compute the range maximal answer sets | select answer set | select answersets with <arg> in the range
    echo "#show in/1. undec(dummy964052wd)." | "$dir"/../../../clingo - "$dir"/heuristic_semi.lp $1 --verbose=0 --heuristic=Domain --enum=domRec 0 2>/dev/null | grep 'range' | grep -v 'undec('$2')'| sed 's/)/)./g; s/range//g' > "$dir"/rangeListCred.tmp
    
    ## exit the script if clingo failed
    ex=$?
    if [[ $ex != 0 ]]; then
        exit
    fi

    #cat "$dir"/rangeListCred.tmp
if grep -q "in("$2")" "$dir"/rangeListCred.tmp; then
  echo "$accept"
  exit 0
fi

# echo "Perform Reasoning with stable extensions"

echo "$query" > "$dir"/query.lp

while read p; do

  #cat <(echo "$p" | cat <(sed 's/in([[:alnum:]]*).//g; s/range//g')) <(echo "$query")
    
  extension=$(echo "$p" | sed 's/in([^()]*).//g; s/range//g' | "$dir"/../../../clingo - "$dir"/stable.lp $1 "$dir"/query.lp 1 2>/dev/null)
    # exist status of clingo
    ex=$?
    
    #echo "$ex"
    # no answer set
    if [[ $ex = 20 ]] ; then
        continue  
    fi    
        # has an answer set
    if [[ $ex = 10 ]] || [[ $ex = 30 ]] ; then
        echo "$accept"
        echo "$extension" | grep "in("
        exit 0  
    fi
    # clingo error
    if [[ $ex != 0 ]] ; then
        exit 1
    fi
    

    
done < "$dir"/rangeListCred.tmp

echo "$reject"
#cat "$dir"/rangeListCred.tmp
