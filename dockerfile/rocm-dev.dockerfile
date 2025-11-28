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
ENV CMAKE_PREFIX_PATH=/opt/rocm-${ROCM_VER}
ENV PATH=/opt/rocm-${ROCM_VER}/bin:/opt/rocm-${ROCM_VER}/lib/llvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin

# step1: install os packages
# rocm dev required packages
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y ca-certificates cmake git git-lfs doxygen wget libssl-dev zlib1g-dev libfmt-dev python3-venv python3-pip python3-packaging && \
    apt-get clean

# hipblaslt required packages
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y libblis-dev && \
    apt-get clean

# rocBLAS rocSolver required packages
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y dumb-init sudo && \
    apt-get install -y build-essential gfortran cmake-format clang-format locales-all && \
    apt-get clean

# Cursor IDE requires clangd for cross-reference C++ code
RUN apt-get update -y && \
    apt-get install -y clangd && \
    apt-get clean

# clr
#RUN python3 -m pip install cxxheaderparser

# unknown below python pkgs missed?
#RUN python3 -m pip install CppHeaderParser joblib ply psutil msgpack regex

# Install available packages via apt
RUN apt-get install -y \
    python3-joblib \
    python3-ply \
    python3-psutil \
    python3-msgpack

# Install remaining packages via pip with --break-system-packages
RUN python3 -m pip install --break-system-packages \
    cxxheaderparser \
    CppHeaderParser \
    regex

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

# SSH server for remote development (required for connecting to container via SSH)
# Purpose: 
# 1. Cursor IDE doesn't have "Attach to Running Container" like VSCode does
# 2. SSH server in container allows Cursor IDE to connect to running containers
# 3. VSCode can also use SSH server for remote development
#
# How to use:
#    Connect from remote machine to container on host machine:
# 1. Start SSH in container after launch: sudo /usr/sbin/sshd or rd-ssh-server
# 2. Configure SSH on client machine (~/.ssh/config):
#   Host host_machine
#       HostName <host_machine_hostname_or_ip>
#       User <username>
#   
#   Host mycontainer
#       HostName <container_ip>  # Get with: docker inspect <container> -f '{{.NetworkSettings.IPAddress}}'
#       User <username>
#       Port 22
#       ProxyJump host_machine
# 3. Connect: ssh mycontainer (or use Remote-SSH in Cursor/VSCode)
# 4. Environment variables in debug sessions:
#    4.1 Pre-built environment variables from the image are not inherited in
#        debug sessions (launch.json). Workaround: set them in launch.json 
#        environment section.
#    4.2 Use script `d2v` (in rdh/scripts/) to export container/image env vars
#        in VSCode launch.json format for copy-paste.
#        Example: d2v <container_name> | pbcopy
RUN apt-get update -y && \
    apt-get install -y openssh-server && \
    mkdir -p /run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    apt-get clean

# Expose SSH port
EXPOSE 22

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
