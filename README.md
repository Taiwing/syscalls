# Syscalls

A small web application that lists the linux kernel syscalls for each available
architecture. It does this with a script that parses the kernel's source code.
Then static html pages are generated from the collected data. The main goal of
this project is to automate the process so that this resource can be kept
up-to-date without manual intervention.

## Setup

```shell
# clone it
git clone https://github.com/Taiwing/syscalls

# build the front
make -C build/

# run the app
docker compose up --build
```

Click [here](http://localhost:8080) to test it locally.
