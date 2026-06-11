#!/bin/sh
set -eu

TOTAL=6
i=0
NPROC=$(nproc)

step() {
    i=$((i + 1))
    echo "($i/$TOTAL) running $1"
}

step "7zip LZMA (1 core)"
7z b -mmt1
step "7zip LZMA (all cores)"
7z b
step "7zip SHA256 (1 core)"
7z b -mm=SHA256 -mmt1
step "7zip SHA256 (all cores)"
7z b -mm=SHA256 -mmts="$NPROC"
step "7zip AES256CBC (1 core)"
7z b -mm=AES256CBC -mmt1
step "7zip AES256CBC (all cores)"
7z b -mm=AES256CBC -mmts="$NPROC"
