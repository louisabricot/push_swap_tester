#!/bin/bash

# Created by lmalki-h with <3
# Usage: ./push_swap_tester.sh [directory to push_swap and checker progs ] [stacksize 0R stacksize_min-stacksize_max ] [nb_of_test per stacksize]
# Example 1: bash visualise.sh ../push_swap/ 5 100
# Will test your program 100 times with a stack of 5 random ints
# Example 2: ./push_swap_tester.sh ../push_swap/ 3-5 50
# Will test your program 50 times with a stack of 3 random ints, then 50 times with 4 ints , then 50 times with 5 ints.

function _in {
	local e match="$1"
	shift
	for e; do [[ "$e" == "$match" ]] && return 0; done
	return 1
}

function _inv {
	local e match="$1"
	shift
	for e; do [[ "$e" == "$match" || "$e" == "$match="* ]] && return 0; done
	return 1
}

function _getv {
	local e match="$1"
	shift
	for e; do
		if [[ "$e" == "$match="* ]]; then
			echo "$(cut -d "=" -f2 <<< "$e")"
			return 0
		fi
	done
	return 1
}

FOLDER_TESTER="$(dirname "$0")"

NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'

if [[ $# -lt 3 ]] && ! ( [[ $# -ge 2 ]] && $(_inv "--retry" $@) ) \
	|| $(_inv "--help" $@) || $(_inv "-h" $@); then
	printf "${WHITE}USAGE\n${NOCOLOR}" >&2
	printf "./push_swap_tester.sh ${WHITE}[directory-to-push_swap] [stacksize 0R range] [nb_of_test] {options}\n${NOCOLOR}" >&2
	printf "\n" >&2
	printf "${WHITE}OPTIONS\n${NOCOLOR}" >&2
	printf "  ${WHITE}--show-arg${NOCOLOR}\tDisplay arguments after the number of instructions.\n" >&2
	printf "  ${WHITE}--retry${NOCOLOR}\t\tRetry with same arguments during the last run or the specified run with ${WHITE}--retry=[NUM]${NOCOLOR}.\n" >&2
	printf "  ${WHITE}--help/-h${NOCOLOR}\t\tShow this message.\n" >&2
	exit -1
fi

if [ -f push_swap_run_args.log ]; then
	NUM_LOGGED_RUN=($(grep -o '\[RUN #' push_swap_run_args.log | wc -l) + 1)
else
	NUM_LOGGED_RUN=0
fi

digit='^[0-9]+$' 		#digit number
range='^[0-9]+-[0-9]+$' #range type 

if [ -f push_swap_run_args.log ] && $(_inv "--retry" $@); then
	if [[ $(_getv "--retry" $@) != "" ]]; then
		NUM_LOGGED_RUN="$(_getv "--retry" $@)"
		if [[ ! $NUM_LOGGED_RUN =~ $digit ]]; then
			printf "${RED} error: --retry=%s value must be a positive number\n${NOCOLOR}" "$NUM_LOGGED_RUN">&2
			exit -1
		fi
	else
		NUM_LOGGED_RUN=$(($NUM_LOGGED_RUN - 1))
	fi
	TITLE=$(grep -n "\[RUN #$NUM_LOGGED_RUN \(.*\) \(.*\)" push_swap_run_args.log)
	LINE_RUN=($(echo $TITLE | cut -d: -f1))
	# 185:[RUN #8 10-22 10]
	#     1    2    3    4
	arg2="$(echo $TITLE | awk '{print $3}')"
	arg3="$(echo $TITLE | awk -F'[ \\]]' '{print $4}')"
	

	printf "${ORANGE}Retry ${NOCOLOR}" >&2
elif [ ! -f push_swap_run_args.log ] && $(_inv "--retry" $@); then
	printf "${ORANGE}Can't retry because push_swap_run_args.log not found\n${NOCOLOR}" >&2
	exit -1
else
	arg2=$2
	arg3=$3
fi
printf "${ORANGE}RUN ${WHITE}#$NUM_LOGGED_RUN${ORANGE} with args: ${WHITE}$arg2 $arg3\n${NOCOLOR}" >&2

rm -f push_swap_result.log

if [[ $arg2 =~ $range ]]; then
	startRange=$(( ${arg2%-*} + 0))
	endRange=$(( ${arg2##*-} + 0))
elif [[ $arg2 =~ $digit ]]; then
	startRange=$(( ${arg2%-*} + 0))
	endRange=$(( ${arg2##*-} + 0))
else
	printf "${RED} error: %s must be a positive number or range\n${NOCOLOR}" "$arg2">&2
	exit -1
fi

if ! [[ $arg3 =~ $digit ]]; then
	printf "${RED}error: %s must be a positive number\n${NOCOLOR}" "$arg3" >&2
	exit -1;
fi

TotalNbTest=$(($arg3 + 0))

if [[ $TotalNbTest -lt 1 ]]; then
	printf "${RED}error: %s must be a positive number\n${NOCOLOR}" "$arg3" >&2
	exit -1;
fi 

if (( $endRange < $startRange )); then
	printf "${RED}error: invalid range\n${NOCOLOR}" >&2
	exit -1
fi

if ! [[ -f "$1/push_swap" ]]; then
	printf "${RED}error: could not find push_swap in $1 \n${NOCOLOR}" >&2
	exit -1;
elif ! [[ -f "$1/checker" ]]; then
	printf "${RED}error: could not find checker in $1 \n${NOCOLOR}" >&2
	exit -1;
elif ! [[ -x "$1/push_swap" ]]; then
	printf "${RED}error: cannot execute push_swap in $1 \n${NOCOLOR}" >&2
	exit -1;
elif ! [[ -x "$1/checker" ]]; then
	printf "${RED}error: cannot execute checker in $1 \n${NOCOLOR}" >&2
	exit -1;
else
	printf "${GREEN}Testing push_swap with $TotalNbTest tests from $startRange to $endRange \n\n${NOCOLOR}" >&2
fi

if ! $(_inv "--retry" $@); then
	echo -e "[RUN #$NUM_LOGGED_RUN $arg2 $arg3]" >> push_swap_run_args.log ;
fi

global_testNB=0
for ((stack_size = $startRange; stack_size <= $endRange; stack_size++)); do
	TOTAL=0
	printf "${PURPLE} Generating random numbers for stack_size $stack_size...\n\n${NOCOLOR}"
  for ((testNB = 0; testNB < $TotalNbTest; testNB++)); do
  	global_testNB=$(($global_testNB + 1))
	if $(_inv "--retry" $@); then
		ARG=$(sed "$(($LINE_RUN + $global_testNB))!d" push_swap_run_args.log)
	else
		ARG=`$FOLDER_TESTER/genstack.pl $stack_size -1000 1000`
		echo "${ARG}" >> push_swap_run_args.log
	fi
	printf "${DARKGRAY} TEST $testNB: ${NOCOLOR}"
	"./$1/push_swap" $ARG > push_swap_result.log; exitCode=$?
	RESULT_CHECKER=`"./$1/checker" $ARG < push_swap_result.log`
	if [[ "$RESULT_CHECKER" = "KO" ]]; then
		printf "${RED}$RESULT_CHECKER ${NOCOLOR}"
	else
		printf "${GREEN}$RESULT_CHECKER ${NOCOLOR}"
	fi
	MOVES=` cat push_swap_result.log | wc -l`
	if (( $stack_size <= 3 )) ; then
		if (( $MOVES < 3 )); then
			COLOR=${WHITE}
		else
			COLOR=${RED}
		fi
	elif (( $stack_size <= 5 )) ; then
		if (( $MOVES < 8 )); then
			COLOR=${WHITE}
		elif (( $MOVES == 8 )); then
			COLOR=${BLUE}
		elif (( $MOVES < 13 )); then
			COLOR=${GREEN}
		else
			COLOR=${RED}
		fi
	elif (( $stack_size <= 100 )) ; then
		if (( $MOVES < 700 )); then
			COLOR=${WHITE}
		elif (( $MOVES < 900 )); then
			COLOR=${BLUE}
		elif (( $MOVES < 1100 )); then
			COLOR=${GREEN}
		elif (( $MOVES < 1500 )); then
			COLOR=${ORANGE}
		else
			COLOR=${RED}
		fi
	elif (( $stack_size <= 500 )) ; then
		if (( $MOVES < 5500 )); then
			COLOR=${WHITE}
		elif (( $MOVES < 7000 )); then
			COLOR=${BLUE}
		elif (( $MOVES < 8500 )); then
			COLOR=${GREEN}
		elif (( $MOVES < 11500 )); then
			COLOR=${ORANGE}
		else
			COLOR=${RED}
		fi
	fi
	printf "${COLOR} $MOVES ${NOCOLOR} instructions\n"
	if [[ "$RESULT_CHECKER" = "KO" || "$COLOR" = "$RED" \
		|| $exitCode != 0 ]] || $(_in "--show-arg" $@); then
		printf "\t arguments was: ${CYAN}$ARG${NOCOLOR}\n"
	fi
	TOTAL=$(( $TOTAL + $MOVES ))
  done
  MEAN=$(( $TOTAL / $TotalNbTest ))
  printf "\nMean: $MEAN for stack of size $stack_size \n\n"
done 

rm -rf push_swap_result.log
