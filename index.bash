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
		<p>Last update: $(date -R)</p>
		<p>
			This website contains a list of every system call for each
			architecture supported by the Linux kernel. The data is extracted
			directly from the last version of the kernel source code. The script
			that does this is executed at regular intervals, therefore it should
			always be up-to-date.
		</p>
		<p>
			The syscall lists are always complete, meaning that there won't be
			any missing syscall. However, some syscalls might not have any
			parameter listed. Most of the time, this is because the syscall
			is not implemented yet. The status will be 'todo' in the csv files.
			In some rare cases, this can be because the script was not able to
			find or parse the syscall declaration. The status will be set to
			'missing' in the csv files. Right now, this is only the case for
			syscalls directly implemented in assembly. This is not yet supported
			by the parsing script but it might be in the future.
		</p>
		<p>
			Other syscalls might be lacking some information about their
			parameters. This is because the syscall declaration was not explicit
			enough. For example, the <code>oldolduname</code> syscall for the
			i386 architecture is declared as follows:
			<code>int sys_olduname(struct oldold_utsname *);</code>
			As you can see, the parameter is not named. This is not a problem
			for the kernel, but it is for the parsing script. In this case, the
			status will be set to 'anon' and only the type of the parameter will
			be listed.
		</p>
		<p>
			Most of the syscalls will show up as 'ok' in the csv files. This
			means that the data was successfully extracted from the kernel
			source code. It should be accurate, complete and up-to-date.
			However, if you find any error, please feel free to report it on the
			<a href="https://github.com/Taiwing/syscalls/issues">github</a>
			repository.
		</p>
		<a href="csv/syscalls.tar.gz" download>Download all syscalls as CSV</a>
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
