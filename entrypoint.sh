#!/bin/sh
set -eu

7z b
7z b -mm=SHA256
7z b -mm=AES256CBC
