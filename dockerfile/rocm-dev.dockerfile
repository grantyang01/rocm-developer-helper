ARG UBUNTU_VERSION=24.04
ARG UBUNTU_CODENAME=noble

FROM ubuntu:${UBUNTU_VERSION} AS installer
ARG UBUNTU_VERSION
ARG UBUNTU_CODENAME
ARG GFX_BUILD
ARG ROCM_BRANCH
ARG ROCM_BUILD
ARG ROCM_VER

RUN test -n "${GFX_BUILD}" || (echo "Error: GFX_BUILD is not set" >&2 && exit 1) && \
    test -n "${ROCM_BRANCH}" || (echo "Error: ROCM_BRANCH is not set" >&2 && exit 1) && \
    test -n "${ROCM_BUILD}" || (echo "Error: ROCM_BUILD is not set" >&2 && exit 1) && \
    test -n "${ROCM_VER}" || (echo "Error: ROCM_VER is not set" >&2 && exit 1)

ENV DEBIAN_FRONTEND=noninteractive

# well-known env variables for ROCM
ENV ROCM_VERSION=${ROCM_VER}
ENV ROCM_PATH=/opt/rocm-${ROCM_VER}
ENV ROCM_ROOT=/opt/rocm-${ROCM_VER}
ENV PATH=/opt/rocm-${ROCM_VER}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin

# step1: install os packages
# rocm dev required packages
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y ca-certificates cmake git git-lfs doxygen wget libssl-dev zlib1g-dev libfmt-dev python3-venv python3-pip && \
    apt-get clean

# rocBLAS rocSolver required packages
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y dumb-init sudo && \
    apt-get install -y build-essential gfortran cmake-format clang-format locales-all && \
    apt-get clean

# clr
RUN python3 -m pip install cxxheaderparser

# rocprofile sdk required packages
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y libdw-dev libsqlite3-dev && \
    apt-get clean

# Useful packages
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y vim zsh zsh-doc curl tmux git less man man-db jq && \
    apt-get install -y keychain hwloc htop ccache bash-completion graphviz && \
    apt-get install -y libgtest-dev libfmt-dev liblapack-dev libtmglib-dev libopenblas-serial-dev && \
    if [ "$UBUNTU_VERSION" = "24.04" ]; then \
      apt-get install -y plocate; \
    else \
      apt-get install -y mlocate; \
    fi && \   
    apt-get clean

# step 2: setup drivers
# generate amdgpu-build.list, sample:
RUN echo "Adding amdgpu-build.list: ${GFX_BUILD} ${UBUNTU_CODENAME}" && \
    echo "deb [trusted=yes] https://mkmartifactory.amd.com/artifactory/list/amdgpu-deb-remote ${GFX_BUILD} ${UBUNTU_CODENAME}" \
    > /etc/apt/sources.list.d/amdgpu-build.list

# generate rocm-build.list, sample:
RUN echo "Adding rocm-build.list: ${UBUNTU_VERSION} ${ROCM_BRANCH} ${ROCM_BUILD}" && \
    echo "deb [arch=amd64 Signed-By=/etc/apt/trusted.gpg.d/rocm-internal.gpg] https://compute-cdn.amd.com/artifactory/list/rocm-osdb-${UBUNTU_VERSION}-deb ${ROCM_BRANCH} ${ROCM_BUILD}" \
    > /etc/apt/sources.list.d/rocm-build.list

# generate /etc/apt/preferences.d/artifactory-pin-600
RUN mkdir -p /etc/apt/preferences.d && \
    printf "Package: *\nPin: release o=Artifactory\nPin-Priority: 600\n" \
    > /etc/apt/preferences.d/artifactory-pin-600

# copy /etc/apt/trusted.gpg.d/rocm-internal.gpg
COPY rocm-internal.gpg /etc/apt/trusted.gpg.d/

# install rocm and rocm-dev
RUN apt-get update -y && \
    apt-get install rocm rocm-dev -y && \
    apt-get clean

