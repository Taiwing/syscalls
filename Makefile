FRONT_DIR := front
LINUX_DIR := linux
BUILD_DIR := build
TBL_DIR := ${LINUX_DIR}/tbl
CSV_DIR := ${FRONT_DIR}/csv
SRC_DIR := ${FRONT_DIR}/src
ARCH_DIR := ${SRC_DIR}/arch

all: ${SRC_DIR}/index.html

${SRC_DIR}/index.html: ${CSV_DIR} ${ARCH_DIR} ${BUILD_DIR}/last_update
	${BUILD_DIR}/index.bash

${ARCH_DIR}: ${CSV_DIR} ${BUILD_DIR}/last_update
	mkdir -p $@
	${BUILD_DIR}/foreach_csv.bash

${CSV_DIR}: ${TBL_DIR}
	mkdir -p $@
	${BUILD_DIR}/foreach_arch_abi.bash
	cd $@ && tar -czf syscalls.tar.gz *.csv

${TBL_DIR}:
	mkdir -p $@
	${BUILD_DIR}/foreach_notable_arch.bash
	${BUILD_DIR}/generate_table.bash generic 32 32
	${BUILD_DIR}/generate_table.bash generic 64 64

${BUILD_DIR}/last_update:
	date -R > $@

front_clean:
	rm -f ${SRC_DIR}/index.html
	rm -rf ${ARCH_DIR}

clean: front_clean
	rm -rf ${TBL_DIR}
	rm -rf ${CSV_DIR}

fclean: clean
	rm -f ${BUILD_DIR}/last_update

re: fclean all

front: front_clean all

.PHONY: all front_clean clean fclean re front
