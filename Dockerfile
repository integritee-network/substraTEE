
ARG VERSION_UBUNTU
ARG VERSION_RUST_SGX_SDK

FROM baiduxlab/sgx-rust:$VERSION_UBUNTU-$VERSION_RUST_SGX_SDK as builder

ARG VERSION_IPFS
RUN echo "VERSION_IPFS = ${VERSION_IPFS}"

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM xterm

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

# source SGX and rust environment
RUN /bin/bash -c "source /opt/sgxsdk/environment" && \
    /bin/bash -c "source /root/.cargo/env"

# install WASM toolchain
RUN /root/.cargo/bin/rustup target install wasm32-unknown-unknown