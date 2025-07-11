#!/bin/bash
set -x

ENV_DUSER=$(whoami | sed -e 's/-//g')
DOCKER_TAG=rocm6_4_2_RC2_ubuntu22_04
DOCKER_IMAGE_NAME=${ENV_DUSER}/dev:${DOCKER_TAG}
DOCKER_NAME=${ENV_DUSER}.dev.${DOCKER_TAG}

ENV_DUID=$(id -u)
ENV_DGID=$(id -g)
ENV_DHOME=${HOME:-/home/$(whoami)}

ENV_VIDEO_GID=$(getent group | grep -Po "video:\w:\K\d+")
ENV_RENDER_GID=$(getent group | grep -Po "render:\w:\K\d+")

if [[ -z ${ENV_DSHELL} ]]; then
    if [[ -n ${SHELL} ]]; then
        ENV_DSHELL=${SHELL}
    else
        ENV_DSHELL="/bin/bash"
    fi
fi

set +x
