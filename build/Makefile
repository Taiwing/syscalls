FRONT_DIR := ../front
LINUX_DIR := ../linux
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

${CSV_DIR}: last_run

last_run: ${LINUX_DIR}/generic_32.tbl ${LINUX_DIR}/generic_64.tbl
	mkdir -p ${CSV_DIR}
	./foreach_arch_abi.bash

${LINUX_DIR}/generic_32.tbl:
	./generic_table.bash 32

${LINUX_DIR}/generic_64.tbl:
	./generic_table.bash 64

clean:
	rm -f ${LINUX_DIR}/generic_*.tbl

fclean: clean
	rm -f last_run
	rm -f ${SRC_DIR}/index.html
	rm -rf ${ARCH_DIR}
	rm -rf ${CSV_DIR}

re: fclean all

.PHONY: all clean fclean re
