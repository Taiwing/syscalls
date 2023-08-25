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
OUTPUT_DIR="./front/src/arch"
mkdir -p "$OUTPUT_DIR"
OUTPUT_FILE="${OUTPUT_DIR}/${ARCH_ABI}.html"

# include the template functions
source ./template.bash

################################################################################
# Create the output files
################################################################################

# create the output file
print_head "$ARCH_ABI" "../style" "yes" > "$OUTPUT_FILE"
cat << EOF >> "$OUTPUT_FILE"
		<main>
			<p>
				<a href="../csv/${ARCH_ABI}.csv" download>Download as a CSV</a>
			</p>
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
	cat <<EOF >> "$OUTPUT_FILE"
					<tr>
						<td>$NR</td>
						<td>$NAME</td>
						<td>$STATUS</td>
						<td>$RETURN_TYPE</td>
						<td>$PARAMS_COUNT</td>
						<td>$PARAM1</td>
						<td>$PARAM2</td>
						<td>$PARAM3</td>
						<td>$PARAM4</td>
						<td>$PARAM5</td>
						<td>$PARAM6</td>
					</tr>
EOF

done < "$CSV_FILE"

################################################################################
# Finish the output file
################################################################################

cat <<EOF >> "$OUTPUT_FILE"
				</tbody>
			</table>
		</main>
EOF

print_tail >> "$OUTPUT_FILE"
