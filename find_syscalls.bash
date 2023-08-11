#!/bin/env bash

# This script will find all the syscall definitions in the kernel source code.
# TODO: make this architecture independent (do this for every architecture)

# path to the linux kernel source code
LINUX_PATH="./linux"

# list of all the x86 64bit syscalls
ARCH_FILE="${LINUX_PATH}/arch/x86/entry/syscalls/syscall_64.tbl"
VALID_ABIS=("common" "64")
SYS_CALLS=()

# read the file line by line
while read LINE; do
    # skip comments
    [[ $LINE =~ ^#.*$ ]] && continue

    # skip empty lines
    [[ -z $LINE ]] && continue

    # split the line into columns
    read -a LCOLS <<< $LINE

	# if the ABI is not valid, skip it
    [[ ! "${VALID_ABIS[@]}" =~ "${LCOLS[1]}" ]] && continue

    # add the syscall to the list
    SYS_CALLS+=("${LCOLS[0]} ${LCOLS[2]} ${LCOLS[3]:-sys_ni_syscall}")
done < $ARCH_FILE

UNIQUE_COUNT=0
MULTIPLE_COUNT=0
NOT_IMPLEMENTED_COUNT=0
NOT_FOUND_COUNT=0
# find all the syscall definitions
for SYSCALL in "${SYS_CALLS[@]}"; do
	# split syscall line into columns
	read -a SCOLS <<< $SYSCALL

	# find the syscall definitions
	OUTPUT=$(rg --count-matches "\bSYSCALL_DEFINE.\(${SCOLS[1]}\b" | cut -d':' -f2)

	# sum the results
	RESULT=0
	for COUNT in $OUTPUT; do
		RESULT=$((RESULT+COUNT))
	done

	# count errors and found syscalls
	if [ $RESULT -eq 1 ]; then
		UNIQUE_COUNT=$((UNIQUE_COUNT+1))
	elif [ $RESULT -gt 1 ]; then
		MULTIPLE_COUNT=$((MULTIPLE_COUNT+1))
		echo "${SCOLS[0]} ${SCOLS[1]} multiple matches ($RESULT)"
	elif [ $RESULT -eq 0 ]; then
		if [ ${SCOLS[2]} = "sys_ni_syscall" ]; then
			NOT_IMPLEMENTED_COUNT=$((NOT_IMPLEMENTED_COUNT+1))
		else
			NOT_FOUND_COUNT=$((NOT_FOUND_COUNT+1))
			echo "${SCOLS[0]} ${SCOLS[1]} not found (${SCOLS[2]})"
		fi
	fi
done

# print the results
echo "Unique definition: $UNIQUE_COUNT/${#SYS_CALLS[@]}"
echo "Multiple definitions: $MULTIPLE_COUNT/${#SYS_CALLS[@]}"
echo "Not implemented: $NOT_IMPLEMENTED_COUNT/${#SYS_CALLS[@]}"
echo "Not found: $NOT_FOUND_COUNT/${#SYS_CALLS[@]}"
