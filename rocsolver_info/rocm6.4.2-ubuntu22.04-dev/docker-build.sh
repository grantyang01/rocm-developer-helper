#!/bin/bash

REL_PATH="$(dirname -- "${BASH_SOURCE[0]}")"
ABS_PATH="$(cd -- "${REL_PATH}" && pwd)"
source ${ABS_PATH}/docker-env.sh

#
# Remove previous image, if it exists
#
docker ps -a | grep ${DOCKER_NAME} > /dev/null 2>&1 \
    && echo "Error: image ${DOCKER_IMAGE_NAME} has already been built, remove it and its dependencies before running ${0}" && exit # docker container stop ${DOCKER_NAME} > /dev/null \
    # && docker container rm ${DOCKER_NAME}

docker image inspect ${DOCKER_IMAGE_NAME} | grep ${DOCKER_NAME} > /dev/null 2>&1 \
    && echo "Error: image ${DOCKER_IMAGE_NAME} has already been built, remove it and its dependencies before running ${0}" && exit # docker rmi ${DOCKER_IMAGE_NAME}

#
# Build new image
#
docker build \
    --build-arg "DUID=$(id -u)" \
    --build-arg "DGID=$(id -g)" \
    --build-arg "DUSERNAME=$(whoami | sed -e 's/-//g')" \
    --build-arg "DHOME=${ENV_DHOME}" \
    --build-arg "DVGID=$(getent group | grep -Po "video:\w:\K\d+")" \
    --build-arg "DRGID=$(getent group | grep -Po "render:\w:\K\d+")" \
    --build-arg "DSHELL=${ENV_DSHELL}" \
    -t ${DOCKER_IMAGE_NAME} .
