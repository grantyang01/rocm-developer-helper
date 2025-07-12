#!/bin/bash

REL_PATH="$(dirname -- "${BASH_SOURCE[0]}")"
ABS_PATH="$(cd -- "${REL_PATH}" && pwd)"

${ABS_PATH}/docker-build.sh
${ABS_PATH}/docker-run.sh
${ABS_PATH}/docker-exec.sh $(pwd)/post-build.sh
