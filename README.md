# substraTEE
[substrate](https://docs.substrate.dev/) runtime in Trusted Execution Environment

*substraTEE* is an extension to [Parity Substrate](https://docs.substrate.dev/), allowing to call a custom state transition function inside a Trusted Execution Environment (TEE), namely an Intel SGX enclave thereby providing confidentiality and integrity. The enclaves operate on an encrypted state which can be read and written only by a set of provisioned and remote-attested enclaves.
*substraTEE* enables use cases demanding transaction privacy as well as atomic cross-chain transfers (bridges).

## Architecture
The high level architecture of the implementation can be seen in the following image
![Diagram](./substraTEE_architecture.svg)

The different building blockscan be found in the following repositories:
* [substraTEE-client](https://github.com/scs/substraTEE-client)
* [substrate-api-client](https://github.com/scs/substrate-api-client)
* [substraTEE-node](https://github.com/scs/substraTEE-node)
* [substraTEE-worker](https://github.com/scs/substraTEE-worker)