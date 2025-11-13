ARG ROCM_VERSION=7.0
ARG ROCM_OS_VERSION=24.04
FROM rocm/dev-ubuntu-${ROCM_OS_VERSION}:${ROCM_VERSION}

RUN sudo apt-get update && sudo apt-get install -y \
# Install general build dependencies
  rocm-llvm-dev git cmake xxd pkg-config libomp-dev libboost-dev libboost-program-options-dev \
# Install HSA dependencies
  libnuma-dev lld \
# Install PAL dependencies
  libxcb-dri2-0-dev libxcb-dri3-dev libxcb-present-dev libxcb-randr0-dev libxshmfence-dev libssl-dev \
# Install PAL Python dependencies
  python3-jinja2 python3-ruamel.yaml \
  git-lfs \
  dumb-init sudo

# Use Clang as the C/C++ compiler
ENV CC=/opt/rocm/llvm/bin/clang CXX=/opt/rocm/llvm/bin/clang++

# create docker user
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
