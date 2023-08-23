#!/bin/env bash

# This script is used to create an HTML table from a CSV file.
# The csv file must have the following format:
#   - The first line must be the header
#   - The first column is the syscall number (nr)
#   - The second column is the name
#   - The third column is the status
#   - The fourth column is the return_type
#   - The fifth column is the number of parameters
#   - The sixth column to the end are the parameters
# The script will generate a file called syscall_table_${ARCH_ABI}.html

################################################################################
# Configuration
################################################################################

# the csv file
CSV_FILE="$1"
# the architecture
ARCH_ABI="$(basename "$CSV_FILE")"
ARCH_ABI="${ARCH_ABI%.*}"
# output file
OUTPUT_DIR="./front/src"
mkdir -p "$OUTPUT_DIR"
OUTPUT_FILE="${OUTPUT_DIR}/${ARCH_ABI}.html"

################################################################################
# Create the output files
################################################################################

# create the output file
echo -n "" > "$OUTPUT_FILE"
cat << EOF >> "$OUTPUT_FILE"
<!DOCTYPE html>
<html>
	<head>
		<meta charset="utf-8">
		<title>syscall table ${ARCH_ABI}</title>
	</head>
	<body>
		<table>
			<thead>
				<tr>
					<th>NR</th>
					<th>Name</th>
					<th>Status</th>
					<th>Return type</th>
					<th>Parameters count</th>
					<th>Parameter 1</th>
					<th>Parameter 2</th>
					<th>Parameter 3</th>
					<th>Parameter 4</th>
					<th>Parameter 5</th>
					<th>Parameter 6</th>
				</tr>
			</thead>
			<tbody>
EOF

################################################################################
# Read the csv file
################################################################################

# read the csv file
MAX_NR=0
while read LINE; do
	# skip the first line
	[[ "$LINE" =~ "nr,name," ]] && continue

	# split the line on commas
	IFS=',' read -r -a ARRAY <<< "$LINE"

	# get the syscall information
	NR="${ARRAY[0]}"
	NAME="${ARRAY[1]}"
	STATUS="${ARRAY[2]}"
	RETURN_TYPE="${ARRAY[3]}"
	PARAMS_COUNT="${ARRAY[4]}"
	DEFAULT_PARAM="-"
	[ $STATUS = 'missing' ] && DEFAULT_PARAM="?"
	PARAM1="${ARRAY[5]:-$DEFAULT_PARAM}"
	PARAM2="${ARRAY[6]:-$DEFAULT_PARAM}"
	PARAM3="${ARRAY[7]:-$DEFAULT_PARAM}"
	PARAM4="${ARRAY[8]:-$DEFAULT_PARAM}"
	PARAM5="${ARRAY[9]:-$DEFAULT_PARAM}"
	PARAM6="${ARRAY[10]:-$DEFAULT_PARAM}"

	# update MAX_NR
	[ $NR -gt $MAX_NR ] && MAX_NR=$NR

	# write the syscall information
	echo "				<tr>" >> "$OUTPUT_FILE"
	echo "					<td>$NR</td>" >> "$OUTPUT_FILE"
	echo "					<td>$NAME</td>" >> "$OUTPUT_FILE"
	echo "					<td>$STATUS</td>" >> "$OUTPUT_FILE"
	echo "					<td>$RETURN_TYPE</td>" >> "$OUTPUT_FILE"
	echo "					<td>$PARAMS_COUNT</td>" >> "$OUTPUT_FILE"
	echo "					<td>$PARAM1</td>" >> "$OUTPUT_FILE"
	echo "					<td>$PARAM2</td>" >> "$OUTPUT_FILE"
	echo "					<td>$PARAM3</td>" >> "$OUTPUT_FILE"
	echo "					<td>$PARAM4</td>" >> "$OUTPUT_FILE"
	echo "					<td>$PARAM5</td>" >> "$OUTPUT_FILE"
	echo "					<td>$PARAM6</td>" >> "$OUTPUT_FILE"
	echo "				</tr>" >> "$OUTPUT_FILE"

done < "$CSV_FILE"

################################################################################
# Finish the output file
################################################################################

# finish the output file
cat << EOF >> "$OUTPUT_FILE"
			</tbody>
		</table>
	</body>
</html>
EOF
