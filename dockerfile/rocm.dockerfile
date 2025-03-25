FROM ubuntu:24.04 AS base
RUN apt-get update -y && apt-get upgrade -y && apt-get install pciutils -y
ENV DEBIAN_FRONTEND=noninteractive
ARG IS_DOCKER_BUILD=1
COPY ai /app
WORKDIR /app
RUN ./amdgpuInstaller --modules=rocm
CMD ["bash"]

