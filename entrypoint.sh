#!/bin/sh
set -eu

TOTAL=3
i=0

step() {
    i=$((i + 1))
    echo "($i/$TOTAL) running $1"
}

step "7zip LZMA"
7z b -mtime=7
step "7zip SHA256"
7z b -mtimems=3300 -mm=SHA256
step "7zip AES256CBC"
7z b -mtimems=3300 -mm=AES256CBC
