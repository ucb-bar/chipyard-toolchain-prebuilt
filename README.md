# Pre-built RISC-V GNU toolchain for Chipyard

This is a crude but efficient mechanism for distributing
[riscv-gnu-toolchain](https://github.com/riscv/riscv-gnu-toolchain)
binaries for [Chipyard](https://github.com/ucb-bar/chipyard).

## Installing a release

    make DESTDIR="$RISCV" install

This extracts both `riscv64-unknown-elf` and `riscv64-unknown-linux-gnu`
toolchains into the installation path given by `$RISCV`.

## Building a new release

    make dist

Then commit the `HASH` and `dist/pkg.tar.*` files.
Watch for QA warnings about non-portable RPATHs being detected.

The sources are assumed to be checked out in `../riscv-gnu-toolchain`
relative to this working tree, matching the directory structure of
Chipyard.  This can be overridden by setting the `SRCDIR` make variable.
