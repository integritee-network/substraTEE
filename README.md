# substraTEE
substrate runtime in Trusted Execution Environment

*substraTEE* is an extension to Parity Substrate, allowing to call a custom state transition function inside a Trusted Execution Environment (TEE), namely an Intel SGX enclave thereby providing confidentiality and integrity. The enclaves operate on an encrypted state which can be read and written only by a set of provisioned and remote-attested enclaves. 
*substraTEE* enables use cases demanding transaction privacy as well as atomic cross-chain transfers (bridges).
