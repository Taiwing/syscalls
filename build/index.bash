#!/usr/bin/env bash

# This script is used to generate the index.html file for the website. It links
# to all the syscalls pages.
# It is not meant to be run by hand, but rather by the Makefile (hehe why not?)

################################################################################
# Configuration
################################################################################

# Set the path to the root of the git repository
ROOT="$(git rev-parse --show-toplevel)"

# output file
OUTPUT_DIR="${ROOT}/front/src"
OUTPUT_FILE="${OUTPUT_DIR}/index.html"

# syscall pages
ARCH_DIR="arch"

################################################################################
# Functions
################################################################################

# print the list of syscall pages
print_main() {
    cat <<EOF
		<main>
			<p>
				This website contains a list of every system call for each
				architecture supported by the Linux kernel. The data is
				extracted directly from the last version of the kernel source
				code. The script that does this is executed at regular
				intervals, therefore it should always be up-to-date.
			</p>
			<p id="csv-download">
				<a href="csv/syscalls.tar.gz" download>
					Download all syscalls as CSV
				</a>
			</p>
			<ul>
EOF
    for SYSCALL_PAGE in $(ls ${OUTPUT_DIR}/${ARCH_DIR}); do
		ARCH="$(basename "${SYSCALL_PAGE}" .html)"
		cat <<EOF
				<li><a href="${ARCH_DIR}/${SYSCALL_PAGE}">${ARCH}</a></li>
EOF
    done
    cat <<EOF
			</ul>
			<p>
				The syscall lists are always complete, meaning that there won't
				be any missing syscall. However, some syscalls might not have
				any parameter listed. Most of the time, this is because the
				syscall is not implemented yet. The status will be 'todo' in the
				csv files. In some rare cases, this can be because the script
				was not able to find or parse the syscall declaration. The
				status will be set to 'missing' in the csv files. Right now,
				this is only the case for syscalls directly implemented in
				assembly. This is not yet supported by the parsing script but it
				might be in the future.
			</p>
			<p>
				Other syscalls might be lacking some information about their
				parameters. This is because the syscall declaration was not
				explicit enough. For example, the <code>oldolduname</code>
				syscall entry point for the i386 architecture is declared as
				follows: <code>int sys_olduname(struct oldold_utsname *);</code>
				As you can see, the parameter is not named. This is not a
				problem for the kernel, but it is for the parsing script. In
				this case, the status will be set to 'anon' and only the type of
				the parameter will be listed.
			</p>
			<p>
				Most of the syscalls will show up as 'ok' in the csv files. This
				means that the data was successfully extracted from the kernel
				source code. It should be accurate, complete and up-to-date.
				However, if you find any error, please feel free to report it on
				the
				<a href="https://github.com/Taiwing/syscalls">github</a>
				repository.
			</p>
		</main>
EOF
}

################################################################################
# Main
################################################################################

# include the template functions
source ./template.bash

main() {
    print_head "Home" "style" "home" > "${OUTPUT_FILE}"
    print_main >> "${OUTPUT_FILE}"
    print_tail >> "${OUTPUT_FILE}"
}

main
