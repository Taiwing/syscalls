#!/bin/env bash

# This script iterates over all syscall tables in the linux kernel source code
# and calls find_syscalls.bash for each architecture and ABI pair possible.

# arguments:
# 1. target architecture
# 2. target ABI
ARCH_NAME_ARG="$1"
ABI_NAME_ARG="$2"
ABI_NAME_ARG_OLD=""

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

	# if the architecture is specified, skip all others
	if [ ! -z "$ARCH_NAME_ARG" ] && [ "$ARCH_NAME_ARG" != "$ARCH_NAME" ]; then
		continue
	fi

	# list every ABI in the table
	ABI_NAMES=($(grep -v '^#' < $TABLE_FILE | grep -v '^$' | awk '{print $2}' | sort | uniq))

	# if there is more than two ABIs remove common
	if [ ${#ABI_NAMES[@]} -gt 2 ]; then
		ABI_NAMES=($(echo "${ABI_NAMES[@]}" | sed 's/common//'))
	fi

	# handle special cases
	if [ "${ARCH_FILE}" == "arch/arm/tools/syscall.tbl" ]; then
		# this one is not in the list (every common is therefore eabi)
		ABI_NAMES+=("eabi")
	elif [ "${ARCH_FILE}" == "arch/mips/kernel/syscalls/syscall_n64.tbl" ]; then
		# here common is forcibly removed because there is an error in the table
		ABI_NAMES=($(echo "${ABI_NAMES[@]}" | sed 's/common//'))
	elif [ "${ARCH_FILE}" == "arch/powerpc/kernel/syscalls/syscall.tbl" \
		-a "${ABI_NAME_ARG}" != "spu" ]; then
		# remove nospu
		ABI_NAMES=($(echo "${ABI_NAMES[@]}" | sed 's/nospu//'))

		if [ "${ABI_NAME_ARG}" == "nospu" ]; then
			# remove only spu
			ABI_NAMES=($(echo "${ABI_NAMES[@]}" | sed 's/spu//'))
			ABI_NAME_ARG_OLD="$ABI_NAME_ARG"
			ABI_NAME_ARG=""
		elif [ "${ABI_NAME_ARG}" == "64" -o "${ABI_NAME_ARG}" == "32" ]; then
			# add nospu
			ABI_NAME_ARG_OLD="$ABI_NAME_ARG"
			ABI_NAME_ARG="nospu ${ABI_NAME_ARG}"
		fi

		# merge nospu with 32 and 64 respectively
		for INDEX in ${!ABI_NAMES[@]}; do
			TMP="${ABI_NAMES[$INDEX]}"
			if [ "$TMP" = "32" -o "$TMP" = "64" ]; then
				ABI_NAMES[$INDEX]="nospu ${ABI_NAMES[$INDEX]}"
			fi
		done
	fi

	# print the parameters and find syscalls
	for ABI_NAME in "${ABI_NAMES[@]}"; do
		# if the ABI is specified, skip all others
		if [ ! -z "$ABI_NAME_ARG" ] && [ "$ABI_NAME_ARG" != "$ABI_NAME" ]; then
			continue
		fi

		# print script parameters
		echo
		echo ------------------------------------------------------------
		echo
		echo "ARCH_FILE=\"$ARCH_FILE\""
		echo "ARCH_NAME=\"$ARCH_NAME\""
		echo "ABI_NAME=\"$ABI_NAME\""
		echo

		# get the syscalls
		./find_syscalls.bash "$ARCH_FILE" "$ARCH_NAME" "$ABI_NAME"
	done

	# restore ABI_NAME_ARG if it was changed
	if [ ! -z "$ABI_NAME_ARG_OLD" ]; then
		ABI_NAME_ARG="$ABI_NAME_ARG_OLD"
		ABI_NAME_ARG_OLD=""
	fi
done