# custom step: pkgs for benchmark and test of rocsolver
RUN apt-get update -y && \
    apt-get install -y rocsolver-benchmarks rocsolver-clients rocsolver-tests && \
    apt-get clean

# build clr need packages
RUN apt-get update -y && \
    apt-get install rocm-hip-libraries rocm-llvm-dev -y && \
    apt-get clean

# update cmake to 3.25.2 for ubuntu 22.04(default 3.22, which will fail rocBLAS build)
# ARG CMAKE_VER=3.25.2
# 3.28.3: ubuntu 24.04
ARG CMAKE_VER=3.28.3

RUN if [ "${UBUNTU_VERSION}" = "22.04" ]; then \
        wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VER}/cmake-${CMAKE_VER}.tar.gz && \
        tar -zxvf cmake-${CMAKE_VER}.tar.gz && \
        cd cmake-${CMAKE_VER} && \
        ./bootstrap && \
        make -j$(nproc) && \
        make install && \
        cd .. && \
        rm -rf cmake-${CMAKE_VER} cmake-${CMAKE_VER}.tar.gz; \
    else \
      echo "Skipping CMake ${CMAKE_VER} build for Ubuntu version ${UBUNTU_VERSION}"; \
    fi

# step 4: create docker user
ARG DUID
ARG DGID
ARG DUSERNAME
ARG DHOME
ARG DSHELL
ARG DVGID
ARG DRGID

RUN test -n "${DUID}" || (echo "Error: DUID is not set" >&2 && exit 1) && \
    test -n "${DGID}" || (echo "Error: DGID is not set" >&2 && exit 1) && \
    test -n "${DUSERNAME}" || (echo "Error: DUSERNAME is not set" >&2 && exit 1) && \
    test -n "${DHOME}" || (echo "Error: DHOME is not set" >&2 && exit 1) && \
    test -n "${DSHELL}" || (echo "Error: DSHELL is not set" >&2 && exit 1) && \
    test -n "${DVGID}" || (echo "Error: DVGID is not set" >&2 && exit 1) && \
    test -n "${DRGID}" || (echo "Error: DRGID is not set" >&2 && exit 1)

RUN addgroup --gid ${DGID} ${DUSERNAME} && \
    useradd -d ${DHOME} -g ${DGID} --no-log-init --no-create-home -u ${DUID} --shell /bin/bash ${DUSERNAME} && \
    adduser ${DUSERNAME} sudo

# The /var is only needed on lockhart?
RUN mkdir -p ${DHOME} /var/${DUSERNAME} && \
    chown ${DUSERNAME}:${DUSERNAME} ${DHOME} /var/${DUSERNAME}
 
# Add user to video group if it exists on host (not necessary for cuda)
RUN if [ -n ${DVGID} ]; then \
        ((getent group | grep "${DVGID}") || addgroup --gid ${DVGID} video) && \
        adduser ${DUSERNAME} $(getent group | grep "${DVGID}" | awk -F: '{print $1}'); \
    fi

# Add user to render group if it exists on host (not necessary for cuda)
RUN if [ -n ${DRGID} ]; then \
        ((getent group | grep "${DRGID}") || addgroup --gid ${DRGID} render) && \
        adduser ${DUSERNAME} $(getent group | grep "${DRGID}" | awk -F: '{print $1}'); \
    fi

# If sudo is installed then make it work without a password
RUN if [ -f /etc/sudoers ]; then \
        sed -i~ -e 's/%sudo\tALL=(ALL:ALL) ALL/%sudo\tALL=(ALL:ALL) NOPASSWD:ALL/g' /etc/sudoers; \
    fi
 
USER ${DUSERNAME}
WORKDIR ${DHOME}
ENV HOME=${DHOME}
 
 # Given a `CMD ["/my/script", "--with", "--args"]`, this yields "/usr/bin/dumb-init -- /my/script --with --args"
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Set default command for `docker run` (default: use "/bin/bash")
CMD ["/bin/bash"]
