#!/bin/bash
set -x

elevate_if_not_root( )
{
  if (( $EUID )); then
    sudo "$@" || exit
  else
    "$@" || exit
  fi
}

#
# Install prebuilt math libraries if they exist
#
REL_PATH="$(dirname -- "${BASH_SOURCE[0]}")"
ABS_PATH="$(cd -- "${REL_PATH}" && pwd)"
ARTIFACTS_DIR=${ARTIFACTS_DIR:-"${ABS_PATH}/artifacts"}
if [[ -d ${ARTIFACTS_DIR} ]] && \
    ! find ${ARTIFACTS_DIR}/. ! -name . -prune -exec false {} +
then
    DEBIAN_FRONTEND=noninteractive elevate_if_not_root dpkg -i ${ARTIFACTS_DIR}/*.deb
    elevate_if_not_root apt --fix-broken install -y
fi
set +x
