#-------------------------------------------
# call: bash ./stage_skept.sh <some_instance.lp> <arg>
#-------------------------------------------

#!/bin/bash

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
echo "#show out/1." | "$dir"/../../clingo - "$dir"/heuristic_stage.lp $1 --heuristic=Domain --enum=domRec 0 | grep 'range' | sed 's/)/)./g; s/range//g' > "$dir"/rangeList.tmp

if grep -q "out("$2")\|undec("$2")" "$dir"/rangeList.tmp; then
  echo "$reject"
  exit 0
fi

# echo "Perform Reasoning with stable extensions"

while read p; do
  extension=$(echo "$p $query" | (sed 's/out([[:alnum:]]*).//g; s/range//g') | "$dir"/../../clingo - "$dir"/stable.lp $1 1 | grep 'stbExt')  
  if [ ! -z "$extension" ]
  then
    echo "$reject"
#     echo $extension
    exit 0    
  fi
done < "$dir"/rangeList.tmp

echo "$accept"
