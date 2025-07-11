ARG UBUNTU_VERSION=24.04
ARG UBUNTU_CODENAME=noble
ARG GFX_BUILD
ARG ROCM_BRANCH
ARG ROCM_BUILD

FROM ubuntu:${UBUNTU_VERSION} AS installer
ARG UBUNTU_VERSION
ARG UBUNTU_CODENAME
ARG GFX_BUILD
ARG ROCM_BRANCH
ARG ROCM_BUILD

RUN test -n "${GFX_BUILD}" || (echo "Error: GFX_BUILD is not set" >&2 && exit 1) && \
    test -n "${ROCM_BRANCH}" || (echo "Error: ROCM_BRANCH is not set" >&2 && exit 1) && \
    test -n "${ROCM_BUILD}" || (echo "Error: ROCM_BUILD is not set" >&2 && exit 1)

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y ca-certificates cmake git git-lfs doxygen wget libssl-dev zlib1g-dev libfmt-dev

# generate amdgpu-build.list, sample:
# deb [trusted=yes] https://mkmartifactory.amd.com/artifactory/list/amdgpu-deb-remote 2187240 noble
RUN echo "Adding amdgpu-build.list: ${GFX_BUILD} ${UBUNTU_CODENAME}" && \
    echo "deb [trusted=yes] https://mkmartifactory.amd.com/artifactory/list/amdgpu-deb-remote ${GFX_BUILD} ${UBUNTU_CODENAME}" \
    > /etc/apt/sources.list.d/amdgpu-build.list

# generate rocm-build.list, sample:
# deb [arch=amd64 Signed-By=/etc/apt/trusted.gpg.d/rocm-internal.gpg] https://compute-cdn.amd.com/artifactory/list/rocm-osdb-24.04-deb compute-rocm-dkms-no-npi-hipclang 16381
RUN echo "Adding rocm-build.list: ${UBUNTU_VERSION} ${ROCM_BRANCH} ${ROCM_BUILD}" && \
    echo "deb [arch=amd64 Signed-By=/etc/apt/trusted.gpg.d/rocm-internal.gpg] https://compute-cdn.amd.com/artifactory/list/rocm-osdb-${UBUNTU_VERSION}-deb ${ROCM_BRANCH} ${ROCM_BUILD}" \
    > /etc/apt/sources.list.d/rocm-build.list

# generate /etc/apt/preferences.d/artifactory-pin-600
RUN mkdir -p /etc/apt/preferences.d && \
    printf "Package: *\nPin: release o=Artifactory\nPin-Priority: 600\n" > /etc/apt/preferences.d/artifactory-pin-600

# copy /etc/apt/trusted.gpg.d/rocm-internal.gpg
COPY rocm-internal.gpg /etc/apt/trusted.gpg.d/

# install rocm
RUN apt-get update -y && \
    apt-get install rocm -y

# RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# update cmake to 3.28 for ubuntu 22.04(default 3.22, which will fail rocBLAS build)
RUN if [ "${UBUNTU_VERSION}" = "22.04" ]; then \
        wget https://github.com/Kitware/CMake/releases/download/v3.28.0/cmake-3.28.0.tar.gz && \
        tar -zxvf cmake-3.28.0.tar.gz && \
        cd cmake-3.28.0 && \
        ./bootstrap && \
        make -j$(nproc) && \
        make install && \
        cd .. && \
        rm -rf cmake-3.28.0 cmake-3.28.0.tar.gz; \
    else \
      echo "Skipping CMake 3.28 build for Ubuntu version ${UBUNTU_VERSION}"; \
    fi
