#!/bin/env bash

# This script is used to generate the syscall table from the kernel.

SYSCALL_TABLE_32_FILENAME="syscall_32.tbl"
SYSCALL_TABLE_64_FILENAME="syscall_64.tbl"
SYSCALL_TABLE_32_URL="https://raw.githubusercontent.com/torvalds/linux/master/arch/x86/entry/syscalls/${SYSCALL_TABLE_32_FILENAME}"
SYSCALL_TABLE_64_URL="https://raw.githubusercontent.com/torvalds/linux/master/arch/x86/entry/syscalls/${SYSCALL_TABLE_64_FILENAME}"
SYSCALL_HEADER_FILENAME="syscalls.h"
SYSCALL_HEADER_URL="https://raw.githubusercontent.com/torvalds/linux/master/include/linux/${SYSCALL_HEADER_FILENAME}"

# Download the syscall tables and header from the kernel.
curl ${SYSCALL_TABLE_64_URL} > ${SYSCALL_TABLE_64_FILENAME}
curl ${SYSCALL_TABLE_32_URL} > ${SYSCALL_TABLE_32_FILENAME}
curl ${SYSCALL_HEADER_URL} > ${SYSCALL_HEADER_FILENAME}

# Remove given patterns from the syscall header.
cp ${SYSCALL_HEADER_FILENAME} ${SYSCALL_HEADER_FILENAME}.bak
sed -i 's/ __user / /g' ${SYSCALL_HEADER_FILENAME}
sed -i 's/asmlinkage //g' ${SYSCALL_HEADER_FILENAME}
