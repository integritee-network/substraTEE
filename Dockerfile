# Copyright 2020 Supercomputing Systems AG
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#           http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Generic Dockerfile for Intel SGX development and CI machines
#  Based on Ubuntu
#  Intel SGX SDK and PSW installed
#  Rust-sgx-sdk installed
#  IPFS installed
# Use the script 'docker_build.sh' to build the docker image

# The docker image can be downloaded from
# https://hub.docker.com/repository/docker/scssubstratee/substratee_dev/

ARG VERSION_UBUNTU
ARG VERSION_RUST_SGX_SDK

FROM baiduxlab/sgx-rust:$VERSION_UBUNTU-$VERSION_RUST_SGX_SDK as development

ARG VERSION_IPFS
RUN echo "VERSION_IPFS = ${VERSION_IPFS}"

SHELL ["/bin/bash", "-c"]

# install rsync
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    rsync && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/apt/archives/*

# install ipfs
RUN mkdir -p /ipfs && \
    cd /ipfs && \
    wget -O go-ipfs.tar.gz https://dist.ipfs.io/go-ipfs/v${VERSION_IPFS}/go-ipfs_v${VERSION_IPFS}_linux-amd64.tar.gz && \
    tar xvfz go-ipfs.tar.gz && \
    cd go-ipfs && \
    ./install.sh

# install WASM toolchain
RUN /root/.cargo/bin/rustup target install wasm32-unknown-unknown

# install packages needed for substrate
RUN apt-get update && \
    apt-get install -y cmake pkg-config libssl-dev git gcc build-essential clang libclang-dev && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/apt/archives/*

# install LLVM to compile ring into WASM
RUN apt-get update && \
    wget https://apt.llvm.org/llvm.sh && \
    chmod +x llvm.sh && \
    sudo ./llvm.sh 10 && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/apt/archives/*

# install additional tools
RUN apt-get update && \
    apt-get install -y tmux nano && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/apt/archives/*

# set environment variables
ENV DEBIAN_FRONTEND noninteractive
ENV TERM xterm
ENV SGX_SDK /opt/sgxsdk
ENV PATH "$PATH:${SGX_SDK}/bin:${SGX_SDK}/bin/x64:/root/.cargo/bin"
ENV PKG_CONFIG_PATH "${PKG_CONFIG_PATH}:${SGX_SDK}/pkgconfig"
ENV LD_LIBRARY_PATH "${LD_LIBRARY_PATH}:${SGX_SDK}/sdk_libs"
ENV CC /usr/bin/clang-10
ENV AR /usr/bin/llvm-ar-10
