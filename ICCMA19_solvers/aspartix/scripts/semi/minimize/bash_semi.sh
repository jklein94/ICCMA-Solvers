#-------------------------------------------
# call: ./bash_semi.sh <some_instance.lp>
#-------------------------------------------

# run complete encoding (in folder)
# write output to tmp.txt (save in folder)




#!/bin/sh

dir=$(dirname $0)

# Parameter: instance $1
if [ -z "$1" ] || [ ! -f $1 ]
then
	echo 'parameter missing or file does not exist'
	exit
fi

# run clingo complete semantics
"$dir"/../../../clingo "$dir"/comp.lp $1 0 2>"$dir"/error.txt | grep "in(\|undec" > "$dir"/tmp.txt 
#"$dir"/./clingo "$dir"/comp.lp $1 0 &> "$dir"/tmp.txt 

#ex=$?
#if [[ $ex != 0 ]]; then
#	exit $ex
#fi

if grep -q "INTERRUPTED" "$dir"/error.txt; then
	exit 
fi

# check if line without "undec" exists
if grep -v -q "undec" "$dir"/tmp.txt; then
	# semi = stable
	grep 'in(' "$dir"/tmp.txt | grep -v 'undec'
	echo "FIN"
else
	# no stable extension exists
	python3 "$dir"/py_semi.py tmp.txt
fi
#echo "FIN"
