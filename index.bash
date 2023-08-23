#!/bin/env bash

# This script is used to generate the index.html file for the website. It links
# to all the syscalls pages.
# It is not meant to be run by hand, but rather by the Makefile (hehe why not?)

################################################################################
# Configuration
################################################################################

# the name of the website
WEBSITE_NAME="Syscalls"

# the name of the website's author
WEBSITE_AUTHOR="Yoann Foreau"

# output file
OUTPUT_DIR="./front/src"
OUTPUT_FILE="${OUTPUT_DIR}/index.html"

# syscall pages
ARCH_DIR="arch"

################################################################################
# Functions
################################################################################

# print the header of the index.html file
print_header() {
    cat <<EOF
<!DOCTYPE html>
<html lang="en">
	<head>
	    <meta charset="utf-8">
	    <title>${WEBSITE_NAME} - Home</title>
	    <meta name="author" content="${WEBSITE_AUTHOR}">
	    <meta name="viewport" content="width=device-width, initial-scale=1">
	</head>
	<body>
EOF
}

# print the footer of the index.html file
print_footer() {
    cat <<EOF
	</body>
</html>
EOF
}

# print the list of syscall pages
print_syscalls() {
    cat <<EOF
		<h1>Syscalls</h1>
		<ul>
EOF
    for SYSCALL_PAGE in $(ls ${OUTPUT_DIR}/${ARCH_DIR}); do
		ARCH="$(basename "${SYSCALL_PAGE}" .html)"
		echo "			<li><a href=\"${ARCH_DIR}/${SYSCALL_PAGE}\">${ARCH}</a></li>"
    done
    cat <<EOF
		</ul>
EOF
}

################################################################################
# Main
################################################################################

main() {
    print_header > "${OUTPUT_FILE}"
    print_syscalls >> "${OUTPUT_FILE}"
    print_footer >> "${OUTPUT_FILE}"
}

main
