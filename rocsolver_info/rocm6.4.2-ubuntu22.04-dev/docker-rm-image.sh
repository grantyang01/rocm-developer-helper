#!/bin/bash

REL_PATH="$(dirname -- "${BASH_SOURCE[0]}")"
ABS_PATH="$(cd -- "${REL_PATH}" && pwd)"
source ${ABS_PATH}/docker-env.sh

docker ps -a | grep ${DOCKER_NAME} > /dev/null 2>&1 \
    && docker container stop ${DOCKER_NAME} > /dev/null \
    && docker container rm ${DOCKER_NAME}

docker image inspect ${DOCKER_IMAGE_NAME} | grep ${DOCKER_NAME} > /dev/null 2>&1 \
    && docker rmi ${DOCKER_IMAGE_NAME}
