FROM scratch
COPY rootfs-22.04 /
CMD ["/bin/bash"]
# docker build -t ubuntu-rootfs -f /mnt/gs/open/rdh/dockerfile/ubuntu-rootfs.dockerfile .