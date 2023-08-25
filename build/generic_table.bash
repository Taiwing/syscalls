#!/bin/env bash

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
# path to the output directory
OUTPUT_DIR=".."
# path to the output file
OUTPUT_FILE="${OUTPUT_DIR}/${ARCH_NAME}_${ABI_NAME}.tbl"

# path to the generic table source file
TABLE_SOURCE="include/uapi/asm-generic/unistd.h"
FLAT_PATH_FILE="$(echo $TABLE_SOURCE | tr '/' '_')"
NO_INCLUDE_FILE="${OUTPUT_DIR}/tmp_${ARCH_ABI}_no_include_${FLAT_PATH_FILE}"
PREPROCESSED_FILE="${OUTPUT_DIR}/tmp_${ARCH_ABI}_preprocessed_${FLAT_PATH_FILE}"

################################################################################
# Functions
################################################################################

# remove include statements
remove_includes() {
	local SOURCE_FILE="$1"

	tail -n '+33' "$SOURCE_FILE"
}

# preprocess the file according to the architecture
preprocess() {
	local SRC="$1"
	local ARCH="$2"
	#local GCC_OPTIONS="-D__BITS_PER_LONG=${ARCH} -D__SYSCALL=__SYSCALL_${ARCH}"
	local GCC_OPTIONS="-D__BITS_PER_LONG=${ARCH} -D__ARCH_WANT_NEW_STAT"
	local TMP_DEFS="${OUTPUT_DIR}/tmp_defs_${ARCH_ABI}.h"
	local TMP_SRC="${OUTPUT_DIR}/tmp_src_${ARCH_ABI}.h"
	local TMP_SRC2="${OUTPUT_DIR}/tmp_src2_${ARCH_ABI}.h"

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

################################################################################
# Main
################################################################################

main() {
	# remove include statements
	remove_includes "$TABLE_SOURCE" > "$NO_INCLUDE_FILE"

	# preprocess the file according to the architecture
	preprocess "$NO_INCLUDE_FILE" "$ABI_NAME" \
		| grep -v -e '^#' -e '^$' > "$PREPROCESSED_FILE"
}

main
