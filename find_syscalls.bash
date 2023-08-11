#!/bin/env bash

# This script will find all the syscall definitions in the kernel source code.
# TODO: make this architecture independent (do this for every architecture)
# TODO: only look for headers and see if the results are the same in case of
# multiple matches and in proper priority order
# TODO: then look for the SYSCALL_DEFINE if the prototype is not found

# header priority:
# arch/<arch>/include/*
# include/asm-generic/*
# include/linux/*

#################### CONFIGURATION ####################

# path to the linux kernel source code
LINUX_PATH="./linux"
cd $LINUX_PATH

# path to the syscall table file
ARCH_FILE="arch/x86/entry/syscalls/syscall_64.tbl"
# architecture name (for the header path)
ARCH_NAME="x86"
# ABI name (for the syscall table)
ABI_NAME="64"
# valid ABIs for this architecture
VALID_ABIS=("common" "$ABI_NAME")

#################### PARSE SYSCALL TABLE ####################

# read the table file line by line
SYS_CALLS=()
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

#################### FIND SYSCALL DECLARATIONS ####################

# find all the syscall prototypes
UNIQUE_COUNT=0
NOT_IMPLEMENTED_COUNT=0
NOT_FOUND_COUNT=0
MULTIPLE_COUNT=0
for SYSCALL in "${SYS_CALLS[@]}"; do
	# split syscall line into columns
	read -a SCOLS <<< $SYSCALL

	# find the syscall declarations
	RESULT=0
	if [ ${SCOLS[2]} != "sys_ni_syscall" ]; then
		# find by prototype declaration
		OUTPUT=$(rg --glob '*.h' --count-matches "\basmlinkage\b.*\b${SCOLS[2]}\b\(" | cut -d':' -f2)
		# find by SYSCALL_DEFINE
		#OUTPUT=$(rg --glob '*.c' --count-matches "\bSYSCALL_DEFINE.\(${SCOLS[1]}\b" | cut -d':' -f2)

		# sum the results
		for COUNT in $OUTPUT; do
			RESULT=$((RESULT+COUNT))
		done
	fi

	# count errors and found syscalls
	if [ ${SCOLS[2]} = "sys_ni_syscall" ]; then
		NOT_IMPLEMENTED_COUNT=$((NOT_IMPLEMENTED_COUNT+1))
	elif [ $RESULT -eq 0 ]; then
		NOT_FOUND_COUNT=$((NOT_FOUND_COUNT+1))
		echo "${SCOLS[0]} ${SCOLS[1]} not found (${SCOLS[2]})"
	elif [ $RESULT -eq 1 ]; then
		UNIQUE_COUNT=$((UNIQUE_COUNT+1))
	elif [ $RESULT -gt 1 ]; then
		MULTIPLE_COUNT=$((MULTIPLE_COUNT+1))
		echo "${SCOLS[0]} ${SCOLS[1]} multiple matches ($RESULT)"
	else
		echo "ERROR: unexpected result ($RESULT)"
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
