ARG ROCM_VERSION=6.4.1
ARG ROCM_OS_VERSION=22.04
ARG ROCM_BASE=rocm/dev-ubuntu-${ROCM_OS_VERSION}:${ROCM_VERSION}
FROM ${ROCM_BASE} AS base
ARG SP3_ASIC
ARG TT_OPTS
RUN test -n "$SP3_ASIC" || (echo "--build-arg SP3_ASIC not set" && false)

RUN sudo apt-get update \
 && sudo apt-get install -y \
    unzip vim parallel less cmake pkg-config \
    libgmp-dev libboost-dev libboost-program-options-dev \
    libfmt-dev libdw-dev libmkl-dev \
    rocblas-dev gfortran rocprim-dev \
    dotnet-runtime-8.0 \
    build-essential \
    libanyevent-perl libclass-refresh-perl libcompiler-lexer-perl \
    libdata-dump-perl libio-aio-perl libjson-perl libmoose-perl \
    libpadwalker-perl libscalar-list-utils-perl libcoro-perl \
    libexcel-writer-xlsx-perl \
    haskell-stack \
    libmsgpack-dev google-mock googletest libgmock-dev

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
