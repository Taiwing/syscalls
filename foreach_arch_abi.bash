#!/bin/env bash

# This script iterates over all syscall tables in the linux kernel source code
# and calls find_syscalls.bash for each architecture and ABI pair possible.

# path to the linux kernel source code
LINUX_PATH="./linux"

# path to the syscall tables
TABLE_FILES=$(find ${LINUX_PATH}/arch -type f -name 'syscall*.tbl')

# read the syscall tables
for TABLE_FILE in ${TABLE_FILES}; do
	# remove linux path
	ARCH_FILE=${TABLE_FILE:${#LINUX_PATH}+1}

	# extract the architecture and the table name
	[[ $TABLE_FILE =~ arch/([^/]*)/.*syscall_*(.*)\.tbl ]]
	ARCH_NAME="${BASH_REMATCH[1]}"

	# list every ABI in the table
	ABI_NAMES=($(grep -v '^#' < $TABLE_FILE | grep -v '^$' | awk '{print $2}' | sort | uniq))

	# handle special cases
	if [ ${#ABI_NAMES[@]} -eq 2 ]; then
		if [ "${ARCH_FILE}" == "arch/arm/tools/syscall.tbl" ]; then
			# this one is not in the list (every common is therefore eabi)
			ABI_NAMES+=("eabi")
		elif [ "${ARCH_FILE}" == "arch/mips/kernel/syscalls/syscall_n64.tbl" ]; then
			# here common is removed because there seems to be an error in the table
			ABI_NAMES=($(echo "${ABI_NAMES[@]}" | sed 's/common//'))
		fi
	fi

	# if there is more than two ABIs remove common
	if [ ${#ABI_NAMES[@]} -gt 2 ]; then
		ABI_NAMES=($(echo "${ABI_NAMES[@]}" | sed 's/common//'))
	fi

	# print the parameters and find syscalls
	for ABI_NAME in "${ABI_NAMES[@]}"; do
		echo
		echo ------------------------------------------------------------
		echo ARCH_FILE="$ARCH_FILE"
		echo ARCH_NAME="$ARCH_NAME"
		echo ABI_NAME="$ABI_NAME"
		echo
		./find_syscalls.bash "$ARCH_FILE" "$ARCH_NAME" "$ABI_NAME"
	done
done
