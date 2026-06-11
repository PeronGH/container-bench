#!/bin/sh
set -eu

NPROC=$(nproc)
steps=${1:-lzma-1,sha256-1,aes256-1,lzma,sha256,aes256,kernel,mongo-insert,mongo-read,mongo-mixed}

i=0

step() {
    i=$((i + 1))
    echo "($i/$TOTAL) running $1"
}

ycsb() {
    go-ycsb "$1" mongodb \
        -p workload=core \
        -p recordcount=100000 \
        -p operationcount=200000 \
        -p threadcount="$NPROC" \
        -p readproportion="$2" \
        -p updateproportion="$3"
}

mongod_up=
mongo_loaded=

start_mongod() {
    [ -n "$mongod_up" ] && return
    dbdir=$(mktemp -d)
    if ! mongod --dbpath "$dbdir" --bind_ip 127.0.0.1 --wiredTigerCacheSizeGB 1 \
            --fork --logpath "$dbdir/mongod.log" >/dev/null; then
        echo "mongod failed to start (this runtime likely lacks AVX support)" >&2
        exit 1
    fi
    mongod_up=1
}

ensure_loaded() {
    [ -n "$mongo_loaded" ] && return
    ycsb load 0 0 >/dev/null
    mongo_loaded=1
}

run_step() {
    case "$1" in
        lzma-1)
            step "7zip LZMA (1 core)"
            7z b -mmt1
            ;;
        sha256-1)
            step "7zip SHA256 (1 core)"
            7z b -mm=SHA256 -mmt1
            ;;
        aes256-1)
            step "7zip AES256CBC (1 core)"
            7z b -mm=AES256CBC -mmt1
            ;;
        lzma)
            step "7zip LZMA ($NPROC cores)"
            7z b
            ;;
        sha256)
            step "7zip SHA256 ($NPROC cores)"
            7z b -mm=SHA256 -mmts="$NPROC"
            ;;
        aes256)
            step "7zip AES256CBC ($NPROC cores)"
            7z b -mm=AES256CBC -mmts="$NPROC"
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
        mongo-insert)
            start_mongod
            step "mongodb insert"
            ycsb load 0 0
            mongo_loaded=1
            ;;
        mongo-read)
            start_mongod
            ensure_loaded
            step "mongodb read"
            ycsb run 1 0
            ;;
        mongo-mixed)
            start_mongod
            ensure_loaded
            step "mongodb mixed"
            ycsb run 0.5 0.5
            ;;
    esac
}

IFS=','
# shellcheck disable=SC2086 # intentional word splitting of the comma-separated step list
set -- $steps
IFS=' '

for s in "$@"; do
    case "$s" in
        lzma-1 | sha256-1 | aes256-1 | lzma | sha256 | aes256 | kernel | mongo-insert | mongo-read | mongo-mixed) ;;
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

if [ -n "$mongod_up" ]; then
    mongod --dbpath "$dbdir" --shutdown >/dev/null
    rm -rf "$dbdir"
fi
