FROM compute-artifactory.amd.com:5000/rocm-plus-docker/compute-rocm-rel-6.4:108-ubuntu-22.04

ENV DEBIAN_FRONTEND=noninteractive

#
# Install software
#

# Required packages
RUN apt-get update && \
apt-get install -y dumb-init sudo && \
apt-get install -y git wget build-essential gfortran cmake cmake-format clang-format locales-all && \
apt-get clean

# Useful packages
RUN apt-get update && \
apt-get install -y vim zsh zsh-doc curl tmux git less man man-db mlocate && \
apt-get install -y keychain hwloc htop ccache bash-completion graphviz && \
apt-get install -y libgtest-dev libfmt-dev liblapack-dev libtmglib-dev libopenblas-serial-dev && \
apt-get clean

#
# Declare variables
# 
ARG DUID
ARG DGID
ARG DUSERNAME
ARG DHOME
ARG DSHELL
# The following two variables are not required if only targetting cuda
ARG DVGID
ARG DRGID

#
# Create user and complete system configuration
#
RUN addgroup --gid ${DGID} ${DUSERNAME} && \
useradd -d ${DHOME} -g ${DGID} --no-log-init --no-create-home -u ${DUID} --shell /bin/bash ${DUSERNAME} && \
adduser ${DUSERNAME} sudo

# The /var is only needed on lockhart?
RUN mkdir -p ${DHOME} /var/${DUSERNAME} && \
chown ${DUSERNAME}:${DUSERNAME} ${DHOME} /var/${DUSERNAME}
 
# Add user to video group if it exists on host (not necessary for cuda)
RUN if [ -n ${DVGID} ]; then \
# ((getent group | grep -Po "video:\w:\K\d+") || addgroup --gid ${DVGID} video) && \
# adduser ${DUSERNAME} video; \
((getent group | grep "${DVGID}") || addgroup --gid ${DVGID} video) && \
adduser ${DUSERNAME} $(getent group | grep "${DVGID}" | awk -F: '{print $1}'); \
fi

# Add user to render group if it exists on host (not necessary for cuda)
RUN if [ -n ${DRGID} ]; then \
# ((getent group | grep -Po "render:\w:\K\d+") || addgroup --gid ${DRGID} render) && \
# adduser ${DUSERNAME} render; \
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
