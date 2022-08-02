#!/bin/sh


# Script interface of ASPARTIX-V for ICCMA 2019 based on the Generic script interface for ICCMA 2019
# script is tested with KornShell (ksh), bash und ash (has issues with dash)
#
# Copyright note for the Generic script interface for ICCMA 2019:
# (c)2014 Federico Cerutti <federico.cerutti@acm.org> --- MIT LICENCE
# adapted 2016 by Thomas Linsbichler <linsbich@dbai.tuwien.ac.at> --- MIT LICENSE
# adapted 2018 by Francesco Santini <francesco.santini@dmi.unipg.it> --- MIT LICENSE
# adapted 2018 by Theofrastos Mantadelis <theo.mantadelis@dmi.unipg.it> --- MIT LICENSE
# Generic script interface for ICCMA 2019
# Please feel free to customize it for your own solver
# In the 2019 adaptation we use "sh" instead of "bash" because Alpine Linux does not natively support it


CLINGO=${CLINGO:='clingo'}
CLINGO_OLD=${CLINGO_OLD:='clingo440'}
ENCDIR=${ENCDIR:='encodings'}
GRDENC=${GRDENC:='grounded.lp'}
PRFENC=${PRFENC:='preferred.lp'}
STBENC=${STBENC:='stable.lp'}
SSTENC_HEURISTIC=${SSTENC_HEURISTIC:='heuristic_semi.lp'}
STGENC_HEURISTIC=${STGENC_HEURISTIC:='heuristic_stage.lp'}
# STGENC=${STGENC:='stage.lp'}
# IDLENC=${IDLENC:='ideal.lp'}
COMENC=${COMENC:='complete.lp'}

# function for echoing on standard error
function echoerr()
{
    # to remove standard error echoing, please comment the following line
    echo "$@" 1>&2; 
}

################################################################
# C O N F I G U R A T I O N
# 
# this script must be customized by defining:
# 1) procedure for printing author and version information of the solver
#    (function "information")
# 2) suitable procedures for invoking your solver (function "solver");
# 3) suitable procedures for parsing your solver's output 
#    (function "parse_output");
# 4) list of supported format (array "formats");
# 5) list of supported problems (array "problems").

# output information
function information()
{
    echo "Solver: ASPARTIX-V v19"
    echo ""
    echo "Team:"
    echo "Wolfgang Dvorak <dvorak@dbai.tuwien.ac.at>"
    echo "Anna Rapberger <arapberg@dbai.tuwien.ac.at>"
    echo "Johannes P. Wallner <wallner@dbai.tuwien.ac.at>"
    echo "Stefan Woltran <woltran@dbai.tuwien.ac.at>"
    echo ""
    echo -n "Affiliation: "
    echo "Institute of Logic and Computation, TU Wien, Austria"
}

