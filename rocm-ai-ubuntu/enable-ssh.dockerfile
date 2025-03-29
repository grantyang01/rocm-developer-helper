ARG IMAGE_NAME=rocm-ai-ubuntu-24.04
ARG IMAGE_TAG=1.0
ARG USER=du
ARG UPWD=du
ARG UBUNTU_VERSION=24.04

FROM ${IMAGE_NAME}:${IMAGE_TAG} AS base
ARG IMAGE_NAME
ARG IMAGE_TAG
ARG USER
ARG UPWD
ARG UBUNTU_VERSION

RUN echo name:${IMAGE_NAME}
RUN echo name:${IMAGE_ID}

# install openssh-server for ssh, sudo for dockeruser, vim for basic edit
ENV DEBIAN_FRONTEND=noninteractive
RUN sudo apt-get install openssh-server sudo vim -y 

EXPOSE 22
RUN mkdir /run/sshd

# Create dockeruser, and its in root group
# Create a new dockeruser and to the sudo/root group:
    
RUN useradd -m ${USER} && echo "${USER}:${UPWD}" | chpasswd && adduser ${USER} sudo
RUN groupadd render
RUN usermod -aG root,video,render ${USER}

# Configure sudo to allow the new dockeruser run commands without a password:
RUN echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# bash as default shell
RUN chsh -s /bin/bash ${USER}
USER ${USER}

# set up ssh public key for root and dockeruser
COPY --chmod=600 --chown=root:root .ssh/container.pub /root/.ssh/authorized_keys
COPY --chmod=600 --chown=${USER}:${USER} .ssh/container.pub /home/${USER}/.ssh/authorized_keys

FROM ubuntu:${UBUNTU_VERSION}
COPY --from=base / /
CMD ["bash", "-c", "chgrp render /dev/kfd /dev/dri/renderD128 && /usr/sbin/sshd -D & bash"]

# manually build:
# uver=24.04     or 22.04
# tver=1.0
# src_image=rocm-ai-ubuntu-${uver}
# tag=${src_image}-dbg:${tver}
# user=du
# passwd=du
# dfile=$(realpath ./enable-ssh.dockerfile)
#       docker build -f "$dfile" -t "$tag" --build-arg IMAGE_NAME="$src_image" --build-arg IMAGE_TAG=$tver --build-arg USER=$user --build-arg UPWD=$passwd --build-arg UBUNTU_VERSION=$uver .