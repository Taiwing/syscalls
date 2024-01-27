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
			<h1>Syscalls</h1>
			<p>
				This website lists every system call for each architecture
				supported by the Linux kernel. The data is extracted directly
				from the last version of the kernel source code. The script that
				does this is executed at regular intervals, therefore it should
				always be up-to-date.
			</p>
			<p id="csv-download">
				<a href="csv/syscalls.tar.gz" download>
					Download every syscall list as CSV
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
			<h2>Syscall status</h2>
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
