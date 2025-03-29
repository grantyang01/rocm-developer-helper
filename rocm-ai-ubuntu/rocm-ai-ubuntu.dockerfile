ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION} AS installer
ARG UBUNTU_VERSION
ARG IS_DOCKER_BUILD=1

# copy amdgpuInstaler
COPY ai-${UBUNTU_VERSION} /app
WORKDIR /app
ENV DEBIAN_FRONTEND=noninteractive

# install amdgpuInstaller
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install pciutils -y && \
    ./amdgpuInstaller --modules=rocm && \
    rm -rf *

# clean up
FROM ubuntu:${UBUNTU_VERSION}
COPY --from=installer / /

CMD ["bash"]

# build:
# uver=24.04   or 22.04
# tver=1.0
# tag=rocm-ai-ubuntu-${uver}:${tver}
# dfile=$(realpath ./rocm-ai-ubuntu.dockerfile)
#     docker build  -f "$dfile" -t "$tag" --build-arg UBUNTU_VERSION=$uver .
# launch
#     docker run -it "rocm-ai-ubuntu-${uver}:${tver}"
