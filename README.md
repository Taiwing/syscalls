# Syscalls

A small web application that lists the linux kernel syscalls for each available
architecture. It does this with a script that parses the kernel's source code.
Then static html pages are generated from the collected data.

The main goal of this project is to automate the process so that this resource
can be kept up-to-date without manual intervention.

## Setup

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
