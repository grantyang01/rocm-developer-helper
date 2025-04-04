#!/bin/bash
uver=24.04
#uver=22.04
tver=1.0
# id=rocm-ai-ubuntu-${uver}-dbg:${tver}
#id=rocm-ai-ubuntu-${uver}:${tver}
id=rocm/miopen:ci_dd7d81


# -p 2222:22: map container port 22 to host port 2222
# --cap-add=SYS_PTRACE: enable strace or gdb
# --security-opt seccomp=unconfined: Secure Computing Mode,  kernel feature 
#          restricting system calls (ptrace, mount, reboot, and unshare) 
#          available to containers.
# --ipc=host: container app use the host's IPC namespace(shared memory segments, 
#             semaphores, and message queues)
# --shm-size 8G: allocate 8 GB(default 64MB) of shared memory to the container's /dev/shm filesystem.
#                df -h /dev/shm

debug_option="-p 2222:22 `
            `--cap-add=SYS_PTRACE `
            `--security-opt seccomp=unconfined `
            `--ipc=host `
            `--shm-size 8G `
            `--device /dev/kfd `
            `--device /dev/dri/renderD128"

folder_option="-v /home/grant/global-share/open/rocm-test/MIOpen:/miopen"

# docker run -it $debug_option $id
docker run --rm -it -p 2222:22 $folder_option --shm-size 8G  --device /dev/kfd --device /dev/dri/renderD128 $id

# in container
# build MIDriver
mkdir build && cd build
CXX=/opt/rocm/llvm/bin/clang++ cmake `
`-DCMAKE_PREFIX_PATH="/opt/rocm" `
`-DCMAKE_BUILD_TYPE=Release `
`-DCMAKE_EXPORT_COMPILE_COMMANDS=1 ..

make MIOpenDriver -j 60
