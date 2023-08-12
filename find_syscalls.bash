#!/bin/env bash

# This script will find all the syscall definitions in the kernel source code
# for a given architecture and ABI.
# TODO: make this architecture independent (do this for every architecture)
# TODO: parse the syscall prototypes (for the number of parameters)
# TODO: if we really cant find a defined syscall just set it to 0 parameter

#################### CONFIGURATION ####################

# path to the linux kernel source code
LINUX_PATH="./linux"
cd $LINUX_PATH

# path to the syscall table file
ARCH_FILE="${1:-arch/x86/entry/syscalls/syscall_64.tbl}"
# architecture name (for the header path)
ARCH_NAME="${2:-x86}"
# ABI name (for the syscall table)
ABI_NAME="${3:-64}"
# valid ABIs for this architecture
TARGET_ABIS=("common" "$ABI_NAME")

#################### PARSE SYSCALL TABLE ####################

# read the table file line by line
SYS_CALLS=()
while read LINE; do
	# skip comments
	[[ $LINE =~ ^#.*$ ]] && continue

	# skip empty lines
	[[ -z $LINE ]] && continue

	# split the line into columns
	LCOLS=(${LINE})
	SYS_NUMBER=${LCOLS[0]}
	SYS_ABI=${LCOLS[1]}
	SYS_NAME=${LCOLS[2]}

	# if the syscall is not for this ABI, skip it
	[[ ! "${TARGET_ABIS[@]}" =~ "$SYS_ABI" ]] && continue

	# define SYS_ENTRY with fallback to SYS_COMPAT if needed
	SYS_ENTRY=""
	if [ -n "${LCOLS[3]}" -a "${LCOLS[3]}" != "-" ]; then
		SYS_ENTRY="${LCOLS[3]}"
	elif [ -n "${LCOLS[4]}" -a "${LCOLS[4]}" != "-" ]; then
		SYS_ENTRY="${LCOLS[4]}"
	fi

	# add the syscall to the list
	SYS_CALLS+=("$SYS_NUMBER $SYS_NAME ${SYS_ENTRY:-sys_ni_syscall}")
done < $ARCH_FILE

#################### FIND SYSCALL DECLARATIONS ####################

# find the syscall by function prototype in the header files
function find_matching_file_by_prototype {
	local SYS_ENTRY=$1
	local FILES=()
	local RESULT=0
	# this is in priority order
	VALID_HEADERS=(\
		"arch/$ARCH_NAME/"
		"include/asm-generic/"
		"include/linux/"
	)

	for HEADER_PATH in ${VALID_HEADERS[@]}; do
		# find by prototype declaration
		OUTPUT=($(\
			rg --glob '*.h' --count-matches "\basmlinkage\b.*\b$SYS_ENTRY\b\(" \
			$HEADER_PATH
		))

		for MATCH in ${OUTPUT[@]}; do
			ARR_MATCH=(${MATCH//:/ })
			FILES+=(${ARR_MATCH[0]})
			COUNT=${ARR_MATCH[1]}
			RESULT=$((RESULT+COUNT))
		done

		# stop if we found a match
		[ $RESULT -gt 0 ] && break
	done

	# print the results
	echo "${FILES[@]}"

	return $RESULT
}


# build a list of all the syscall source directories
RAW_SOURCES=$(\
	find . -maxdepth 1 -type d -not -name 'arch' -not -name '.*' \
	| tr -d './' \
	| sort
)
VALID_SOURCES=("arch/$ARCH_NAME") # in priority order
for DIRECTORY in $RAW_SOURCES; do
	if rg -q --glob '*.c' "\bSYSCALL_DEFINE.\(\w+\b" $DIRECTORY; then
		VALID_SOURCES+=($DIRECTORY)
	fi
done

# reduce the list of files if possible
function reduce_files_by_define {
	local RESULT=0
	local FILES=($(echo $1 | tr ':' ' '))
	local COUNTS=($(echo $2 | tr ':' ' '))

	# if conflict between kernel/ and um/ subdirectories, prefer kernel/
	if [[ "${FILES[@]}" =~ "/kernel/" ]] && [[ "${FILES[@]}" =~ "/um/" ]]; then
		for INDEX in ${!FILES[@]}; do
			if [[ "${FILES[$INDEX]}" =~ "/um/" ]]; then
				unset FILES[$INDEX]
				unset COUNTS[$INDEX]
			fi
		done
		FILES=(${FILES[@]})
		COUNTS=(${COUNTS[@]})
	fi

	# if nommu.c is there remove it
	if [ ${#FILES[@]} -gt 1 ] && [[ "${FILES[@]}" =~ "/nommu.c" ]]; then
		for INDEX in ${!FILES[@]}; do
			if [[ "${FILES[$INDEX]}" =~ "/nommu.c" ]]; then
				unset FILES[$INDEX]
				unset COUNTS[$INDEX]
				break
			fi
		done
		FILES=(${FILES[@]})
		COUNTS=(${COUNTS[@]})
	fi

	# recompute RESULT since we may have removed some files
	for COUNT in ${COUNTS[@]}; do
		RESULT=$((RESULT+COUNT))
	done

	# print the results
	echo "${FILES[@]}"

	return $RESULT
}

# find the syscall by syscall define in the source files
function find_matching_file_by_define {
	local SYS_ENTRY=$1
	local FILES=()
	local COUNTS=()
	local RESULT=0

	for SOURCE_PATH in ${VALID_SOURCES[@]}; do
		# find by syscall define
		OUTPUT=($(\
			rg --glob '*.c' --count-matches "\bSYSCALL_DEFINE.\($SYS_NAME\b" \
			$SOURCE_PATH
		))

		for MATCH in ${OUTPUT[@]}; do
			ARR_MATCH=(${MATCH//:/ })
			FILES+=(${ARR_MATCH[0]})
			COUNT=${ARR_MATCH[1]}
			COUNTS+=($COUNT)
			RESULT=$((RESULT+COUNT))
		done

		# try and zero in on a unique file if needed
		if [ ${#FILES[@]} -gt 1 ]; then
			FILES_ARG="$(echo ${FILES[@]} | tr ' ' ':')"
			COUNTS_ARG="$(echo ${COUNTS[@]} | tr ' ' ':')"
			FILES=($(reduce_files_by_define "$FILES_ARG" "$COUNTS_ARG"))
			RESULT=$?
		fi

		# stop if we found a match
		[ $RESULT -gt 0 ] && break
	done

	# print the results
	echo "${FILES[@]}"

	return $RESULT
}

# get the full syscall prototype
function get_details_by_prototype {
	local SYS_ENTRY=$1
	local FILE=$2

	# get the full prototype
	rg -U "\basmlinkage\b.*\b$SYS_ENTRY\b\((?s).*?\);" $FILE
}

# get the full syscall define
function get_details_by_define {
	local SYS_NAME=$1
	local FILE=$2

	# get the full define
	rg -U "\bSYSCALL_DEFINE.\($SYS_NAME\b(?s).*?\)" $FILE
}

# find all the syscall prototypes
UNIQUE_COUNT=0
NOT_IMPLEMENTED_COUNT=0
NOT_FOUND_COUNT=0
MULTIPLE_COUNT=0
#DETAILS_ARR=()	#TEMP
for SYSCALL in "${SYS_CALLS[@]}"; do
	# split syscall line into columns
	SCOLS=(${SYSCALL})
	SYS_NUMBER=${SCOLS[0]}
	SYS_NAME=${SCOLS[1]}
	SYS_ENTRY=${SCOLS[2]}

	# find the syscall file
	RESULT=0
	METHOD=""
	if [ $SYS_ENTRY != "sys_ni_syscall" ]; then
		FILES=($(find_matching_file_by_prototype $SYS_ENTRY))
		RESULT=$?
		METHOD="prototype"

		# if we didn't get a unique syscall, try to find one by syscall define
		if [ $RESULT -ne 1 ]; then
			FILES2="$(find_matching_file_by_define $SYS_NAME)"
			RESULT2=$?

			# if we found a unique syscall or if there was no syscall
			if [ $RESULT2 -eq 1 ] || [ $RESULT -eq 0 -a $RESULT2 -ne 0 ]; then
				FILES=($FILES2)
				RESULT=$RESULT2
				METHOD="define"
			fi
		fi

		#TEMP: TODO: uncomment
		# check if we found multiple files (this should never happen)
		#if [ ${#FILES[@]} -gt 1 ]; then
		#	echo "ERROR: $SYS_NUMBER $SYS_NAME: unexpected multiple file matches"
		#	for FILE in ${FILES[@]}; do
		#		echo "  $FILE"
		#	done
		#	exit 1
		#fi
	fi

	# get details about the syscall
	DETAILS=""
	if [ $RESULT -eq 1 -a ${#FILES[@]} -eq 1 ]; then
		if [ $METHOD = "prototype" ]; then
			DETAILS=$(get_details_by_prototype $SYS_ENTRY ${FILES[0]})
		else
			DETAILS=$(get_details_by_define $SYS_NAME ${FILES[0]})
			#DETAILS_ARR+=("$DETAILS")	#TEMP
		fi

		# check if we actually got the details
		if [ $? -ne 0 -o -z "$DETAILS" ]; then
			echo -n "ERROR: $SYS_NUMBER $SYS_NAME: "
			echo "unexpected get_details_by_$METHOD failure"
			exit 1
		fi
	fi

	# count errors and found syscalls
	if [ $SYS_ENTRY = "sys_ni_syscall" ]; then
		NOT_IMPLEMENTED_COUNT=$((NOT_IMPLEMENTED_COUNT+1))
	elif [ $RESULT -eq 0 ]; then
		NOT_FOUND_COUNT=$((NOT_FOUND_COUNT+1))
		echo "$SYS_NUMBER $SYS_NAME $SYS_ENTRY() not found"
	elif [ $RESULT -eq 1 ]; then
		UNIQUE_COUNT=$((UNIQUE_COUNT+1))
	elif [ $RESULT -gt 1 ]; then
		MULTIPLE_COUNT=$((MULTIPLE_COUNT+1))
		echo "$SYS_NUMBER $SYS_NAME $SYS_ENTRY() multiple matches ($RESULT by '$METHOD')"
		for FILE in ${FILES[@]}; do
			echo "  $FILE"
		done
	else
		# this should never happen
		echo "ERROR: $SYS_NUMBER $SYS_NAME $SYS_ENTRY(): unexpected result ($RESULT)"
		exit 1
	fi
done

#################### PRINT RESULTS ####################

# print the results
echo
echo "Unique definition: $UNIQUE_COUNT/${#SYS_CALLS[@]}"
echo "Not implemented: $NOT_IMPLEMENTED_COUNT/${#SYS_CALLS[@]}"
echo "Not found: $NOT_FOUND_COUNT/${#SYS_CALLS[@]}"
echo "Multiple definitions: $MULTIPLE_COUNT/${#SYS_CALLS[@]}"

#TEMP
#echo
#for DETAILS in "${DETAILS_ARR[@]}"; do
#	echo "$DETAILS"
#done
