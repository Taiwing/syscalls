#!/usr/bin/env bash

# This script is used to generate a table file for the architectures that do
# not have one in the linux kernel source code. It uses the generic unistd.h as
# a base and includes the architecture specific unistd.h files to get the full
# list of syscalls. In the case of the generic architecture dummy headers are
# used to compile the generic unistd.h file. Macros are added so that every
# possible syscall is included in the table.

# The output is a table file that can be used by the syscall table generator
# to generate the syscall table for the architecture.

################################################################################
# Configuration
################################################################################

# set the path to the root of the git repository
ROOT="$(git rev-parse --show-toplevel)"

# path to the linux kernel source code
LINUX_PATH="${ROOT}/linux"
cd $LINUX_PATH

# architecture name
ARCH_NAME="${1}"
# ABI name
ABI_NAME="${2}"
# architecture bitness
ARCH_BITNESS="${3}"
# architecture only
ARCH_ONLY="${4}"
# architecture and abi combined
ARCH_ABI="${ARCH_NAME}_${ABI_NAME}"
# path to the output directory
OUTPUT_DIR="tbl"
mkdir -p $OUTPUT_DIR
# path to the output file
OUTPUT_FILE="${OUTPUT_DIR}/${ARCH_NAME}_${ABI_NAME}.tbl"
# if ARCH_ONLY (when theres only one ABI)
[ ! -z "$ARCH_ONLY" ] && OUTPUT_FILE="${OUTPUT_DIR}/${ARCH_NAME}.tbl"

# path to the generic table source file
GENERIC_SOURCE="include/uapi/asm-generic/unistd.h"
FLAT_PATH_FILE="$(echo $GENERIC_SOURCE | tr '/' '_')"
HEADLESS_GENERIC_FILE="tmp_${ARCH_ABI}_headless_${FLAT_PATH_FILE}"
PREPROCESSED_FILE="tmp_${ARCH_ABI}_preprocessed_${FLAT_PATH_FILE}"
TMP_INCLUDE_DIR="tmp_${ARCH_ABI}_include_dir"
TMP_ASM_PATH="${TMP_INCLUDE_DIR}/asm"
TMP_UAPI_ASM_PATH="${TMP_INCLUDE_DIR}/uapi/asm"
TMP_ASM_GENERIC_PATH="${TMP_INCLUDE_DIR}/asm-generic"

################################################################################
# Functions
################################################################################

# clean up the output directory
function cleanup {
	rm -rf tmp_${ARCH_ABI}_*
}

# remove generic header first lines (includes and SYSCALL macro definitions)
remove_head() {
	local SOURCE_FILE="$1"

	tail -n '+33' "$SOURCE_FILE"
}

# put our own syscall macro definitions in the file
replace_macros() {
	local SOURCE_FILE="$1"
	local ARCH="$2"
	local BITNESS="$3"

	# add our own defines:
	# - __BITS_PER_LONG: the bitness of the architecture
	# - __ALIAS: get the real syscall name
	# - __S*: every syscall macro creates a table row formatted as follows:
	#   - syscall number
	#   - ABI (which is the bitness of the architecture in this case)
	#   - syscall name (with the __NR_ prefix)
	#   - syscall entry point
	# note: a dollar sign and double parenthesis has been added to the syscall
	# number to perform the eventual computation yielded by the macro (eval)
	cat <<EOF
#define __BITS_PER_LONG						${BITNESS}
#define __SYSCALL(x, y)						row: \$((x)) ${BITNESS} #x y
#define __SC_COMP(x, y, z)					row: \$((x)) ${BITNESS} #x y
#define __SC_3264(x, y_32, y_64)			row: \$((x)) ${BITNESS} #x y_${BITNESS}
#define __SC_COMP_3264(x, y_32, y_64, z)	row: \$((x)) ${BITNESS} #x y_${BITNESS}
#define ALIAS(x, y)							alias: #y #x
EOF

	# add every optional syscall to get the complete generic table
	if [ "$ARCH" = "generic" ]; then
cat <<EOF
#define __ARCH_WANT_MEMFD_SECRET
#define __ARCH_WANT_NEW_STAT
#define __ARCH_WANT_RENAMEAT
#define __ARCH_WANT_SET_GET_RLIMIT
#define __ARCH_WANT_STAT64
#define __ARCH_WANT_SYS_CLONE3
#define __ARCH_WANT_TIME32_SYSCALLS
EOF
	fi

	# append the rest of the file wth ALIAS statements
	rg '^#define\s+(__NR_\w+)\s+(__NR3264_\w+)$' "${SOURCE_FILE}" \
		-r 'ALIAS($1, $2)' --passthru
}

# preprocess the file according to the architecture
preprocess() {
	local ARCH="$1"
	local HEADER=""

	# search the uapi/asm/unistd.h header file
	HEADER="arch/${ARCH}/include/uapi/asm/unistd.h"
	if [ -f "$HEADER" ]; then
		cp "$HEADER" "$TMP_UAPI_ASM_PATH"
	else
		echo '#include <asm-generic/unistd.h>' > "$TMP_UAPI_ASM_PATH/unistd.h"
	fi

	# search the asm/unistd.h header file
	HEADER="arch/${ARCH}/include/asm/unistd.h"
	if [ -f "$HEADER" ]; then
		cp "$HEADER" "$TMP_ASM_PATH"
	else
		echo '#include <uapi/asm/unistd.h>' > "$TMP_ASM_PATH/unistd.h"
	fi

	# preprocess the file
	gcc -E -nostdinc -I "$TMP_INCLUDE_DIR" "$TMP_ASM_PATH/unistd.h"
}

create_table() {
	local SRC="$1"
	declare -A ALIAS

	# load alias map
	while read -r LINE; do
		ARR=($(eval echo $LINE))
		ALIAS[${ARR[0]}]="${ARR[1]}"
	done < <(grep '^alias:' "$SRC" | sed -e 's/^alias: //')

	# create row file
	while read -r LINE; do
		ARR=($(eval echo $LINE))
		NAME="${ARR[2]}"
		NAME="${ALIAS[$NAME]:-$NAME}"
		NAME="${NAME//__NR_/}"
		echo "${ARR[0]} ${ARR[1]} ${NAME} ${ARR[3]}"
	done < <(grep '^row:' "$SRC" | sed -e 's/^row: //')
}

################################################################################
# Main
################################################################################

main() {
	# setup cleanup function
	trap cleanup EXIT

	# remove start of generic table source file
	remove_head "$GENERIC_SOURCE" > "$HEADLESS_GENERIC_FILE"

	# replace syscall macros
	mkdir -p "$TMP_ASM_GENERIC_PATH"
	replace_macros "$HEADLESS_GENERIC_FILE" "$ARCH_NAME" "$ARCH_BITNESS" \
		> "$TMP_ASM_GENERIC_PATH/unistd.h"

	# preprocess the header file according to the architecture
	mkdir -p "$TMP_ASM_PATH"
	mkdir -p "$TMP_UAPI_ASM_PATH"
	preprocess "$ARCH_NAME" | grep -v -e '^#' -e '^$' > "$PREPROCESSED_FILE"

	# create table file
	create_table "$PREPROCESSED_FILE" | sort -n > "$OUTPUT_FILE"
}

main
