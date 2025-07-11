# Docker scripts -- small utilities to simplify the creation of reproducible environments

## Usage:

1. To create a new docker image based on the configurations provided in `Dockerfile`, run:
```.bash
$ ./docker-build.sh
```

`docker-build.sh` will download the base image specified in `Dockerfile`,
install the required packages and create a new user (matching the host user
name, uid and gid).  The created user will have passwordless sudo, and will
also be automatically added to the necessary groups in order to use the gpu(s).


2. To create a docker container based on the image built in (1), run:
```.bash
$ ./docker-run.sh
```

`docker-run.sh` will mount `$HOME` into the homedir of the user created in (1),
inside the container, and will also pass all of the necessary flags to use the
host's gpu(s).


3. To execute command `[CMD]` inside the container created in (2), run:
```.bash
$ ./docker-exec.sh [CMD]
```

`docker-exec.sh` executed without a command will run the configured shell.
Typical invocations are `./docker-exec.sh` (without any arguments to run the
configured shell) or `./docker-exec.sh bash` (to run `bash` inside the docker).


4. To remove the image created in (1), run:
```.bash
$ ./docker-rm-image.sh
```

In order to remove an image it is necessary to remove all containers that
depend on it first, see item (5).


5. To remove the container created in (2), run:
```.bash
$ ./docker-rm-container.sh
```
