#!/bin/bash

# Use go 1.23.8 to run this to make 0.25.5 reproducible

PATH="`pwd`/fakegit:$PATH" make esbuild platform-darwin-arm64 platform-linux-x64
echo
shasum esbuild npm/@esbuild/*/bin/*
