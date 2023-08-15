#!/bin/env bash

# This script will find all the syscall definitions in the kernel source code
# for a given architecture and ABI. It returns a CSV file with the following
# columns:
# - nr: syscall number
# - name: syscall name
# - status: syscall status (implemented, not implemented or missing)
# - return_type: syscall return type
# - param_count: number of parameters
# - param1: first parameter
# - param2: second parameter
# - param3: third parameter
# - param4: fourth parameter
# - param5: fifth parameter
# - param6: sixth parameter
#
# The status is determined by the following rules:
# - implemented: the syscall is implemented in the kernel
# - not implemented: the syscall is not implemented in the kernel
# - missing: this script has not found the syscall definition in the kernel, in
#   most case this means that this script needs to be updated, but it can also
#   mean that the syscall is implemented in a different way (e.g. using a
#   different name or a different prototype)

#################### SCRIPT CONFIGURATION ####################

# path to the linux kernel source code
LINUX_PATH="./linux"
cd $LINUX_PATH

# path to the syscall table file
ARCH_FILE="${1:-arch/x86/entry/syscalls/syscall_64.tbl}"
# architecture name (for the header path)
ARCH_NAME="${2:-x86}"
# ABI name (for the syscall table)
ABI_NAME="${3:-64}"
# valid ABIs for this architecture
TARGET_ABIS=("common" $ABI_NAME)

# set unique ARCH_ABI identifier
ARCH_ABI="${ARCH_NAME}"
if [ "${ABI_NAME}" != "common" ]; then
	ARCH_ABI="${ARCH_ABI}_$(echo ${ABI_NAME} | tr ' ' '_')"
fi

# get address size (32 or 64)
ADDR_SIZE=0
if [[ "${ARCH_FILE}" =~ _(32|64)\.tbl ]]; then
	ADDR_SIZE=${BASH_REMATCH[1]}
elif [[ "${ABI_NAME}" =~ ^(|.* )(32|64)$ ]]; then
	ADDR_SIZE=${BASH_REMATCH[2]}
fi

# output file
OUTPUT_FILE="syscalls_${ARCH_ABI}.csv"
echo -n "nr,name,status,return_type,param_count," > $OUTPUT_FILE
echo "param1,param2,param3,param4,param5,param6" >> $OUTPUT_FILE

#################### CLEANUP ####################

# remove temporary files
function cleanup {
	rm -f tmp_${ARCH_ABI}_*
}

# cleanup on exit
trap cleanup EXIT

#################### PARSE SYSCALL TABLE ####################

