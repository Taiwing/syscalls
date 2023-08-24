#!/bin/env bash

################################################################################
# Configuration
################################################################################

# Set the path to the directory containing the CSV files
CSV_DIR="./front/csv"

################################################################################
# Main
################################################################################

# create an html file for each csv file
for CSV_FILE in $CSV_DIR/*.csv; do
	./htables.bash "$CSV_FILE"
done
