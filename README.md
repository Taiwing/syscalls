# Syscalls

A small web application that lists the linux kernel syscalls for each available
architecture. It does this with a script that parses the kernel's source code.
Then static html pages are generated from the collected data.

The main goal of this project is to automate the process so that this resource
can be kept up-to-date without manual intervention.

## Setup

### Prerequisites

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

SHELL=path/of/your/bash/executable
BASH\_ENV=path/of/your/bash/config
