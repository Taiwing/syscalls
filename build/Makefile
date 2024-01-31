FRONT_DIR := ../front
LINUX_DIR := ../linux
TBL_DIR := ${LINUX_DIR}/tbl
CSV_DIR := ${FRONT_DIR}/csv
SRC_DIR := ${FRONT_DIR}/src
ARCH_DIR := ${SRC_DIR}/arch

all: ${SRC_DIR}/index.html

${SRC_DIR}/index.html: ${ARCH_DIR} ${CSV_DIR}/syscalls.tar.gz
	./index.bash

${ARCH_DIR}: ${CSV_DIR}
	mkdir -p $@
	./foreach_csv.bash

${CSV_DIR}/syscalls.tar.gz: ${CSV_DIR}
	cd ${CSV_DIR} && tar -czf syscalls.tar.gz *.csv

${CSV_DIR}: ${TBL_DIR}
	mkdir -p ${CSV_DIR}
	./foreach_arch_abi.bash

${TBL_DIR}:
	mkdir -p $@
	./foreach_notable_arch.bash
	./generate_table.bash generic 32 32
	./generate_table.bash generic 64 64

clean:
	rm -rf ${TBL_DIR}

fclean: clean
	rm -f ${SRC_DIR}/index.html
	rm -rf ${ARCH_DIR}
	rm -rf ${CSV_DIR}

re: fclean all

.PHONY: all clean fclean re
