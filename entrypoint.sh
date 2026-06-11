#!/bin/sh
set -eu

TOTAL=7
i=0
NPROC=$(nproc)

step() {
    i=$((i + 1))
    echo "($i/$TOTAL) running $1"
}

step "7zip LZMA (1 core)"
7z b -mmt1
step "7zip SHA256 (1 core)"
7z b -mm=SHA256 -mmt1
step "7zip AES256CBC (1 core)"
7z b -mm=AES256CBC -mmt1
step "7zip LZMA ($NPROC cores)"
7z b
step "7zip SHA256 ($NPROC cores)"
7z b -mm=SHA256 -mmts="$NPROC"
step "7zip AES256CBC ($NPROC cores)"
7z b -mm=AES256CBC -mmts="$NPROC"
step "kernel build"
builddir=$(mktemp -d)
make -C /usr/src/linux O="$builddir" tinyconfig >/dev/null
start=$(date +%s)
make -C /usr/src/linux O="$builddir" -j"$NPROC" >/dev/null
echo "kernel built in $(($(date +%s) - start))s"
rm -rf "$builddir"
