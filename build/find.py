#!/usr/bin/env python3

import os
import re
import sys

# Execute command to find all syscalls declared with SYSCALL_DEFINE
path = "./linux"
regex = "'^SYSCALL_DEFINE[0-6]\(\w+\\b(?s).*?\)'"
command = "rg -U --heading --glob '*.[c]' " + regex + " " + path
lines = os.popen(command).readlines()

file = ""
file_matches = {}
for line in lines:
    # remove the trailing newline
    line = line.strip()

    # if line is a file path add a new entry to file_matches
    if line.startswith(path):
        file = line
        file_matches[file] = []
        continue
    # if it is a separator, skip it
    elif line == "--" or line == "":
        continue
    # if it is a syscall, add it to the list
    elif line.startswith("SYSCALL_DEFINE"):
        file_matches[file].append(line)
    elif len(file_matches[file]) > 0:
        file_matches[file][-1] += " " + line

# format parameter
def format_parameter(raw_param):
    raw_param = raw_param.strip().split()
    param = []
    for token in raw_param:
        token = token.strip()
        if token == "__user":
            continue
        while token.startswith("*") and len(token) > 1:
            param.append("*")
            token = token[1:]
        param.append(token)
    return " ".join(param)


# format the parameters from the syscall defines
def format_define_parameters(define_params):
    define_params = define_params.strip().split(",")
    params = []
    for ctype, name in zip(define_params[::2], define_params[1::2]):
        params.append(format_parameter(ctype + " " + name))
    return params


# iterate over the dictionary and add the syscalls to the list
syscall_macros = {}
for file in file_matches:
    for define in file_matches[file]:
         match = re.search(r"^SYSCALL_DEFINE([0-6])\((\w+),?(.*)\)$", define)
         count = int(match.group(1))
         name = match.group(2)
         args = format_define_parameters(match.group(3))
         if count != len(args):
            print("Error: " + name + " has " + str(len(args)) + " arguments but is declared with SYSCALL_DEFINE" + str(count))
            sys.exit(1)
         if name not in syscall_macros:
            syscall_macros[name] = {}
         if file not in syscall_macros[name]:
            syscall_macros[name][file] = []
         syscall_macros[name][file].append(args)

# print the syscalls
for syscall in syscall_macros:
    print(syscall + ":")
    for file in syscall_macros[syscall]:
        print("\t" + file + ":")
        for args in syscall_macros[syscall][file]:
            arg_string = ", ".join(args)
            if len(arg_string) > 0:
                print("\t\t" + arg_string)
            else:
                print("\t\tvoid")