# how to invoke your solver: this function must be customized
# these variables are taken from the environment, and they are set in Dockerfile
# that has been packaged in the container
function solver
{

    fileinput=$1    # input file with correct path

    format=$2    # format of the input file (see below)

    task=$3        # task to solve (see below)

    additional=$4    # additional information, i.e. name of an argument

    DIR=$(dirname $0)"/"
    SOLVER=$CLINGO
    SOLVEROLD=$CLINGO_OLD
    
    case $task in
        "DC-CO")
            echo ":- not in("$additional")." > "$DIR"query.lp
            echo "coneArg("$additional")." | $DIR$SOLVER - "$DIR"tools/cone_of_influence2.lp $fileinput 2>/dev/null | grep cone | sed 's/coneArg/arg/g; s/coneAtt/att/g; s/)/).\n/g' | $DIR$SOLVER - $DIR$ENCDIR/$COMENC "$DIR"query.lp 1 2>/dev/null | grep -o "UNSATISFIABLE\|SATISFIABLE"
        ;;
        "DC-PR")
            echo ":- not in("$additional")." > "$DIR"query.lp
            echo "coneArg("$additional")." | $DIR$SOLVER - "$DIR"tools/cone_of_influence2.lp $fileinput 2>/dev/null | grep cone | sed 's/coneArg/arg/g; s/coneAtt/att/g; s/)/).\n/g' | $DIR$SOLVER - $DIR$ENCDIR/$COMENC "$DIR"query.lp 1 2>/dev/null | grep -o "UNSATISFIABLE\|SATISFIABLE"
        ;;
        "DC-ST")
            echo ":- not in("$additional")." | $DIR$SOLVER - $fileinput $DIR$ENCDIR/$STBENC 2>/dev/null | grep -o "UNSATISFIABLE\|SATISFIABLE"
        ;;
        "DC-SST")
            sh $DIR/scripts/semi/heuristic_reasoning/semi_cred.sh $fileinput $additional | grep -o "UNSATISFIABLE\|SATISFIABLE"
        ;;
        "DC-STG")
            sh $DIR/scripts/stage/heuristic_reasoning/stage_cred.sh $fileinput $additional 2>/dev/null 
        ;;
        "DC-GR")
            echo ":- not in("$additional")." | $DIR$SOLVER - $fileinput $DIR$ENCDIR/$GRDENC 2>/dev/null | grep -o "UNSATISFIABLE\|SATISFIABLE"
        ;;
        "DC-ID")
            echo ":- not in("$additional")." > "$DIR"query.lp
            echo "coneArg("$additional")." | $DIR$SOLVER - "$DIR"tools/cone_of_influence2.lp $fileinput 2>/dev/null | grep cone | sed 's/coneArg/arg/g; s/coneAtt/att/g; s/)/).\n/g' | $DIR$SOLVEROLD - $DIR$ENCDIR/idealset_comp.lp "$DIR"query.lp 1 2>/dev/null | grep -o "UNSATISFIABLE\|SATISFIABLE"
        ;;
        "DS-CO")
            echo ":- in("$additional")." | $DIR$SOLVER - $fileinput $DIR$ENCDIR/$GRDENC 2>/dev/null | grep -o "UNSATISFIABLE\|SATISFIABLE"
        ;;
        "DS-PR")
	    echo ":- in("$additional")." > "$DIR"query.lp
            echo "coneArg("$additional")." | $DIR$SOLVER - "$DIR"tools/cone_of_influence2.lp $fileinput 2>/dev/null | grep cone | sed 's/coneArg/arg/g; s/coneAtt/att/g; s/)/).\n/g' | $DIR$SOLVER - $DIR$ENCDIR/sakama-rienstra.lp 1 "$DIR"query.lp 2>/dev/null | grep -o "UNSATISFIABLE\|SATISFIABLE"
        ;;
        "DS-ST")
            echo ":- in("$additional")." | $DIR$SOLVER - $fileinput $DIR$ENCDIR/$STBENC 2>/dev/null | grep -o "UNSATISFIABLE\|SATISFIABLE"
        ;;
        "DS-SST")
            sh $DIR/scripts/semi/heuristic_reasoning/semi_skept.sh $fileinput $additional | grep -o "UNSATISFIABLE\|SATISFIABLE"
        ;;
        "DS-STG")
            sh $DIR/scripts/stage/heuristic_reasoning/stage_skept.sh $fileinput $additional | grep -o "UNSATISFIABLE\|SATISFIABLE"
        ;;
        "EE-CO")
            # We use "dummy(arg)." as an easy way to identify answer sets in the clingo output. In particular for empty extensions.
            # We grep for SATISFIABLE to detect when the solver is done
			echo "["
            echo "dummy(arg). #show dummy/1." | $DIR$SOLVER - $fileinput $DIR$ENCDIR/$COMENC 0 2>/dev/null  | grep 'dummy(arg)\|SATISFIABLE' | sed 's/ dummy(arg)//; s/dummy(arg) //; s/dummy(arg)/]/; s/in(//g; s/) /,/g; s/)/]/; s/^/[/; s/\[SATISFIABLE/]/;'
        ;;
        "EE-PR")
            # We use "dummy(arg)." as an easy way to identify answer sets in the clingo output. In particular for empty extensions.
            # We grep for SATISFIABLE to detect when the solver is done
			echo "["
            echo "dummy(arg). #show dummy/1." | $DIR$SOLVER - --heuristic=Domain --enum=domRec --out-hide $fileinput $DIR$ENCDIR/$PRFENC 0 2>/dev/null | grep 'dummy(arg)\|SATISFIABLE' | sed 's/ dummy(arg)//; s/dummy(arg) //; s/dummy(arg)/]/; s/in(//g; s/) /,/g; s/)/]/; s/^/[/; s/\[SATISFIABLE/]/;'
        ;;
        "EE-ST")
             # We use "dummy(arg)." as an easy way to identify answer sets in the clingo output. In particular for empty extensions.
             # By default we do not have a linebreak after [ such that we can get [] for the empty extension set
             # When clingo outputs the "Answer: 1" line we add a linebreak and then enumerate the extensions as for the other semantics
             # We grep for both SATISFIABLE and UNSATISFIABLE to detect when the solver is done
			 printf "["
             echo "dummy(arg). #show dummy/1." | $DIR$SOLVER - $fileinput $DIR$ENCDIR/$STBENC 0 2>/dev/null | grep 'dummy(arg)\|SATISFIABLE\|Answer: 1$'| sed 's/ dummy(arg)//; s/dummy(arg) //; s/dummy(arg)/]/; s/in(//g; s/) /,/g; s/)/]/; s/^/[/; s/\[SATISFIABLE/]/; s/\[UNSATISFIABLE/]/; s/\[Answer: 1//;'
        ;;
        "EE-SST")
           # We grep for FIN to detect when the solver is done
		   echo "["
           sh "$DIR"scripts/semi/minimize/bash_semi.sh $fileinput | sed 's/in(//g; s/) /,/g; s/)/]/; s/^/[/; s/\[FIN/]/; s/\[$/\[]/'
        ;;
        "EE-STG")
            # Output is handled by the script
            sh "$DIR"scripts/stage/heuristic/stage2.sh $fileinput
        ;;
        "SE-CO")
            # We use "dummy(arg)." as an easy way to identify answer sets in the clingo output. In particular for empty extensions.
            echo "dummy(arg). #show dummy/1." | $DIR$SOLVER - $fileinput $DIR$ENCDIR/$GRDENC 2>/dev/null 
        ;;
        "SE-PR")
            # We use "dummy(arg)." as an easy way to identify answer sets in the clingo output. In particular for empty extensions.
            echo "dummy(arg). #show dummy/1." | $DIR$SOLVER - --heuristic=Domain --enum=domRec --out-hide $fileinput $DIR$ENCDIR/$PRFENC 2>/dev/null 
        ;;
        "SE-ST")
            # We use "dummy(arg)." as an easy way to identify answer sets in the clingo output. In particular for empty extensions.
            echo "dummy(arg). #show dummy/1." | $DIR$SOLVER - $fileinput $DIR$ENCDIR/$STBENC 2>/dev/null 
        ;;
        "SE-SST")
            # We use "dummy(arg)." as an easy way to identify answer sets in the clingo output. In particular for empty extensions.
            echo "dummy(arg). #show dummy/1." | $DIR$SOLVER - --heuristic=Domain --enum=domRec --out-hide $fileinput $DIR$ENCDIR/$SSTENC_HEURISTIC 2>/dev/null 
        ;;
        "SE-STG")
            # We use "dummy(arg)." as an easy way to identify answer sets in the clingo output. In particular for empty extensions.
            echo "dummy(arg). #show dummy/1." | $DIR$SOLVER - --heuristic=Domain --enum=domRec --out-hide $fileinput $DIR$ENCDIR/$STGENC_HEURISTIC 2>/dev/null 
        ;;
        "SE-GR")
            # We use "dummy(arg)." as an easy way to identify answer sets in the clingo output. In particular for empty extensions.
            echo "dummy(arg). #show dummy/1." | $DIR$SOLVER - $fileinput $DIR$ENCDIR/$GRDENC 2>/dev/null 
        ;;
        "SE-ID")
            # We use "dummy(arg)." as an easy way to identify answer sets in the clingo output. In particular for empty extensions.
            echo "dummy(arg). #show dummy/1." | $DIR$SOLVER - $DIR$ENCDIR/labBased_comp.dl $fileinput -e brave 2>/dev/null | grep 'in(' | sed 's/in(/credIn(/g; s/)/)./g' | $DIR$SOLVER - $DIR$ENCDIR/ideal-fixed-point.lp $fileinput 2>/dev/null 
        ;;
        *)
            echo "Task $task not supported"

        ;;
    esac
    
