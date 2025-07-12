#!/bin/bash

REL_PATH="$(dirname -- "${BASH_SOURCE[0]}")"
ABS_PATH="$(cd -- "${REL_PATH}" && pwd)"
source ${ABS_PATH}/docker-env.sh

DEXEC_CMD="${@:-${ENV_DSHELL}}"

docker ps -a | grep ${DOCKER_NAME} > /dev/null 2>&1 \
    && docker start ${DOCKER_NAME} > /dev/null 2>&1 \
    && docker exec -it ${DOCKER_NAME} ${DEXEC_CMD}
