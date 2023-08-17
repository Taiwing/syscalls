#!/bin/env bash

# This script is used to create an ansi C table from a csv file.
# The csv file must have the following format:
#   - The first line must be the header
#   - The first column is the index
#   - The second column is the name
#   - The third column is skipped
#   - The fourth column is the return_type
#   - The fifth column is skipped
#   - The sixth column to the end are the arguments
# The script will generate a file called syscall_table_${ARCH_ABI}.c
# The script will also generate a file called syscall_table_${ARCH_ABI}.h

################################################################################
# Configuration
################################################################################

# the csv file
CSV_FILE="$1"
# the architecture
ARCH_ABI="${CSV_FILE%.*}"
UPPER_ARCH_ABI="$(echo "$ARCH_ABI" | tr '[:lower:]' '[:upper:]')"
# the output file
OUTPUT_FILE="syscall_table_${ARCH_ABI}.c"
# the header file
HEADER_FILE="syscall_table_${ARCH_ABI}.h"

################################################################################
# Create the output files
################################################################################

# create the output file
echo "#include \"syscalls.h\"" > "$OUTPUT_FILE"
echo >> "$OUTPUT_FILE"
echo -n "const t_syscall_entry	${ARCH_ABI}_" >> "$OUTPUT_FILE"
echo -n "syscall_table[${UPPER_ARCH_ABI}_SYSCALL_TABLE_SIZE]" >> "$OUTPUT_FILE"
echo "= {" >> "$OUTPUT_FILE"

################################################################################
# Read the csv file
################################################################################

# read the csv file
MAX_INDEX=0
while read LINE; do
	# skip the first line
	[[ "$LINE" =~ "nr,name," ]] && continue

	# split the line on commas
	IFS=',' read -r -a ARRAY <<< "$LINE"

	# get the syscall information
	INDEX="${ARRAY[0]}"
	NAME="${ARRAY[1]}"
	RETURN_TYPE="${ARRAY[3]:-TLINT}"
	ARG1="${ARRAY[5]:-TNONE}"
	ARG2="${ARRAY[6]:-TNONE}"
	ARG3="${ARRAY[7]:-TNONE}"
	ARG4="${ARRAY[8]:-TNONE}"
	ARG5="${ARRAY[9]:-TNONE}"
	ARG6="${ARRAY[10]:-TNONE}"

	# update MAX_INDEX
	[ $INDEX -gt $MAX_INDEX ] && MAX_INDEX=$INDEX

	# write the syscall information
	echo -n "	[$INDEX] = {" >> "$OUTPUT_FILE"
	echo -n " \"$NAME\"" >> "$OUTPUT_FILE"
	echo -n ", $RETURN_TYPE" >> "$OUTPUT_FILE"
	echo -n ", $ARG1" >> "$OUTPUT_FILE"
	echo -n ", $ARG2" >> "$OUTPUT_FILE"
	echo -n ", $ARG3" >> "$OUTPUT_FILE"
	echo -n ", $ARG4" >> "$OUTPUT_FILE"
	echo -n ", $ARG5" >> "$OUTPUT_FILE"
	echo -n ", $ARG6" >> "$OUTPUT_FILE"
	echo " }," >> "$OUTPUT_FILE"
done < "$CSV_FILE"

################################################################################
# Finish the output files
################################################################################

# finish the output file
echo "};" >> "$OUTPUT_FILE"

# create the header file
echo "#pragma once" > "$HEADER_FILE"
echo "#include \"syscalls.h\"" >> "$HEADER_FILE"
echo >> "$HEADER_FILE"
MAX_INDEX=$((MAX_INDEX + 1))
echo "#define ${UPPER_ARCH_ABI}_SYSCALL_TABLE_SIZE $MAX_INDEX" >> "$HEADER_FILE"
echo >> "$HEADER_FILE"
echo "extern const t_syscall_entry	${ARCH_ABI}_syscall_table[];" >> "$HEADER_FILE"
echo >> "$HEADER_FILE"
