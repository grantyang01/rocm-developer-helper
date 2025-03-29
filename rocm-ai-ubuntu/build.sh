#!/bin/bash
uver=22.04
#uver=24.04
tver=1.0
tag=rocm-ai-ubuntu-${uver}:${tver}
dfile=$(realpath ./rocm-ai-ubuntu.dockerfile)
docker build  -f "$dfile" -t "$tag" --build-arg UBUNTU_VERSION=$uver .
