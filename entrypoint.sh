#!/bin/sh
set -eu

NPROC=$(nproc)
steps=${1:-lzma-1,sha256-1,aes256-1,lzma,sha256,aes256,kernel}

i=0

step() {
    i=$((i + 1))
    echo "($i/$TOTAL) running $1"
}

run_step() {
    case "$1" in
        lzma-1)
            step "7zip LZMA (1 core)"
            7z b -mmt1
            ;;
        sha256-1)
            step "7zip SHA256 (1 core)"
            7z b -mm=SHA256 -mdf=22 -mmt1
            ;;
        aes256-1)
            step "7zip AES256CBC (1 core)"
            7z b -mm=AES256CBC -mdf=22 -mmt1
            ;;
        lzma)
            step "7zip LZMA ($NPROC cores)"
            7z b
            ;;
        sha256)
            step "7zip SHA256 ($NPROC cores)"
            7z b -mm=SHA256 -mdf=22 -mmts="$NPROC"
            ;;
        aes256)
            step "7zip AES256CBC ($NPROC cores)"
            7z b -mm=AES256CBC -mdf=22 -mmts="$NPROC"
            ;;
        kernel)
            step "kernel build"
            builddir=$(mktemp -d)
            make -C /usr/src/linux O="$builddir" tinyconfig >/dev/null
            start=$(date +%s)
            make -C /usr/src/linux O="$builddir" -j"$NPROC" >/dev/null
            echo "kernel built in $(($(date +%s) - start))s"
            rm -rf "$builddir"
            ;;
    esac
}

IFS=','
# shellcheck disable=SC2086 # intentional word splitting of the comma-separated step list
set -- $steps
IFS=' '

for s in "$@"; do
    case "$s" in
        lzma-1 | sha256-1 | aes256-1 | lzma | sha256 | aes256 | kernel) ;;
        *)
            echo "unknown step: $s" >&2
            exit 1
            ;;
    esac
done

TOTAL=$#

for s in "$@"; do
    run_step "$s"
done
