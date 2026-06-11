#!/bin/sh
set -eu

TOTAL=10
i=0
NPROC=$(nproc)

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

dbdir=$(mktemp -d)
if ! mongod --dbpath "$dbdir" --bind_ip 127.0.0.1 --wiredTigerCacheSizeGB 1 \
        --fork --logpath "$dbdir/mongod.log" >/dev/null; then
    echo "mongod failed to start (this runtime likely lacks AVX support)" >&2
    exit 1
fi
step "mongodb insert"
ycsb load 0 0
step "mongodb read"
ycsb run 1 0
step "mongodb mixed"
ycsb run 0.5 0.5
mongod --dbpath "$dbdir" --shutdown >/dev/null
rm -rf "$dbdir"
