#!/bin/bash
uver=24.04
#uver=22.04
tver=1.0
id=rocm-ai-ubuntu-${uver}-dbg:${tver}
#id=rocm-ai-ubuntu-${uver}:${tver}
docker run -it -p 2222:22 --device /dev/kfd --device /dev/dri/renderD128 $id