ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION} AS installer
ARG IS_DOCKER_BUILD=1

# copy amgpuInstaler
COPY ai /app
WORKDIR /app
ENV DEBIAN_FRONTEND=noninteractive
EXPOSE 22

RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install pciutils openssh-server sudo vim -y && \
    ./amdgpuInstaller --modules=rocm && \
    rm -rf *

RUN mkdir /run/sshd

# Create dockeruser, and its in root group
# Create a new dockeruser and to the sudo/root group:
RUN useradd -m dockeruser && echo "dockeruser:111111" | chpasswd && adduser dockeruser sudo
RUN groupadd render
RUN usermod -aG root,video,render dockeruser

# Configure sudo to allow the new dockeruser run commands without a password:
RUN echo "dockeruser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# bash as default shell
RUN chsh -s /bin/bash dockeruser
USER dockeruser

# set up ssh public key for root and dockeruser
COPY --chmod=600 --chown=root:root .ssh/container.pub /root/.ssh/authorized_keys
COPY --chmod=600 --chown=dockeruser:dockeruser .ssh/container.pub /home/dockeruser/.ssh/authorized_keys

FROM ubuntu:${UBUNTU_VERSION}
COPY --from=installer / /
CMD ["bash", "-c", "/usr/sbin/sshd -D & bash"]

# build
# 24.04
#     docker build  -f /home/grant/global-share/open/rdh/dockerfile/rocm.dockerfile -t ubuntu-24.04-ai:1.0 .
# 22.04 
#     docker build  -f /home/grant/global-share/open/rdh/dockerfile/rocm.dockerfile -t ubuntu-22.04-ai:1.0 --build-arg UBUNTU_VERSION=22.04 .
# 
# launch container:
#   for dockeruser
#      docker run -it -p 2222:22 --device /dev/kfd --device /dev/dri/renderD128 --entrypoint /bin/bash "$id" -c "chgrp render /dev/kfd /dev/dri/renderD128 && /usr/sbin/sshd -D & bash"
#   for root
#      docker run -it -p 2222:22 --device /dev/kfd --device /dev/dri/renderD128 "$id"
# 
# ssh as dockeruser:
#   ssh dockeruser@192.168.2.22 -p 2222 -i ~/.ssh/container
# ssh as root:
#   ssh root@192.168.2.22 -p 2222 -i ~/.ssh/container
# 
# config and connect:
# container
#    HostName 192.168.2.22 
#    Port 2222
#    User dockeruser
#    IdentityFile ~/.ssh/container
# ssh from config
#   ssh container
# 
# create render group
#    groupadd render
#    usradd -a -G render,video dockeruser