#   check whether solver returned correctly if not return with code 1
    ex=$?
    if [[ $ex != 10 ]] && [[ $ex != 20 ]] && [[ $ex != 0 ]] && [[ $ex != 30 ]] ; then
        exit 1
    fi
}



# accepted formats: please comment those unsupported
formats=""
formats="${formats} apx" # "aspartix" format
# formats="${formats} tgf" # trivial graph format

# task that are supported: please comment those unsupported

#+------------------------------------------------------------------------+
#|         I C C M A   2 0 1 9   L I S T   O F   P R O B L E M S          |
#|                                                                        |
tasks=""
tasks="${tasks} DC-CO"     # Decide credulously according to Complete semantics
tasks="${tasks} DS-CO"     # Decide skeptically according to Complete semantics
tasks="${tasks} SE-CO"     # Enumerate some extension according to Complete semantics
tasks="${tasks} EE-CO"     # Enumerate all the extensions according to Complete semantics
tasks="${tasks} DC-PR"     # Decide credulously according to Preferred semantics
tasks="${tasks} DS-PR"     # Decide skeptically according to Preferred semantics
tasks="${tasks} SE-PR"     # Enumerate some extension according to Preferred semantics
tasks="${tasks} EE-PR"     # Enumerate all the extensions according to Preferred semantics
tasks="${tasks} DC-ST"     # Decide credulously according to Stable semantics
tasks="${tasks} DS-ST"     # Decide skeptically according to Stable semantics
tasks="${tasks} SE-ST"     # Enumerate some extension according to Stable semantics
tasks="${tasks} EE-ST"     # Enumerate all the extensions according to Stable semantics
tasks="${tasks} DC-SST"     # Decide credulously according to Semi-stable semantics
tasks="${tasks} DS-SST"     # Decide skeptically according to Semi-stable semantics
tasks="${tasks} SE-SST"     # Enumerate some extension according to Semi-stable semantics
tasks="${tasks} EE-SST"     # Enumerate all the extensions according to Semi-stable semantics
tasks="${tasks} DC-STG"     # Decide credulously according to Stage semantics
tasks="${tasks} DS-STG"     # Decide skeptically according to Stage semantics
tasks="${tasks} EE-STG"     # Enumerate all the extensions according to Stage semantics
tasks="${tasks} SE-STG"     # Enumerate some extension according to Stage semantics
tasks="${tasks} DC-GR"     # Decide credulously according to Grounded semantics
tasks="${tasks} SE-GR"     # Enumerate some extension according to Grounded semantics
tasks="${tasks} DC-ID"     # Decide credulously according to Ideal semantics
tasks="${tasks} SE-ID"     # Enumerate some extension according to Ideal semantics
#|                                                                        |
#|  E N D   O F   I C C M A   2 0 1 9   L I S T   O F   P R O B L E M S   |
#+------------------------------------------------------------------------+


