ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION} AS installer
ARG IS_DOCKER_BUILD=1
COPY ai /app
WORKDIR /app
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install pciutils -y && \
    ./amdgpuInstaller --modules=rocm && \
    rm -rf *
CMD ["bash"]
FROM ubuntu:${UBUNTU_VERSION}
COPY --from=installer / /
