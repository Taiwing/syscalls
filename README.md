# Syscalls

A small web application that lists the linux kernel syscalls for each available
architecture. It does this with a script that parses the kernel's source code.
Then static html pages are generated from the collected data.

## Description

The main goal of this project is to automate the process so that this resource
can be kept up-to-date without manual intervention. This application is up and
running at the following address:

https://syscalls.defoy.tech

It is updated once a week (every monday). The lists are available for each
architecture supported by the linux kernel as well as for the "generic
architectures" (the default syscall lists for 32bit and 64bit processors). They
can be consulted directly on the site or downloaded in the CSV format.

## Local Setup

### Dependencies

This project is made to run on a linux system with at least the following
programs available:

- bash
- gcc
- ripgrep
- make
- docker

### Run the application

```shell
# clone it (downloading the kernel will take some time)
git clone --recurse-submodules https://github.com/Taiwing/syscalls
```

The first thing you need to do is to create an environment file for the
application. To use the default values you can simply copy the _env.sample_ file
at the root of the repository and rename it to _.env_:

```shell
cp env.sample .env
```

Then you can build the application and run it:

```shell
# build the front
make -C build/

# run the app
docker compose up --build
```

Click [here](http://localhost:8080) to test it locally.

### Automation

To keep the lists up to date automatically simply create a cron job running the
_update.bash_ script. It will pull the last changes from the linux kernel
repository, re-build the application and restart it.

```shell
# edit the cron job table
crontab -e
```

Add this line to your crontab to run it once a week:

```cron
0 7 * * 1 path/of/this/repo/update.bash
```

If you have issues when running the script with cron (like empty lists), this is
probably because the ripgrep command is missing. Either because it is not
installed or because it is not on the PATH. If you have a specific bash
configuration that is not taken into account by the cron job you might need to
add the following lines to your crontab:

```shell
SHELL=path/of/your/bash/executable
BASH_ENV=path/of/your/bash/config
```

## Other Sources

There are some other projects listing the linux kernel syscalls that have been a
great help during the development of this application. Some have more or less
informations about each syscall. They also do not handle the exact same set of
architectures. They might be used to cross-reference the lists provided here or
simply as an additional source regarding linux syscalls:

- https://gpages.juszkiewicz.com.pl/syscalls-table/syscalls.html
- https://syscalls.w3challs.com/
- https://syscall.sh/about
- https://github.com/strace/strace/tree/master/src/linux