function list_output
{
    check_something_printed=false
    printf "["
    if [[ "$1" = "1" ]];
        then
        for format in ${formats}; do
            if [ "$check_something_printed" = true ];
            then
                printf ", "
            fi
            printf "%s" $format
            check_something_printed=true
        done
        printf "]\n"
    elif [[ "$1" = "2" ]];
        then
        for task in ${tasks}; do
            if [ "$check_something_printed" = true ];
            then
                printf ", "
            fi
            printf "%s" $task
            check_something_printed=true
        done
        printf "]\n"
    fi
}



# how to parse the output of your solver in order to be compliant with ICCMA 2019:
function parse_output()
{
    task=$1
    output=$2
    
    case "$task" in 
	EE-*) # currently unused branch
	    if [[ "$task" == "EE-ST" ]];
	    then
		TMP=`echo "${output}" | grep "in("`
		output=$TMP
		
		if [[ "$output" == "" ]];
		then
		    echo "[]"
		    return
		fi
	    fi
	    
	    if [[ "$task" == "EE-SST" ]];
	    then
		TMP=`echo "${output}" | sed 's/$/ dummy(arg)/'`
		output=$TMP
	    fi
	    
	    if [[ "$task" == "EE-STG" ]];
	    then
		echo "${output}"
		return
	    fi
# 	  
# 	    if [[ "$output" == "" ]];
# 	    then
# 		if [[ "$task" == "EE-ST" ]];
# 		then
# 		    echo "[]"
# 		else
# 		    echo "["
# 		    echo "[]"
# 		    echo "]"
# 		fi
# 	    else
		echo "["
# 		echo "${output}" | grep "dummy"
		echo "${output}" | grep "dummy(arg)" | sed 's/dummy(arg)//; s/undec([^()]*)//g ; s/ //g; s/)in(/,/g; s/in(//g; s/)//g; s/$/]/; s/^/[/'
		echo "]"
