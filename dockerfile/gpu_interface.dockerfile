ARG ROCM_VERSION=6.4.1
ARG ROCM_OS_VERSION=22.04
FROM rocm/dev-ubuntu-${ROCM_OS_VERSION}:${ROCM_VERSION}

RUN sudo apt-get update && sudo apt-get install -y \
# Install general build dependencies
  rocm-llvm-dev git cmake xxd pkg-config libomp-dev libboost-dev libboost-program-options-dev \
# Install HSA dependencies
  libnuma-dev lld \
# Install PAL dependencies
  libxcb-dri2-0-dev libxcb-dri3-dev libxcb-present-dev libxcb-randr0-dev libxshmfence-dev libssl-dev \
  git-lfs

# Install PAL Python dependencies
RUN python3 -m pip install jinja2 ruamel.yaml

# Use Clang as the C/C++ compiler
ENV CC=/opt/rocm/llvm/bin/clang CXX=/opt/rocm/llvm/bin/clang++