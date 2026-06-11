#!/bin/sh
set -eu

echo "(1/3) running 7zip LZMA"
7z b -mtime=7
echo "(2/3) running 7zip SHA256"
7z b -mtimems=3300 -mm=SHA256
echo "(3/3) running 7zip AES256CBC"
7z b -mtimems=3300 -mm=AES256CBC
