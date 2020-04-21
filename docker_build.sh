#!/bin/bash

# set the correct version numbers
export VERSION_UBUNTU=1804
export VERSION_RUST_SGX_SDK=1.1.1
export VERSION_INTEL_SGX_SDK=2.9
export VERSION_IPFS=0.4.21

set -ex

# build the docker image for development
docker build --target development \
    --build-arg VERSION_UBUNTU=$VERSION_UBUNTU \
    --build-arg VERSION_RUST_SGX_SDK=$VERSION_RUST_SGX_SDK \
    --build-arg VERSION_IPFS=$VERSION_IPFS \
    -t substratee_builder:$VERSION_UBUNTU-$VERSION_INTEL_SGX_SDK-$VERSION_RUST_SGX_SDK \
    -f ./Dockerfile .