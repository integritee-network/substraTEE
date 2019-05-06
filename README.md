# substraTEE

[substrate](https://docs.substrate.dev/) runtime in Trusted Execution Environment

*substraTEE* is an extension to [Parity Substrate](https://docs.substrate.dev/), allowing to call a custom state transition function inside a Trusted Execution Environment (TEE), namely an Intel SGX enclave thereby providing confidentiality and integrity. The enclaves operate on an encrypted state which can be read and written only by a set of provisioned and remote-attested enclaves.
*substraTEE* enables use cases demanding transaction privacy as well as atomic cross-chain transfers (bridges).

## Concept Study

Different use cases for TEE's and potential software architectures have been analyzed and compared in [CONCEPTS](./CONCEPTS.md).
In the following we'll refer to the *substraTEE-worker* architecture, which has been implemented because it supports the widest range of use cases.

## Roadmap

### M1 PoC1: single-TEE confidential state transition function
off-chain worker runs STF within an Intel SGX enclave. The state is persisted in a sealed file which can only be read by that very enclave.

The demo STF will be a simple counter.

### M2 PoC2: single-TEE confidential state transition function in WASM
In addition to M1, the STF is defined by WASM code which is run by a WASMI interpreter within an Intel SGX enclave.

The demo STF will be a simple counter.

### M3 simple enclave provisioning
multiple workers can be assigned to a particular STF (contract). Only one of the enclaves will be master, the others serve as a failover backup.
Additional enclaves join by supplying remote attestation (RA) from Intel IAS and get group keys from partially trusted provisioning services (PS).

### M4 enclave provisioning 
Enhanced provisioning (get rid of partially trusted PS).

enclave joins by supplying RA. With every enclave membership change group keys are renewed using dynamic peer group key agreement among enclaves.

## Overview M1

The high level architecture of the current implementation can be seen in the following diagram:

![Diagram](./substraTEE-worker-overview.svg)

The main building blocks can be found in the following repositories:

* [substraTEE-node](https://github.com/scs/substraTEE-node): (custom substrate node) A substrate node with a custom runtime module
* [substraTEE-worker](https://github.com/scs/substraTEE-worker) (client, worker-app, worker-enclave): A SGX-enabled service that performs a confidential state-transition-function

## Demo

This repo will host a docker container to showcase basic functionality soon.

## Acknowledgements

The development of substraTEE is financed by [web3 foundation](https://web3.foundation/)'s grant programme.

We also thank the teams at

* [Parity Technologies](https://www.parity.io/) for building [substrate](https://github.com/paritytech/substrate) and supporting us during development.
* [Baidu's Rust-SGX-SDK](https://github.com/baidu/rust-sgx-sdk) for their very helpful support and contributions.
