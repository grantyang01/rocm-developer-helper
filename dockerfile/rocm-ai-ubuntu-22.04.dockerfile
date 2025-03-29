FROM ubuntu:22.04 AS installer
ARG IS_DOCKER_BUILD=1

# copy amdgpuInstaler
COPY ai-22.04 /app
WORKDIR /app
ENV DEBIAN_FRONTEND=noninteractive

# install amdgpuInstaller
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install pciutils -y && \
    ./amdgpuInstaller --modules=rocm && \
    rm -rf *

# clean up
FROM ubuntu:22.04
COPY --from=installer / /
CMD ["bash"]

# build:
# tver=1.0
# tag=ubuntu-22.04-ai:${tver}
# dfile=/home/grant/global-share/open/rdh/dockerfile/rocm-ai-ubuntu-22.04.dockerfile
#     docker build  -f "$dfile" -t "$tag" .
# launch:
#     docker run -it "ubuntu-22.04-ai:1.0"
