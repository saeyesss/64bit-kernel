# 64-bit OS Kernel

## Setup

- Docker for creating the build env.
- [gcc-cross-x86_64-elf](https://hub.docker.com/r/randomdude/gcc-cross-x86_64-elf) container to build a Debian image for the build env.
- Packages installed in the docker build env (check Dockerfile):
  - NASM to run the ASM instructions
  - Xorriso
  - GNU GRUB to use multiboot2 and building the final kernel ISO image
- Qemu for emulating our operating system.

---

## Steps to run

- Build an image for our build environment:
  `docker build buildenv -t myos-buildenv`
- Enter build environment:
  Windows (CMD): `docker run --rm -it -v "%cd%":/root/env myos-buildenv`
- Build for x86 arch:
  `make build-x86_64`
- Leave build env:
  `exit`
- Emulate the kernel using QEMU:
  `qemu-system-x86_64 -cdrom dist/x86_64/kernel.iso`
- To remove the build env image:
  `docker rmi myos-buildenv -f`
