#!/usr/bin/env bash

# Generate a table file for each architecture and ABI pair that do not already
# have one. For this use the generic table as a base and specific unistd.h
# headers to override it. The available ABIs are determined by parsing the
# Kconfig files.

################################################################################
# Configuration
################################################################################

# set the path to the root of the git repository
ROOT="$(git rev-parse --show-toplevel)"

# path to the linux kernel source code
LINUX_PATH="${ROOT}/linux"
cd $LINUX_PATH

################################################################################
# Functions
################################################################################

# get the list of architectures without a table file
list_notable_archs() {
	for ARCH in $(ls -d arch/*/); do
		HAS_TABLE=$(find $ARCH -name '*syscall*.tbl' -type f | wc -l)
		# skip uml as it is a special case
		if [ $HAS_TABLE -eq 0 ] && [ $ARCH != "arch/um/" ]; then
			echo $ARCH | sed -E 's/^arch\/(\w+)\/$/\1/'
		fi
	done
}

# get the list of ABIs for a given architecture
# note: It works but it is a bit hacky right now. There might be a better way
# to do this without hardcoding the ABIs but I just don't know it yet.
function get_arch_abis() {
	local ABIS=()
	local ARCH_NAME=$1
	local KCONFIG_FILE="arch/$ARCH_NAME/Kconfig"

	# Kconfig file does not exist (this should not happen)
	[ ! -f $KCONFIG_FILE ] && echo ERROR: no Kconfig file for $ARCH_NAME \
		&& exit 1

	# look for ARCH_32BIT_OFF_T select statement
	if grep -E "select ARCH_32BIT_OFF_T" $KCONFIG_FILE > /dev/null 2>&1; then
		ABIS+=("32")
	else
		#look for 32BIT config
		grep -E "config 32BIT" $KCONFIG_FILE > /dev/null 2>&1 && ABIS+=("32")

		#look for 64BIT config
		grep -E "config 64BIT" $KCONFIG_FILE > /dev/null 2>&1 && ABIS+=("64")
	fi

	# print the results
	echo "${ABIS[@]}"
}

################################################################################
# Main
################################################################################

main() {
	ARCHS=($(list_notable_archs))

	declare -A ABIS
	for ARCH in "${ARCHS[@]}"; do
		# add arch to abis dict
		ABIS[$ARCH]=$(get_arch_abis $ARCH)
	done

	# generate the table files
	cd - > /dev/null
	cd $ROOT > /dev/null
	for ARCH in "${!ABIS[@]}"; do
		# if there is only one ABI
		if [ $(echo ${ABIS[$ARCH]} | wc -w) -lt 2 ]; then
			./build/generate_table.bash $ARCH common ${ABIS[$ARCH]} yes
		else
			for ABI in ${ABIS[$ARCH]}; do
				./build/generate_table.bash $ARCH $ABI $ABI ""
			done
		fi
	done
}

main
