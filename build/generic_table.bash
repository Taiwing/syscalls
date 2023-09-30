#!/usr/bin/env bash

# This script is used to generate a table file for the linux generic
# architecures.

################################################################################
# Configuration
################################################################################

# set the path to the root of the git repository
ROOT="$(git rev-parse --show-toplevel)"

# path to the linux kernel source code
LINUX_PATH="${ROOT}/linux"
cd $LINUX_PATH

# architecture to build for
ARCH_NAME="generic"
# bitness of the architecture ("abi")
ABI_NAME="${1:-64}"
# architecture and abi combined
ARCH_ABI="${ARCH_NAME}_${ABI_NAME}"
# path to the output file
OUTPUT_FILE="${ARCH_NAME}_${ABI_NAME}.tbl"

# path to the generic table source file
TABLE_SOURCE="include/uapi/asm-generic/unistd.h"
FLAT_PATH_FILE="$(echo $TABLE_SOURCE | tr '/' '_')"
NO_INCLUDE_FILE="tmp_${ARCH_ABI}_no_include_${FLAT_PATH_FILE}"
PREPROCESSED_FILE="tmp_${ARCH_ABI}_preprocessed_${FLAT_PATH_FILE}"

################################################################################
# Functions
################################################################################

# clean up the output directory
function cleanup {
	rm -f tmp_${ARCH_ABI}_*
}

# remove include statements
remove_includes() {
	local SOURCE_FILE="$1"

	tail -n '+33' "$SOURCE_FILE"
}

# preprocess the file according to the architecture
preprocess() {
	local SRC="$1"
	local ARCH="$2"
	local TMP_DEFS="tmp_${ARCH_ABI}_defs.h"
	local TMP_SRC="tmp_${ARCH_ABI}_src.h"
	local TMP_SRC2="tmp_${ARCH_ABI}_src2.h"
	# add defines to get as many syscalls as possible
	local GCC_OPTIONS="-D__BITS_PER_LONG=${ARCH}"
	GCC_OPTIONS="$GCC_OPTIONS -D__ARCH_WANT_MEMFD_SECRET"
	GCC_OPTIONS="$GCC_OPTIONS -D__ARCH_WANT_NEW_STAT"
	GCC_OPTIONS="$GCC_OPTIONS -D__ARCH_WANT_RENAMEAT"
	GCC_OPTIONS="$GCC_OPTIONS -D__ARCH_WANT_SET_GET_RLIMIT"
	GCC_OPTIONS="$GCC_OPTIONS -D__ARCH_WANT_STAT64"
	GCC_OPTIONS="$GCC_OPTIONS -D__ARCH_WANT_SYS_CLONE3"
	GCC_OPTIONS="$GCC_OPTIONS -D__ARCH_WANT_TIME32_SYSCALLS"

	cat <<EOF > "${TMP_DEFS}"
#define __SYSCALL(x, y)						row: x ${ARCH} #x y
#define __SC_COMP(x, y, z)					row: x ${ARCH} #x y
#define __SC_3264(x, y_32, y_64)			row: x ${ARCH} #x y_${ARCH}
#define __SC_COMP_3264(x, y_32, y_64, z)	row: x ${ARCH} #x y_${ARCH}
#define ALIAS(x, y)							alias: #y #x
EOF

	# prepend the __SYSCALL_ macros to the file
	cat "$TMP_DEFS" "$SRC" > "$TMP_SRC"

	# create ALIAS statements to get the real syscall names
	rg '^#define\s+(__NR_\w+)\s+(__NR3264_\w+)$' "$TMP_SRC" -r 'ALIAS($1, $2)' --passthru > "$TMP_SRC2"

	# preprocess the file
	gcc -E $GCC_OPTIONS "$TMP_SRC2"
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

	# remove include statements
	remove_includes "$TABLE_SOURCE" > "$NO_INCLUDE_FILE"

	# preprocess the file according to the architecture
	preprocess "$NO_INCLUDE_FILE" "$ABI_NAME" \
		| grep -v -e '^#' -e '^$' > "$PREPROCESSED_FILE"

	# create table file
	create_table "$PREPROCESSED_FILE" > "$OUTPUT_FILE"
}

main
