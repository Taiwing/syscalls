#!/usr/bin/env bash

# This script is used to generate the index.html file for the website. It links
# to all the syscalls pages.
# It is not meant to be run by hand, but rather by the Makefile (hehe why not?)

################################################################################
# Configuration
################################################################################

# Set the path to the root of the git repository
ROOT="$(git rev-parse --show-toplevel)"

# build directory
BUILD_DIR="${ROOT}/build"

# output file
OUTPUT_DIR="${ROOT}/front/src"
OUTPUT_FILE="${OUTPUT_DIR}/index.html"

# syscall pages
ARCH_DIR="arch"

################################################################################
# Functions
################################################################################

count_status() {
    local STATUS="$1"

    COUNT=$(\
		rg -c ",$STATUS," "$ROOT"/front/csv \
		| awk -F ':' '{s+=$2} END {print s}' \
	)
	[ -z "$COUNT" ] && COUNT=0
    echo "$COUNT"
}

# print the list of syscall pages
print_main() {
    cat <<EOF
		<main>
			<h1>Syscalls</h1>
			<p>
				This website lists every system call for each architecture
				supported by the Linux kernel. The data is extracted directly
				from the last version of the kernel source code. The script that
				does this is executed once a week, therefore it should always be
				up-to-date.
			</p>
			<p id="csv-download">
				<a href="csv/syscalls.tar.gz" download>
					Download every syscall list as CSV
				</a>
			</p>
EOF

	# list generic architectures
	cat <<EOF
			<h2>Generic Architectures</h2>
			<ul>
EOF
	for SYSCALL_PAGE in $(ls ${OUTPUT_DIR}/${ARCH_DIR} | grep -e 'generic_*');
	do
		ARCH="$(basename "${SYSCALL_PAGE}" .html)"
		cat <<EOF
				<li><a href="${ARCH_DIR}/${SYSCALL_PAGE}">${ARCH}</a></li>
EOF
	done

	# list non-generic architectures
	cat <<EOF
			</ul>
			<h2>Specific Architectures</h2>
			<ul>
EOF
	for SYSCALL_PAGE in $(ls ${OUTPUT_DIR}/${ARCH_DIR} | grep -ve 'generic_*');
	do
		ARCH="$(basename "${SYSCALL_PAGE}" .html)"
		cat <<EOF
				<li><a href="${ARCH_DIR}/${SYSCALL_PAGE}">${ARCH}</a></li>
EOF
    done

    cat <<EOF
			</ul>
			<h2>What is a syscall?</h2>
			<p>
				A system call is a function provided by the kernel that can be
				used by user-space programs. It is the only way for a program to
				interact with the kernel. For example, if a program wants to
				write something to a file, it will have to use the
				<code>write</code> syscall. The program will pass the file
				descriptor, the buffer and the size of the buffer to the kernel
				through the syscall. The kernel will then write the content of
				the buffer to the file and return the number of bytes written.
			</p>
			<h2>Why so many lists?</h2>
			<p>
				For historical and technical reasons, the Linux kernel supports
				a lot of architectures with different system calls sets. Some
				might be implemented differently, some might not be implemented
				at all. Or they might simply be ordered differently. However not
				every architecture has its own syscall list. Some of them share
				the same generic list, either the 32bit or the 64bit version.
				They are the standard API for newer architectures.
			</p>
			<h2>Listing the kernel syscalls</h2>
			<p>
				In order to list the syscalls, the script parses the kernel
				source code. It looks for the table files for each specific
				architecture. These files are located in the <code>arch</code>
				directory of the kernel source code. From there, taking the
				Kconfig options into account, it will extract the syscall
				parameters from the C files.
			</p>
			<p>
				The generic syscalls lists are directly based on the generic
				<code>unistd.h</code> header file. It is preprocessed to make
				sure that every optional syscall is included. The script will
				then extract the parameters from the C files as well.
			</p>
			<h2>Syscall status</h2>
			<p>
				The syscall lists are always complete, meaning that there won't
				be any missing syscall even when they are not found. However the
				prototype can be missing or incomplete.
			</p>
			<p>
				Therefore each syscall has a status. You can find it in the csv
				files. On the website non-implemented syscalls are not shown and
				missing prototype information is symbolized by a <code>?</code>.
				The status can be one of the following:
			</p>
			<ul>
				<li>
					<code>ok</code>: The syscall was successfully found and
					parsed. All its parameters are listed and named.
					(total: $(count_status ok))
				</li>
				<li>
					<code>anon</code>: The syscall was successfully found and
					parsed but some of its parameters are not named.
					(total: $(count_status anon))
				</li>
				<li>
					<code>noparam</code>: The syscall was successfully found but
					its parameters are not listed because the script couldn't
					parse them.
					(total: $(count_status noparam))
				</li>
				<li>
					<code>notimp</code>: The syscall is not implemented.
					(total: $(count_status notimp))
				</li>
				<li>
					<code>missing</code>: The syscall was not found in the
					source code. This is a failure of the parsing script.
					(total: $(count_status missing))
				</li>
			</ul>
			<h2>Contributing</h2>
			<p>
				If you find any error, please feel free to report it on the
				<a href="https://github.com/Taiwing/syscalls">github</a>
				repository. Pull requests are also welcome.
			</p>
		</main>
EOF
}

################################################################################
# Main
################################################################################

# include the template functions
source ${BUILD_DIR}/template.bash

main() {
    print_head "Home" "style" "home" > "${OUTPUT_FILE}"
    print_main >> "${OUTPUT_FILE}"
    print_tail >> "${OUTPUT_FILE}"
}

main