# read the table file line by line
SYS_CALLS=()
while read LINE; do
	# skip comments
	[[ $LINE =~ ^#.*$ ]] && continue

	# skip empty lines
	[[ -z $LINE ]] && continue

	# split the line into columns
	LCOLS=(${LINE})
	SYS_NUMBER=${LCOLS[0]}
	SYS_ABI=${LCOLS[1]}
	SYS_NAME=${LCOLS[2]}

	# if the syscall is not for this ABI, skip it
	[[ ! "${TARGET_ABIS[@]}" =~ "$SYS_ABI" ]] && continue

	# define SYS_ENTRY with fallback to SYS_COMPAT if needed
	SYS_ENTRY=""
	if [ -n "${LCOLS[3]}" -a "${LCOLS[3]}" != "-" ]; then
		SYS_ENTRY="${LCOLS[3]}"
	elif [ -n "${LCOLS[4]}" -a "${LCOLS[4]}" != "-" ]; then
		SYS_ENTRY="${LCOLS[4]}"
	fi

	# add the syscall to the list
	SYS_CALLS+=("$SYS_NUMBER $SYS_NAME ${SYS_ENTRY:-sys_ni_syscall}")
done < $ARCH_FILE

#################### PARSE DECLARATIONS ####################

# list of kernel types
# output of the following command (with some manual cleanup):
# awk -F ',' '{ for (i = 6; i <= 11; i++) { sub(/ .*/, "", $i); print $i } }' \
# linux/syscalls_*.csv | sort -u | grep -v '^\(param[1-6]\|\)$'
KERNEL_TYPES=(
	aio_context_t cap_user_data_t cap_user_header_t char clockid_t
	compat_sigset_t compat_size_t compat_ulong_t fd_set gid_t int
	__kernel_old_time_t key_serial_t key_t loff_t long mqd_t off_t old_sigset_t
	pid_t qid_t rwf_t __s32 __sighandler_t siginfo_t sigset_t size_t stack_t
	timer_t __u32 u32 __u64 u64 uid_t umode_t unsigned utrap_entry_t
	utrap_handler_t void
)

# list of kernel types that are multi word (const is a special case)
MW_KERNEL_TYPES=(enum struct union)

# check that parameter has a name (0 = yes, 1 = no)
# TODO: handle multi word types (e.g. enum struct union)
function parameter_has_name {
	local PARAMETER=("$@")

	# if the first word is a const, remove it
	#[ "${PARAMETER[0]}" == "const" ] && PARAMETER=("${PARAMETER[@]:1}")

	# if there is not at least two words then the parameter has no name
	[ ${#PARAMETER[@]} -lt 2 ] && return 1

	# if the last word is a KERNEL_TYPE then the parameter has no name
	LAST_WORD="${PARAMETER[-1]}"
	for TYPE in "${KERNEL_TYPES[@]}"; do
		[ "$LAST_WORD" == "$TYPE" ] && return 1
	done

	# if the last word ends with a '*' then the parameter has no name
	[[ "$LAST_WORD" =~ \*$ ]] && return 1

	# we assume that the parameter has a name
	return 0
}

# parse syscall prototype from the header files
function parse_syscall_prototype {
	local SYS_ENTRY="$1"
	local PROTOTYPE="$2"

	# get the parameters
	local PARAMETER_STRING=""
	[[ "$PROTOTYPE" =~ \((.*)\)\;$ ]] || return 1
	PARAMETER_STRING="${BASH_REMATCH[1]}"

	# split and count the parameters
	local PARAMETERS=""
	local PARAMETER_COUNT=0
	local TEST_PARAM_ARRAY=() #TEMP
	local ANONYMOUS_PARAMETERS=0 #TEMP (0 = false, 1 = true)
	while [[ "$PARAMETER_STRING" =~ ^([^,]+),?(.*)$ ]]; do
		# tokenize the parameter
		read -ra PARAMETER -d '' <<< "${BASH_REMATCH[1]}"

		# remove the __user annotation
		for INDEX in "${!PARAMETER[@]}"; do
			[ "${PARAMETER[$INDEX]}" == "__user" ] && unset PARAMETER[$INDEX]
		done
		PARAMETER=("${PARAMETER[@]}") #TEMP
		if [ $ANONYMOUS_PARAMETERS -eq 0 ]; then
			parameter_has_name "${PARAMETER[@]}"
			ANONYMOUS_PARAMETERS=$?
		fi

		# append the parameter to the list
		if [ -z "$PARAMETERS" ]; then
			PARAMETERS=",${PARAMETER[@]}"
		else
			PARAMETERS="$PARAMETERS,${PARAMETER[@]}"
		fi
		TEMP="${PARAMETER[@]}" #TEMP
		TEST_PARAM_ARRAY+=("$TEMP") #TEMP
		PARAMETER_STRING="${BASH_REMATCH[2]}"
		PARAMETER_COUNT=$((PARAMETER_COUNT+1))
	done

	if [ $ANONYMOUS_PARAMETERS -eq 1 ]; then
		echo "anonymous parameters ($SYS_ENTRY):" >&2 #TEMP
		for PARAM in "${TEST_PARAM_ARRAY[@]}"; do
			echo "  $PARAM" >&2 #TEMP
		done
	fi

	# handle special case for void
	if [ $PARAMETER_COUNT -eq 1 -a "$PARAMETERS" == ",void" ]; then
		PARAMETERS=""
		PARAMETER_COUNT=0
	fi

	# get the return type
	local RETURN_TYPE=""
	[[ "$PROTOTYPE" =~ ^asmlinkage[[:space:]]+([^\(]+)[[:space:]]+$SYS_ENTRY\(.*$ ]] || return 1
	RETURN_TYPE="${BASH_REMATCH[1]}"

	# print the prototype
	echo -n "${RETURN_TYPE},${PARAMETER_COUNT}${PARAMETERS}"

	#print remaining commas
	for ((i=PARAMETER_COUNT; i<6; i++)); do
		echo -n ","
	done

	return 0
}

# parse syscall define from the source files
function parse_syscall_define {
	local SYS_NAME="$1"
	local PROTOTYPE="$2"

	# get parameter count and parameter string
	local PARAMETER_COUNT=0
	[[ "$PROTOTYPE" =~ ^SYSCALL_DEFINE([0-9]+)\((.*)\)$ ]] || return 1
	PARAMETER_COUNT="${BASH_REMATCH[1]}"
	PROTOTYPE="${BASH_REMATCH[2]}"

	# if there are no parameters we can print the prototype and return
	if [ $PARAMETER_COUNT -eq 0 ]; then
		echo -n "long,0,,,,,,"
		return 0
	fi

	# get the parameters
	[[ "$PROTOTYPE" =~ ^$SYS_NAME,(.*)$ ]] || return 1
	PROTOTYPE="${BASH_REMATCH[1]}"
	local COUNT=0
	local PARAMETERS=""
	while [[ "$PROTOTYPE" =~ ^([^,]+),([^,]+),?(.*)$ ]]; do
		# tokenize the parameter type and name
		read -ra PTYPE -d '' <<< "${BASH_REMATCH[1]}"
		read -ra PNAME -d '' <<< "${BASH_REMATCH[2]}"

		# remove the __user annotation
		for INDEX in "${!PTYPE[@]}"; do
			[ "${PTYPE[$INDEX]}" == "__user" ] && unset PTYPE[$INDEX]
		done

		# append the parameter to the list
		if [ -z "$PARAMETERS" ]; then
			PARAMETERS=",${PTYPE[@]} ${PNAME[@]}"
		else
			PARAMETERS="$PARAMETERS,${PTYPE[@]} ${PNAME[@]}"
		fi
		PROTOTYPE="${BASH_REMATCH[3]}"

		# increment the parameter count
		COUNT=$((COUNT+1))
	done
	[ $COUNT -ne $PARAMETER_COUNT ] && return 1

	# print the prototype
	echo -n "long,${PARAMETER_COUNT}${PARAMETERS}"

	#print remaining commas
	for ((i=PARAMETER_COUNT; i<6; i++)); do
		echo -n ","
	done

	return 0
}


#################### DISAMBIGUATION ####################

# special cases where the Kconfig section name is not the same as the arch name
declare -A SPECIFIC_CONFIG_NAMES
SPECIFIC_CONFIG_NAMES["x86_i386"]="X86_32 COMPAT_32"
SPECIFIC_CONFIG_NAMES["x86_64"]="X86_64"
SPECIFIC_CONFIG_NAMES["powerpc_nospu_32"]="PPC"
SPECIFIC_CONFIG_NAMES["powerpc_nospu_64"]="PPC"
SPECIFIC_CONFIG_NAMES["powerpc_spu"]="PPC"
SPECIFIC_CONFIG_NAMES["sh"]="SUPERH"

# get Kconfig options
function get_kconfig {
	local OPTIONS=()
	local KCONFIG_KEYS=()
	local KCONFIG_FILE="arch/$ARCH_NAME/Kconfig"

	# return if Kconfig file does not exist (this means default)
	[ ! -f $KCONFIG_FILE ] && return

	# set KCONFIG_KEYS depending on ARCH_ABI to handle special cases
	if [ -n "${SPECIFIC_CONFIG_NAMES[$ARCH_ABI]}" ]; then
		KCONFIG_KEYS=(${SPECIFIC_CONFIG_NAMES[$ARCH_ABI]})
	else
		KCONFIG_KEYS=($(echo $ARCH_NAME | tr '[:lower:]' '[:upper:]'))
	fi

	# get the Kconfig block from the file and extract the options
	for KEY in ${KCONFIG_KEYS[@]}; do
		OUTPUT=($(\
			rg --pcre2 -U \
			'(?s)(\A|\R)\Kconfig\s+'"$KEY"'\n.*?(?=\Rendmenu\b|\Rconfig\b|\Z)' \
			$KCONFIG_FILE | grep -E '^\s+select\s+\b\w+\b$' \
			| sed -E 's/^\s+select\s+(\b\w+\b)$/\1/'
		))
		OPTIONS=("${OPTIONS[@]}" "${OUTPUT[@]}")
	done

	# print the results
	echo "${OPTIONS[@]}"
}

# set Kconfig options
KCONFIG_OPTIONS=($(get_kconfig))

# apply Kconfig options and preprocess the file to reduce to one syscall match
function preprocess_source_file {
	local SOURCE_FILE=$1
	local SYSCALL="$(echo $2 | tr '[:lower:]' '[:upper:]')"

	# file names
	local FLAT_PATH_FILE="$(echo $SOURCE_FILE | tr '/' '_')"
	local NO_INCLUDE_FILE="tmp_${ARCH_ABI}_no_include_${FLAT_PATH_FILE}"
	local PREPROCESSED_FILE="tmp_${ARCH_ABI}_preprocessed_${FLAT_PATH_FILE}"

	# remove include statements if not already done
	if [ ! -f $NO_INCLUDE_FILE ]; then
		grep -v '^\s*#\s*include\b.*' $SOURCE_FILE > $NO_INCLUDE_FILE
	fi

	# create gcc option string from Kconfig options
	local GCC_OPTIONS="-D__ARCH_WANT_SYS_$SYSCALL"
	for OPTION in ${KCONFIG_OPTIONS[@]}; do
		GCC_OPTIONS="$GCC_OPTIONS -DCONFIG_$OPTION"
	done

	# preprocess the file
	gcc -E $GCC_OPTIONS $NO_INCLUDE_FILE > $PREPROCESSED_FILE
	[ $? -ne 0 -o ! -f $PREPROCESSED_FILE ] && return 1

	# return the preprocessed file
	echo $PREPROCESSED_FILE
	return 0
}

#################### FIND SYSCALL DECLARATIONS ####################

# header paths in priority order
VALID_HEADER_PATHS=(\
	"arch/$ARCH_NAME/"
	"include/asm-generic/"
	"include/linux/"
)

# find the syscall by function prototype in the header files
function find_matching_file_by_prototype {
	local SYS_ENTRY=$1
	local HEADER_PATHS=()
	local FILES=()
	local RESULT=0
	local GLOB="true"

	# if no header paths specified, use all valid ones
	if [ -z "$2" ]; then
		HEADER_PATHS=(${VALID_HEADER_PATHS[@]})
	else
		GLOB=""
		HEADER_PATHS=($2)
	fi

	local REGEX="\basmlinkage\b.*\b$SYS_ENTRY\b\("
	for HEADER_PATH in ${HEADER_PATHS[@]}; do
		# find by prototype declaration
		OUTPUT=()
		if [ -z "$GLOB" ]; then
			COUNT="$(rg --count-matches $REGEX $HEADER_PATH || echo 0)"
			[ $COUNT -gt 0 ] && OUTPUT+=("$HEADER_PATH:$COUNT")
		else
			OUTPUT=($(rg --glob '*.h' --count-matches $REGEX $HEADER_PATH))
		fi

		for MATCH in ${OUTPUT[@]}; do
			ARR_MATCH=(${MATCH//:/ })
			FILES+=(${ARR_MATCH[0]})
			COUNT=${ARR_MATCH[1]}
			RESULT=$((RESULT+COUNT))
		done

		# stop if we found a match
		[ $RESULT -gt 0 ] && break
	done

	# print the results
	echo "${FILES[@]}"

	return $RESULT
}

# build a list of all the syscall source directories
RAW_SOURCE_PATHS=$(\
	find . -maxdepth 1 -type d -not -name 'arch' -not -name '.*' \
	| tr -d './' \
	| sort
)
VALID_SOURCE_PATHS=("arch/$ARCH_NAME") # in priority order
for DIRECTORY in $RAW_SOURCE_PATHS; do
	if rg -q --glob '*.c' "\bSYSCALL_DEFINE.\(\w+\b" $DIRECTORY; then
		VALID_SOURCE_PATHS+=($DIRECTORY)
	fi
done

# reduce the list of files if possible
function reduce_files_by_define {
	local RESULT=0
	local TO_REMOVE=()
	local FILES=($(echo $1 | tr ':' ' '))
	local COUNTS=($(echo $2 | tr ':' ' '))

	# if conflict between kernel/ and um/ subdirectories, prefer kernel/
	if [[ "${FILES[@]}" =~ "/kernel/" ]] && [[ "${FILES[@]}" =~ "/um/" ]]; then
		for INDEX in ${!FILES[@]}; do
			[[ "${FILES[$INDEX]}" =~ "/um/" ]] && TO_REMOVE+=($INDEX)
		done
	fi

	# remove blacklisted files
	local BLACKLIST=("nommu.c" "posix-stubs.c")
	for INDEX in ${!FILES[@]}; do
		for BLACKLISTED in ${BLACKLIST[@]}; do
			[[ "${FILES[$INDEX]}" =~ /$BLACKLISTED ]] && TO_REMOVE+=($INDEX)
		done
	done

	# remove file with wrong ADDR_SIZE if the right one is present
	if [ $ADDR_SIZE -eq 32 -o $ADDR_SIZE -eq 64 ]; then
		OTHER_SIZE=$((ADDR_SIZE==32?64:32))
		for FILE in ${FILES[@]}; do
			[[ $FILE =~ ^(.*)_${ADDR_SIZE}\.c$ ]] || continue
			OTHER_FILE="${BASH_REMATCH[1]}_${OTHER_SIZE}.c"
			for INDEX in ${!FILES[@]}; do
				if [ "${FILES[$INDEX]}" = "$OTHER_FILE" ]; then
					TO_REMOVE+=($INDEX)
					break
				fi
			done
		done
	fi

	# remove files
	TO_REMOVE=($(echo ${TO_REMOVE[@]} | tr ' ' '\n' | sort -rn | uniq))
	for INDEX in ${TO_REMOVE[@]}; do
		unset FILES[$INDEX]
		unset COUNTS[$INDEX]
	done
	FILES=(${FILES[@]})
	COUNTS=(${COUNTS[@]})

	# recompute RESULT since we may have removed some files
	for COUNT in ${COUNTS[@]}; do
		RESULT=$((RESULT+COUNT))
	done

	# print the results
	echo "${FILES[@]}"

	return $RESULT
}

# find the syscall by syscall define in the source files
function find_matching_file_by_define {
	local SYS_NAME=$1
	local SOURCE_PATHS=()
	local FILES=()
	local COUNTS=()
	local RESULT=0
	local GLOB="true"

	# if no source paths specified, use all valid ones
	if [ -z "$2" ]; then
		SOURCE_PATHS=(${VALID_SOURCE_PATHS[@]})
	else
		GLOB=""
		SOURCE_PATHS=($2)
	fi

	local REGEX="\bSYSCALL_DEFINE.\($SYS_NAME\b"
	for SOURCE_PATH in ${SOURCE_PATHS[@]}; do
		# find by syscall define
		OUTPUT=()
		if [ -z "$GLOB" ]; then
			COUNT="$(rg --count-matches $REGEX $SOURCE_PATH || echo 0)"
			[ $COUNT -gt 0 ] && OUTPUT+=("$SOURCE_PATH:$COUNT")
		else
			OUTPUT=($(rg --glob '*.c' --count-matches $REGEX $SOURCE_PATH))
		fi

		for MATCH in ${OUTPUT[@]}; do
			ARR_MATCH=(${MATCH//:/ })
			FILES+=(${ARR_MATCH[0]})
			COUNT=${ARR_MATCH[1]}
			COUNTS+=($COUNT)
			RESULT=$((RESULT+COUNT))
		done

		# try and zero in on a unique file if needed
		if [ ${#FILES[@]} -gt 1 ]; then
			FILES_ARG="$(echo ${FILES[@]} | tr ' ' ':')"
			COUNTS_ARG="$(echo ${COUNTS[@]} | tr ' ' ':')"
			FILES=($(reduce_files_by_define "$FILES_ARG" "$COUNTS_ARG"))
			RESULT=$?
		fi

		# stop if we found a match
		[ $RESULT -gt 0 ] && break
	done

	# print the results
	echo "${FILES[@]}"

	return $RESULT
}

# get the full syscall prototype
function get_details_by_prototype {
	local SYS_ENTRY=$1
	local FILE=$2

	# get the full prototype
	rg -U "\basmlinkage\b.*\b$SYS_ENTRY\b\((?s).*?\);" $FILE
}

# get the full syscall define
function get_details_by_define {
	local SYS_NAME=$1
	local FILE=$2

	# get the full define
	rg -U "\bSYSCALL_DEFINE.\($SYS_NAME\b(?s).*?\)" $FILE
}

function find_by_prototype {
	local SYS_NUMBER=$1
	local SYS_NAME=$2
	local SYS_ENTRY=$3
	local FILES=()
	local RESULT=0

	# find the syscall by prototype in the header files
	FILES=($(find_matching_file_by_prototype $SYS_ENTRY))
	RESULT=$?

	# if there was a single file but multiple matches
	if [ ${#FILES[@]} -eq 1 -a $RESULT -gt 1 ]; then
		# try to reduce the matches
		NEW_FILE=$(preprocess_source_file "${FILES[0]}" "$SYS_NAME")
		if [ $? -ne 0 ]; then
			echo -n "ERROR: $SYS_NUMBER $SYS_NAME:"
			echo " failed to preprocess ${FILES[0]}"
			exit 1
		fi

		# check if we got a unique syscall
		FILES=($(find_matching_file_by_prototype $SYS_ENTRY $NEW_FILE))
		RESULT=$?
	fi

	# print the results
	echo "${FILES[@]}"

	return $RESULT
}

function find_by_define {
	local SYS_NUMBER=$1
	local SYS_NAME=$2
	local SYS_ENTRY=$3
	local FILES=()
	local RESULT=0

	# find the syscall by define in the source files
	FILES=($(find_matching_file_by_define $SYS_NAME))
	RESULT=$?

	# if there was a single file but multiple matches
	if [ ${#FILES[@]} -eq 1 -a $RESULT -gt 1 ]; then
		# try to reduce the matches
		NEW_FILE=$(preprocess_source_file "${FILES[0]}" "$SYS_NAME")
		if [ $? -ne 0 ]; then
			echo -n "ERROR: $SYS_NUMBER $SYS_NAME:"
			echo " failed to preprocess ${FILES[0]}"
			exit 1
		fi

		# check if we got a unique syscall
		FILES=($(find_matching_file_by_define $SYS_NAME $NEW_FILE))
		RESULT=$?
	fi

	# print the results
	echo "${FILES[@]}"

	return $RESULT
}

# find all the syscall prototypes
UNIQUE_COUNT=0
NOT_IMPLEMENTED_COUNT=0
NOT_FOUND_COUNT=0
MULTIPLE_COUNT=0
for SYSCALL in "${SYS_CALLS[@]}"; do
	# split syscall line into columns
	SCOLS=(${SYSCALL})
	SYS_NUMBER=${SCOLS[0]}
	SYS_NAME=${SCOLS[1]}
	SYS_ENTRY=${SCOLS[2]}

	# find the syscall file
	FILE=""
	RESULT=0
	METHOD=""
	if [ $SYS_ENTRY != "sys_ni_syscall" ]; then
		METHOD="define"
		FILES=($(find_by_define $SYS_NUMBER $SYS_NAME $SYS_ENTRY))
		RESULT=$?

		# if we did not get a unique syscall, try to find it by prototype
		if [ $RESULT -ne 1 ]; then
			METHOD="prototype"
			FILES=($(find_by_prototype $SYS_NUMBER $SYS_NAME $SYS_ENTRY))
			RESULT=$?
		fi

		if [ ${#FILES[@]} -gt 1 ]; then
			# if we found multiple files (this should never happen)
			echo -n "ERROR: $SYS_NUMBER $SYS_NAME: "
			echo "unexpected multiple file matches"
			for FILE in ${FILES[@]}; do
				echo "  $FILE"
			done
			exit 1
		elif [ $RESULT -gt 1 ]; then
			# if RESULT is still not 1, then pinning down the syscall failed
			echo -n "ERROR: $SYS_NUMBER $SYS_NAME:"
			echo " got $RESULT definitions in ${FILES[0]}"
			exit 1
		else
			FILE=${FILES[0]}
		fi
	fi

	# get details about the syscall
	PARSED_PROTOTYPE=""
	if [ $RESULT -eq 1 ]; then
		DETAILS=""
		if [ $METHOD = "prototype" ]; then
			DETAILS=$(get_details_by_prototype $SYS_ENTRY $FILE)
			PARSED_PROTOTYPE=$(parse_syscall_prototype "$SYS_ENTRY" "$DETAILS")
		else
			DETAILS=$(get_details_by_define $SYS_NAME $FILE)
			PARSED_PROTOTYPE=$(parse_syscall_define "$SYS_NAME" "$DETAILS")
		fi

		# check if we actually got the prototype
		if [ $? -ne 0 -o -z "$PARSED_PROTOTYPE" ]; then
			echo "ERROR: $SYS_NUMBER $SYS_NAME: failed to parse prototype"
			echo $DETAILS
			exit 1
		fi
	fi

	# count errors and found syscalls
	if [ $SYS_ENTRY = "sys_ni_syscall" ]; then
		NOT_IMPLEMENTED_COUNT=$((NOT_IMPLEMENTED_COUNT+1))
		echo "$SYS_NUMBER,$SYS_NAME,not implemented,,,,,,,," >> $OUTPUT_FILE
	elif [ $RESULT -eq 0 ]; then
		NOT_FOUND_COUNT=$((NOT_FOUND_COUNT+1))
		echo "$SYS_NUMBER $SYS_NAME $SYS_ENTRY() not found"
		echo "$SYS_NUMBER,$SYS_NAME,missing,,,,,,,," >> $OUTPUT_FILE
	elif [ $RESULT -eq 1 ]; then
		echo "$SYS_NUMBER,$SYS_NAME,implemented,$PARSED_PROTOTYPE" >> $OUTPUT_FILE
		UNIQUE_COUNT=$((UNIQUE_COUNT+1))
	else
		# this should never happen
		echo "ERROR: $SYS_NUMBER $SYS_NAME $SYS_ENTRY(): unexpected result ($RESULT)"
		exit 1
	fi
done

#################### PRINT RESULTS ####################

# print the results
echo
echo "Unique definition: $UNIQUE_COUNT/${#SYS_CALLS[@]}"
echo "Not implemented: $NOT_IMPLEMENTED_COUNT/${#SYS_CALLS[@]}"
echo "Not found: $NOT_FOUND_COUNT/${#SYS_CALLS[@]}"
