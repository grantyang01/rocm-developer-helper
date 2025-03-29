#!/bin/bash
# uver=24.04
uver=22.04
tver=1.0
src_image=rocm-ai-ubuntu-${uver}
tag=${src_image}-dbg:${tver}
user=du
passwd=du
dfile=$(realpath ./enable-ssh.dockerfile)
docker build -f "$dfile" -t "$tag" `
        `--build-arg IMAGE_NAME="$src_image" `
        `--build-arg IMAGE_TAG=$tver `
        `--build-arg USER=$user `
        `--build-arg UPWD=$passwd `
        `--build-arg UBUNTU_VERSION=$uver .