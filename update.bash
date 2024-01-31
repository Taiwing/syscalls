#!/usr/bin/env bash

# This script is meant to be run directly as a cron job. It fetches the last
# version of the linux kernel and updates the syscall lists in the frontend.
# It commits the changes and refreshes the running app.

# go to this application directory
cd $(dirname $0)

# pull the latest changes from the remote repository, including all submodules
git pull --recurse-submodules

# update all submodules to the latest version
git submodule update --remote --recursive

# rebuild the front files
date -R > build/last_update
make -C build/ re
make -C build/ clean

# commit the new application build
git commit -am "build: update syscalls list"

# rebuild the running application
docker compose up -d --build --force-recreate
