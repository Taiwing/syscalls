#!/usr/bin/env bash

# This script is used to update the syscalls and restart the docker container

# log file to keep track of the updates
LOG_FILE=syscalls-update.log

# go to repo directory and update the syscalls
cd $(dirname $0)
make re >> .${LOG_FILE}.new 2>&1

if diff .${LOG_FILE}.old .${LOG_FILE}.new; then
	# if old and new logs are same, remove the new log
	rm .${LOG_FILE}.new
else
	# if old and new logs are different, update the logs
	echo Updating syscalls on $(date) >> ${LOG_FILE}
	cat .${LOG_FILE}.new >> ${LOG_FILE}
	mv .${LOG_FILE}.new .${LOG_FILE}.old
fi

# restart the docker container
docker compose up -d --build --force-recreate
