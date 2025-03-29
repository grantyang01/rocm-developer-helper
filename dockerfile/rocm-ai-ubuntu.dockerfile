ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION} AS installer
ARG UBUNTU_VERSION
ARG IS_DOCKER_BUILD=1

# copy amdgpuInstaler
COPY ai-${UBUNTU_VERSION} /app
WORKDIR /app
ENV DEBIAN_FRONTEND=noninteractive

# install amdgpuInstaller
# RUN apt-get update -y && \
#     apt-get upgrade -y && \
#     apt-get install pciutils -y && \
#     ./amdgpuInstaller --modules=rocm && \
#    rm -rf *

# clean up
FROM ubuntu:${UBUNTU_VERSION}
COPY --from=installer / /
CMD ["bash"]

# build:
# tver=1.0
# tag=ubuntu-24.04-ai:${tver}
# dfile=/home/grant/global-share/open/rdh/dockerfile/rocm-ai-ubuntu-24.04.dockerfile
#     docker build  -f "$dfile" -t "$tag" .
# launch
#     docker run -it "ubuntu-24.04-ai:1.0"
