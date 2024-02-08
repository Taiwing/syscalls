#!/usr/bin/env bash

cd $(dirname $0)
{
	echo Updating syscalls on $(date)
	make re
	docker compose up -d --build --force-recreate
} >> /var/log/syscalls-update.log 2>&1

