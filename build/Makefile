FRONT_DIR := ../front
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

last_run:
	mkdir -p ${CSV_DIR}
	./foreach_arch_abi.bash

clean:
	rm -f last_run

fclean: clean
	rm -f ${SRC_DIR}/index.html
	rm -rf ${ARCH_DIR}
	rm -rf ${CSV_DIR}

re: fclean all

.PHONY: all clean fclean re
