ARG ROCM_VERSION=6.4.1
ARG ROCM_OS_VERSION=22.04
ARG ROCM_BASE=rocm/dev-ubuntu-${ROCM_OS_VERSION}:${ROCM_VERSION}
FROM ${ROCM_BASE} AS base
RUN sudo apt-get update \
 && sudo apt-get install -y unzip vim parallel less cmake pkg-config libgmp-dev libboost-dev libboost-program-options-dev \
 && sudo apt-get install -y build-essential libanyevent-perl libclass-refresh-perl libcompiler-lexer-perl libdata-dump-perl \
 libio-aio-perl libjson-perl libmoose-perl libpadwalker-perl libscalar-list-utils-perl libcoro-perl libexcel-writer-xlsx-perl