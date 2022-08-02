#-------------------------------------------
# call: sh stage2.sh <some_instance.lp>
#-------------------------------------------



#!/bin/sh

dir=$(dirname $0)

# Parameter: instance $1
if [ -z "$1" ] || [ ! -f $1 ]
then
	echo 'parameter missing or file does not exist'
	exit
fi

# echo "# running clingo to compute the ranges"

    "$dir"/../../../clingo "$dir"/heuristic_stage.lp $1 --heuristic=Domain --enum=domRec 0 2>/dev/null | grep 'range' | sed 's/)/)./g; s/range//g' > "$dir"/rangeList.tmp

    ## exit the script if clingo failed
    ex=$?
    if [[ $ex != 0 ]]; then
        exit $ex
    fi
	   
    #cat "$dir"/rangeList.tmp

# echo "# Compute stable extensions"
    
    echo "["
    while read p; do
        #echo "$p"
        echo "$p" | "$dir"/../../../clingo - "$dir"/stable.lp $1 0 2>/dev/null | grep 'stbExt' | sed 's/ stbExt//; s/stbExt //; s/stbExt/]/; s/in(//g; s/) /,/g; s/)/]/; s/^/[/'
        ## exit the script if clingo failed
        ex=$?
        if [[ $ex != 0 ]]; then
            exit $ex
        fi
    done < "$dir"/rangeList.tmp

    echo "]"
