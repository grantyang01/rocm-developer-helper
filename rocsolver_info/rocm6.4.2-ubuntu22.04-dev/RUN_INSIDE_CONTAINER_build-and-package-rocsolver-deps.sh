#!/bin/bash
set -x

REPOS_COMMON_BRANCH=${REPOS_COMMON_BRANCH:-"develop"}

ROCPRIM_REPO=${ROCPRIM_REPO:-"https://github.com/ROCm/rocPRIM"}
ROCPRIM_TAG=${REPOS_COMMON_BRANCH:-${ROCPRIM_TAG:-"develop"}}
ROCPRIM_DIR="rocPRIM"

HIPBLASLT_REPO=${HIPBLASLT_REPO:-"https://github.com/ROCm/hipBLASLt"}
HIPBLASCOMMON_REPO=${HIPBLASCOMMON_REPO:-"https://github.com/ROCm/hipBLAS-common"}
HIPBLASCOMMON_TAG=${REPOS_COMMON_BRANCH:-${HIPBLASCOMMON_TAG:-"develop"}}
HIPBLASCOMMON_DIR="hipBLAS-common"

HIPBLASLT_REPO=${HIPBLASLT_REPO:-"https://github.com/ROCm/hipBLASLt"}
HIPBLASLT_TAG=${REPOS_COMMON_BRANCH:-${HIPBLASLT_TAG:-"develop"}}
HIPBLASLT_DIR="hipBLASLt"

ROCBLAS_REPO=${ROCBLAS_REPO:-"https://github.com/ROCm/rocBLAS"}
ROCBLAS_TAG=${REPOS_COMMON_BRANCH:-${ROCBLAS_TAG:-"develop"}}
ROCBLAS_DIR="rocBLAS"

ROCSOLVER_REPO=${ROCSOLVER_REPO:-"https://github.com/ROCm/rocSOLVER"}
ROCSOLVER_TAG=${REPOS_COMMON_BRANCH:-${ROCSOLVER_TAG:-"develop"}}
ROCSOLVER_DIR="rocSOLVER"

SCRIPTS_DIR=$(pwd)

# Artifacts (e.g., deb packages) will be saved to the following directory after
# each library is built:
ARTIFACTS_DIR=${ARTIFACTS_DIR:-"${SCRIPTS_DIR}/artifacts_`date +"%F.%s"`"}
mkdir -p ${ARTIFACTS_DIR}

elevate_if_not_root( )
{
  if (( $EUID )); then
    sudo "$@" || exit
  else
    "$@" || exit
  fi
}

# Install rocPRIM and export deb packages
git clone ${ROCPRIM_REPO} \
  && cd ${ROCPRIM_DIR} \
  && git checkout ${ROCPRIM_TAG} \
  && LESS="-R -F" git show --oneline -s \
  && elevate_if_not_root ./install -i
if [[ -d build/release ]]; then
  cd build/release \
  && elevate_if_not_root cpack \
  && cp *.deb ${ARTIFACTS_DIR} \
  && true
fi
cd ${SCRIPTS_DIR} \
  && elevate_if_not_root rm -rf ${ROCPRIM_DIR} \
  && true
elevate_if_not_root apt --fix-broken install -y

# Install hipBLAS-common and export deb packages
git clone ${HIPBLASCOMMON_REPO} \
  && cd ${HIPBLASCOMMON_DIR} \
  && git checkout ${HIPBLASCOMMON_TAG} \
  && LESS="-R -F" git show --oneline -s \
  && mkdir build \
  && cd build \
  && cmake .. \
  && elevate_if_not_root make package install \
  && cp *.deb ${ARTIFACTS_DIR} \
  && cd ${SCRIPTS_DIR} \
  && elevate_if_not_root rm -rf ${HIPBLASCOMMON_DIR} \
  && true
elevate_if_not_root apt --fix-broken install -y

# Install hipBLASLt and export deb packages
# Requires cmake version >= 3.24 but < 4.0
git clone ${HIPBLASLT_REPO} \
  && cd ${HIPBLASLT_DIR} \
  && git checkout ${HIPBLASLT_TAG} \
  && LESS="-R -F" git show --oneline -s \
  && ./install.sh -di
if [[ -d build/release ]]; then
  cd build/release \
  && cp *.deb ${ARTIFACTS_DIR} \
  && true
fi
cd ${SCRIPTS_DIR} \
  && rm -rf ${HIPBLASLT_DIR} \
  && true
elevate_if_not_root apt --fix-broken install -y

# Install rocBLAS and export deb packages
git clone ${ROCBLAS_REPO} \
  && cd ${ROCBLAS_DIR} \
  && git checkout ${ROCBLAS_TAG} \
  && LESS="-R -F" git show --oneline -s \
  && ./install.sh -di
if [[ -d build/release ]]; then
  cd build/release \
  && cp *.deb ${ARTIFACTS_DIR} \
  && true
fi
cd ${SCRIPTS_DIR} \
  && rm -rf ${ROCBLAS_DIR} \
  && true
elevate_if_not_root apt --fix-broken install -y

# Install rocSOLVER and export deb packages
git clone ${ROCSOLVER_REPO} ${ROCSOLVER_DIR} \
  && cd ${ROCSOLVER_DIR} \
  && git checkout ${ROCSOLVER_TAG} \
  && LESS="-R -F" git show --oneline -s \
  && ./install.sh -ci --cmake-arg="-DROCSOLVER_FIND_PACKAGE_LAPACK_CONFIG=OFF"
if [[ -d build/release ]]; then
  cd build/release \
  && cp *.deb ${ARTIFACTS_DIR} \
  && true
fi
cd ${SCRIPTS_DIR} \
  && rm -rf ${ROCSOLVER_DIR} \
  && true
elevate_if_not_root apt --fix-broken install -y

set +x
