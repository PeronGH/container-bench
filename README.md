# container-bench

Benchmark suite in a container: an offline `apt install` of the benchmark
toolchain, 7-Zip (LZMA, SHA256, AES256CBC), and a Linux kernel `tinyconfig`
build. Built for comparing container runtimes; published for `linux/amd64`
and `linux/arm64`.

## Usage

```sh
docker pull ghcr.io/perongh/container-bench:latest
docker run --rm ghcr.io/perongh/container-bench
```

Run a subset of steps by passing a comma-separated list:

```sh
docker run --rm ghcr.io/perongh/container-bench lzma-1,sha256,kernel
```

Every run starts with a timed apt install → purge → install cycle of the
pre-downloaded benchmark toolchain (7zip, gcc, make, ...) — the image ships
the `.deb`s but nothing installed, so this doubles as a package-install
benchmark. The remaining steps run in the order given:

| Step | Workload |
| --- | --- |
| `lzma-1`, `lzma` | 7-Zip LZMA benchmark, 1 core / all cores |
| `sha256-1`, `sha256` | 7-Zip SHA256 benchmark, 1 core / all cores |
| `aes256-1`, `aes256` | 7-Zip AES256CBC benchmark, 1 core / all cores |
| `kernel` | Linux kernel tinyconfig build, timed |
