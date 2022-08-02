#-------------------------------------------
# call: sh ./stage_cred.sh <some_instance.lp> <arg>
#-------------------------------------------

#!/bin/bash

dir=$(dirname $0)

accept="SATISFIABLE"
reject="UNSATISFIABLE"

# Parameter: instance $1
if [ -z "$1" ] || [ ! -f $1 ]
then
	echo 'parameter missing or file does not exist'
	exit
fi

echo ":- not in($2)." > "$dir"/query.lp

# echo "Running clingo to compute the ranges"
# compute the range maximal answer sets | select answer set | select answersets with <arg> in the range
echo "#show in/1." | "$dir"/../../clingo - "$dir"/heuristic_stage.lp $1 --heuristic=Domain --enum=domRec 0 | grep 'range' | grep -v 'undec('$2')'| sed 's/)/)./g; s/range//g' > "$dir"/rangeList.tmp

if grep -q "in("$2")" "$dir"/rangeList.tmp; then
  echo "$accept"
  exit 0
fi

# echo "Perform Reasoning with stable extensions"

while read p; do
  extension=$(echo "$p" | sed 's/in([[:alnum:]]*).//g; s/range//g' | "$dir"/../../clingo - "$dir"/stable.lp $1 "$dir"/query.lp 1 | grep 'in('$2')')  
  if [ ! -z "$extension" ]
  then
    echo "$accept"
#     echo $extension
    exit 0    
  fi
done < "$dir"/rangeList.tmp

echo "$reject"
#cat "$dir"/rangeList.tmp
