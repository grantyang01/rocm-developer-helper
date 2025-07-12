#!/bin/bash
set -x

REL_PATH="$(dirname -- "${BASH_SOURCE[0]}")"
ABS_PATH="$(cd -- "${REL_PATH}" && pwd)"
source ${ABS_PATH}/docker-env.sh

DRUN_AMD_DEVS=${DRUN_AMD_DEVS:-}
if [ -z ${DRUN_AMD_DEVS} ]; then
    echo ""
    if [ -e "/dev/dri" ]; then
        DRUN_AMD_DEVS="${DRUN_AMD_DEVS} --device /dev/dri"
    fi

    if [ -e "/dev/kfd" ]; then
        DRUN_AMD_DEVS="${DRUN_AMD_DEVS} --device /dev/kfd"
    fi
fi

docker ps -a | grep ${DOCKER_NAME} > /dev/null 2>&1 \
    && echo "Error: container ${DOCKER_NAME} is available already, remove it before running ${0}" && exit # docker container stop ${DOCKER_NAME} > /dev/null \
    # && docker container rm ${DOCKER_NAME}

if [ -n "${ROCR_VISIBLE_DEVICES}" ]; then
    INIT_ROCR_VISIBLE_DEVICES="-e ROCR_VISIBLE_DEVICES=${ROCR_VISIBLE_DEVICES}"
fi

if [ -n "${INIT_ROCR_VISIBLE_DEVICES}" ]; then
    INIT_VISIBLE_DEVICES="${INIT_ROCR_VISIBLE_DEVICES}"
fi

docker run -it -d ${DRUN_AMD_DEVS} ${INIT_VISIBLE_DEVICES} \
    --cap-add=SYS_PTRACE \
    --security-opt seccomp=unconfined \
    --hostname "DOCKER-`hostname -s`" \
    --mount type=bind,source=${HOME},target=${ENV_DHOME} \
    --name ${DOCKER_NAME} \
    ${DOCKER_IMAGE_NAME} ${ENV_DSHELL}

set +x