# 	    fi
	;;
	SE-*)
	    if [[ "$task" == "SE-ST" ]];
	    then
		TMP=`echo "${output}" | grep "in("`
		output=$TMP
		
		if [[ "$output" == "" ]];
		then
		    echo "NO"
		    return
		fi
	    fi	      
	    
# 	    if [[ "$output" == "" ]];
# 	    then
# 		if [[ "$task" == "SE-ST" ]];
# 		then
# 		    echo "NO"
# 		else
# 		    echo "[]"
# 		fi
# 	    else
# 		echo -n "["
	    echo "${output}" | grep "dummy(arg)" | sed 's/dummy(arg)//; s/undec([^()]*)//g; s/ //g; s/)in(/,/g; s/in(//g; s/)//g; s/$/]/; s/^/[/'

# 		echo $output | sed 's/in(//g; s/) /,/g; s/)/]/'
# 	    fi
	;;
	DC-*)
	    echo $output | sed 's/UNSATISFIABLE/NO/; s/SATISFIABLE/YES/'
	;;
	DS-*)
	    echo $output | sed 's/UNSATISFIABLE/YES/; s/SATISFIABLE/NO/'
	;;
	*)
            echoerr "unsupported format or task"
	    exit 1
        ;;
    esac
    
}




function main
{

    if [ "$#" = "0" ]
    then
        information
        exit 0
    fi

    local local_problem=""
    local local_fileinput=""
    local local_format=""
    local local_additional=""
    local local_filemod=""
    local local_task=""
    local local_task_valid=""

    while [ "$1" != "" ]; do
        case $1 in
          "--formats")
        list_output 1
        exit 0
        ;;
          "--problems")
        list_output 2
        exit 0
        ;;
          "-p")
        shift
        local_problem=$1
        ;;
          "-f")
        shift
        local_fileinput=$1
        ;;
          "-fo")
        shift
        local_format=$1
        ;;
          "-a")
        shift
        local_additional=$1
        ;;
          "-m")
        shift
        local_filemod=$1
        ;;
        esac
        shift
    done

    if [ -z $local_problem ]
    then
        echo "Task missing"
        exit 0
    else
        for local_task in ${tasks}; do
            if [ $local_task = $local_problem ]
            then
              local_task_valid="true"
            fi
        done
        if [ -z $local_task_valid ]
        then
            echo "Invalid task"
            exit 0
        fi
    fi

    if [ -z $local_fileinput ]
    then
        echo "Input file missing"
        exit 0
    fi

    if [ -z $local_filemod ]
    then
		case "$local_problem" in 
		EE-*)
            # Avoid the post processing parser for Enumeration tasks (EE-* tasks) 
            # This is necessary to allow for partial solutions
			solver $local_fileinput $local_format $local_problem $local_additional
		;;
		*)
			# All tasks but enumeration task
			res=$(solver $local_fileinput $local_format $local_problem $local_additional)
			
            # check if solver returned correctly (0), or faulty (1), in latter case don't print anything
            # This is necessary in order to deal with the timeout of ./runsolver which kills processes bottom-up,
            # ie it kills the solver before the skript (this can cause faulty output).
			ex=$?
			if [[ $ex != 0 ]]; then
				exit 1
			fi
			# If your solver output is not natively compliant with ICCMA 2019, use this function to adapt it
			parse_output $local_problem "$res"
		;;
		esac
		
		#if [[ "$local_problem" == "EE-CO" ]];
# 		if [[ "$local_problem" =~ ^EE- ]];		
# 		then
# 			solver $local_fileinput $local_format $local_problem $local_additional
# 		else
# 			res=$(solver $local_fileinput $local_format $local_problem $local_additional)
# 			
# 	#       check if solver returned correctly (0), or faulty (1), in latter case don't print anything
# 			ex=$?
# 			if [[ $ex != 0 ]]; then
# 				exit 1
# 			fi
# 			# If your solver output is not natively compliant with ICCMA 2019, use this function to adapt it
# 			parse_output $local_problem "$res"
# 		fi
	else
				
		echoerr "dynamic tasks are not supported"
	exit 1	
    fi
}

# function exit_code
# {
# echo "TRAP"
# exit 1
# }
# 
# trap exit_code SIGTERM SIGINT SIGHUP SIGQUIT SIGABRT SIGALRM

main $@
exit 0
