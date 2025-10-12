ARG ROCM_VERSION=6.4.1
ARG ROCM_OS_VERSION=22.04
ARG ROCM_BASE=rocm/dev-ubuntu-${ROCM_OS_VERSION}:${ROCM_VERSION}
FROM ${ROCM_BASE} AS base
ARG SP3_ASIC
ARG TT_OPTS
RUN test -n "$SP3_ASIC" || (echo "--build-arg SP3_ASIC not set" && false)

RUN sudo apt-get update \
 && sudo apt-get install -y unzip vim parallel less cmake pkg-config libgmp-dev libboost-dev libboost-program-options-dev \
 && sudo apt-get install -y build-essential libanyevent-perl libclass-refresh-perl libcompiler-lexer-perl libdata-dump-perl \
 libio-aio-perl libjson-perl libmoose-perl libpadwalker-perl libscalar-list-utils-perl libcoro-perl libexcel-writer-xlsx-perl

RUN curl -O https://download.visualstudio.microsoft.com/download/pr/fea239ad-fd47-4764-aa71-6a147a82f632/20ee58b0bf08ae9f6e76e37ba3765c57/dotnet-runtime-3.1.32-linux-x64.tar.gz \
 && sudo mkdir -p /dotnet \
 && sudo tar zxf dotnet-runtime-3.1.32-linux-x64.tar.gz -C /dotnet
ENV DOTNET_ROOT="/dotnet" \
    PATH="$PATH:/dotnet"

RUN curl -LO https://get.haskellstack.org/stable/linux-x86_64.tar.gz \
 && sudo mkdir -p /stack \
 && sudo tar zxf linux-x86_64.tar.gz -C /stack \
 && sudo mv /stack/stack-*/* /stack
ENV PATH="$PATH:/stack"

# Install GHC for Shader Processor (not required but helps to reduce the build time when deployed from VS)
RUN stack setup --resolver lts-22.29
# Precompile dependencies for Shader Processor (not required but helps to reduce the build time when deployed from VS)
RUN stack build --resolver lts-22.29 --only-dependencies megaparsec vector unordered-containers indexed-traversable bytestring-trie half

RUN echo y | sudo perl -MCPAN -e 'CPAN::Shell->rematein("notest", "install", $_) for @ARGV' List::MoreUtils File::Slurp List::Compare Proc::ProcessTable Perl::LanguageServer

ENV CC=/opt/rocm/llvm/bin/clang CXX=/opt/rocm/llvm/bin/clang++

ENV SHISA="/SHISA" \
    PATH="/SHISA/bin:$PATH" \
    LD_LIBRARY_PATH="/SHISA/bin:/opt/rocm/lib/llvm/lib" \
    SP3_ASIC="$SP3_ASIC" \
    SP3_PREPROCESSOR="perl /SHISA/tools/scripts/preprocessor.pl" \
    SP3_PREPROCESSOR_INCLUDE_DIRS="/SHISA/shader_dev_SSP/include;/SHISA/shader_dev_IL/include;/SHISA/shader_dev/include/lib" \
    SP3_PREPROCESSOR_CONFIG_FILE="/SHISA/sp3_config.log" \
    SHISA_CLANG_BINARY="/opt/rocm/llvm/bin/clang" \
    SHISA_ELF_ABI="HSA" \
    TT_OPTS="$TT_OPTS"
