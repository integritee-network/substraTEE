# substraTEE

[substrate](https://docs.substrate.dev/) runtime in Trusted Execution Environment

*substraTEE* is an extension to [Parity Substrate](https://docs.substrate.dev/), allowing to call a custom state transition function inside a Trusted Execution Environment (TEE), namely an Intel SGX enclave thereby providing confidentiality and integrity. The enclaves operate on an encrypted state which can be read and written only by a set of provisioned and remote-attested enclaves.
*substraTEE* enables use cases demanding transaction privacy as well as atomic cross-chain transfers (bridges).

![vision](./substraTEE-vision.png)
*SubstraTEE Target Architecture with Direct Invocation*

What substraTEE aims to provide:

* confidential decentralized state transition functions
  * private transactions
  * private smart contracts
  * off-chain confidential personal data records (GDPR)
* scalability by providing a 2nd layer to substrate-based blockchains
  * off-chain smart contracts
  * payment hubs
* trusted chain bridges
* trusted oracles

## Concept Study

Different use cases for TEE's and potential software architectures have been analyzed and compared in [CONCEPTS](./CONCEPTS.md).
In the following we'll refer to the *substraTEE-worker* architecture, which has been implemented because it supports the widest range of use cases.

An overview over security aspects can be found in [SECURITY](./SECURITY.md). Remote attestation deviates from the usual Intel SGX scenario and is presented in [ATTESTATION](./ATTESTATION.md)

## Roadmap

|    Milestone    	|    Request    Invocation    	|    STF                      	|    # Workers per STF    	|    On-chain tx per invocation    	|    Supported TEE Manufact.                   	|  Remote Attestation Registry  |
|-----------------	|-----------------------------	|-----------------------------	|-------------------------	|----------------------------------	|----------------------------------------------	| ---|
|    M1           	|    Proxy                    	|    Rust                     	|    1                    	|    2                             	|    Intel                                     	|   -  |
|    M2           	|    Proxy                    	|    Rust or WASM             	|    1                    	|    2                             	|    Intel                                     	|  -  |
|    M3           	|    Proxy                    	|    Rust or WASM             	|    1                    	|    2                             	|    Intel                                     	|  X  |
|    M4           	|    Proxy                    	|    Rust or WASM             	|    N (redundant)        	|    1+N                           	|    Intel                                     	|  X  |
|    future       	|    Proxy                    	|    Rust or WASM or   **Ink**	|    N (redundant)        	|    2                             	|    Intel + ARM TrustZone + Keystone   (?)    	|  X  |
|    future        |    **Direct**               	|    Rust or WASM or   **Ink**	|    N (master + failover)    	|    **<< 1**                	|    Intel + ARM TrustZone + Keystone   (?)    	|  X  |


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

### *M5 support for ink contracts*

*(development not yet funded)*

[ink!](https://medium.com/block-journal/introducing-substrate-smart-contracts-with-ink-d486289e2b59) is substrate's domain specific contract language on top of Rust. This milestone shall bring ink! contracts to substraTEE.

### future

* performance benchmarks and optimization
* testnet for stress-tests and showcasing
* use cases: bridges, payment hubs, ...

## Overview M1

The high level architecture of the current implementation can be seen in the following diagram:

![Diagram](./substraTEE-worker-overview.svg)

The main building blocks can be found in the following repositories:

* [substraTEE-node](https://github.com/scs/substraTEE-node): (custom substrate node) A substrate node with a custom runtime module
* [substraTEE-worker](https://github.com/scs/substraTEE-worker): (client, worker-app, worker-enclave): A SGX-enabled service that performs a confidential state-transition-function

## Overview M2
The architecture of M2 corresponds with M1. The main difference is that the STF (block *update state* in the figure above) is WASM code which is executed inside the enclave.

## Overview M3 and M4
The high level architecture of the proposed architecture for M3 and M4 can be seen in the following diagram:
![Diagram](./substraTEE-architecture-M4.svg)

where M3 includes only the *docker image 1* and the *Intel Attestation Service (IAS)* and M4 includes the three *docker images* and the *Intel Attestation Service (IAS)*.

### Terms
* Shielding key: used by the substraTEE-client to encrypt the call in order to protect caller privacy. It is common to all enclaves.
* State encryption key: used to encrypt and decrypt the state storage. It is common to all enclaves.
* Signing key: used to sign transactions for the substraTEE-node. The corresponding account must be funded in order to pay for chain fees. It is unique for every enclave.

### Description
The *substraTEE-node* includes two additional runtime modules:
* substraTEE-proxy module: It forwards encrypted payloads to substraTEE-worker (event based) and indicates the finalization of the transaction (event based). This is the same functionality as for M1 and M2.
* substraTEE-registry module: It checks the IAS reports and keeps track of the registered enclaves. It provides the following API interfaces:
  * Register an enclave
  * Remove an enclave
  * Get the list of enclaves

The *substraTEE-worker* checks on the first start-up if "his" enclave is already registered on the chain. If this is not the case, it requests a remote attestion from the Intel Attestation Service (IAS) and sends the report to the *substraTEE-registry module* to register his enclave. If there is already an enclave (p.ex. from a different substraTEE-worker) registered on the chain, the substraTEE-worker gives his enclave the address of (any of) the registered enclave(s) so that it can get the *shielding and state encryption private key* and the most recent *encrypted state storage*.
The remaining functionality of the *substraTEE-worker* stays the same as for M1 and M2 (get the encrypted payload, use the enclave to decode the payload and perform the STF in the enclave).

The exchange of critical information between the enclaves is performed over a secure connection (TLS). The two enclaves perform a mutual remote attestation before exchanging any secrets.

## Demo

This repo hosts docker files to showcase the milestones.

#### Enabling SGX HW support
The demos are by default compiled for [Simulation Mode](https://software.intel.com/en-us/blogs/2016/05/30/usage-of-simulation-mode-in-sgx-enhanced-application) meaning that you don't need an actual SGX platform to run the example. This is specified in the `DockerfileM*` on line 99 (`SGX_MODE=SW make`). If you are on a platform that supports the SGX, you can enable HW support by:
  * Installing the Intel SGX Driver 2.5 and make sure that `/dev/isgx` appears
  * Start the docker with SGX device support:
    ```bash
    $ docker run -v $(pwd):/substraTEE/backup -ti --device /dev/isgx substratee
    ```
  * Start the aesm service inside the docker:
    ```bash
    root@<DOCKERID>:/# LD_LIBRARY_PATH=/opt/intel/libsgx-enclave-common/aesm /opt/intel/libsgx-enclave-common/aesm/aesm_service &
    ```
  * Compile the substraTEE-worker with HW support:
    ```bash
    root@<DOCKERID>:/substraTEE/substraTEE-worker-M1# make
    ```
  * Re-run the demos.

If you run the Hardware Mode on a platform that does not support SGX, you get the following error from the substraTEE-worker
```
*** Start the enclave
[2019-05-15T05:15:03Z ERROR substratee_worker::enclave_wrappers] [-] Init Enclave Failed SGX_ERROR_NO_DEVICE!
```

### M1 PoC1: single-TEE confidential state transition function
The following requirements are needed to run the M1 demo:
* Docker installed
* Active internet connection

To build and execute the code, follow these instructions:
1. Clone the [substraTEE](https://github.com/scs/substraTEE) repository to your favorite location:
   ```
   $ git clone https://github.com/scs/substraTEE.git
   ```
2. Build the docker image:
   ```
   $ docker build -t substratee -f DockerfileM1 .
   ```
   This may take some time (~2h on a recent MacBook), so grab a cup of :coffee: or :tea: - or two.
3. Start the docker image and get an interactive shell:
   ```
   $ docker run -v $(pwd):/substraTEE/backup -ti substratee
   ```
   The `-v $(pwd):/substraTEE/backup` is used to save the files generated by the enclave for later use and can also be omitted.

   If you are in a PowerShell on Windows, replace the `$(pwd)` with `${PWD}`.
4. Start the development substraTEE-node in the background and log the output in a file:
   ```
   root@<DOCKERID>:/substraTEE# /substraTEE/substraTEE-node-M1/target/release/substratee-node --dev > node.log 2>&1 &
   ```
   The node now runs in the background and the output can be inspected by calling: `tail -f /substraTEE/node.log`.
5. Start the substraTEE-worker and generate the keys:
   ```
   root@<DOCKERID>:/substraTEE# cd /substraTEE/substraTEE-worker-M1
   root@<DOCKERID>:/substraTEE/substraTEE-worker-M1# ./bin/substratee_worker getpublickey
   root@<DOCKERID>:/substraTEE/substraTEE-worker-M1# ./bin/substratee_worker getsignkey
   ```
   This will generate the sealed (= encrypted) RSA3072 keypair (`./bin/rsa3072_key_sealed.bin`), the sealed ED25519 keypair (`./bin/ed25519_key_sealed.bin`) and the unencrypted public keys (`./bin/rsa_pubkey.txt` and `./bin/ecc_pubkey.txt`). The sealed keypairs can only be decrypted by your specific SGX enclave.
6. Start the substraTEE-worker in the background and log the output in a file:
   ```
   root@<DOCKERID>:/substraTEE/substraTEE-worker-M1# ./bin/substratee_worker worker > /substraTEE/worker.log 2>&1 &
   ```
   The worker now runs in the background and the output can be inspected by calling: `tail -f /substraTEE/worker.log`.
7. Start the substraTEE-client to send an extrinsic to the substraTEE-node that is then forwarded and processed by the substraTEE-worker (incrementing a counter):
   ```
   root@<DOCKERID>:/substraTEE/substraTEE-worker-M1# ./bin/substratee_client | tee /substraTEE/client.log
   ```
   The output of the client is also logged to the file `/substraTEE/client.log` and can be inspected by `less /substraTEE/client.log`.

   You will see on the last lines of the output the two hashes of the transaction (expected and actual). These should match indicating that all commands were processed successfully.
   ```
   Expected Hash: [...]
   Actual Hash:   [...]
   ```
8. Query the counter from the substraTEE-worker:
   ```
   root@<DOCKERID>:/substraTEE/substraTEE-worker-M1# ./bin/substratee_client getcounter | tee /substraTEE/counter.log
   ```

Whenever you perform the steps 7. and 8., you will see the counter incrementing.

#### IMPORTANT
If you exit the container (`exit`), you will loose the sealed counter state and the generated keys.

To backup the files:
```
root@<DOCKERID>:/substraTEE# cp /substraTEE/substraTEE-worker-M1/bin/*.txt /substraTEE/backup/
root@<DOCKERID>:/substraTEE# cp /substraTEE/substraTEE-worker-M1/bin/*.bin /substraTEE/backup/
```

To restore the files:
```
root@<DOCKERID>:/substraTEE# cp /substraTEE/backup/*.txt /substraTEE/substraTEE-worker-M1/bin/
root@<DOCKERID>:/substraTEE# cp /substraTEE/backup/*.bin /substraTEE/substraTEE-worker-M1/bin/
```

#### Enabling Debug output
To enable debug output, call the substraTEE-worker or the substraTEE-client with the following command, respectivly: `RUST_LOG=debug ./bin/substratee_client`.

### M2 PoC2: single-TEE confidential state transition function in WASM
The following requirements are needed to run the M2 demo:
* Docker installed
* Active internet connection

The main principle is the same as M1. The big difference is that the code that implements the business logic (in our case, incrementing a counter) is stored as WASM code. When starting the client (step 8), we tell the worker the SHA256 hash of the WASM that we want to execute. If the desired and the computed hashes don't match, the STF must not be executed. This ensures that we know which code was executed in the SGX enclave.

To build and execute the code, follow these instructions:
1. Clone the [substraTEE](https://github.com/scs/substraTEE) repository to your favorite location:
   ```shell
   $ git clone https://github.com/scs/substraTEE.git
   ```

2. Build the docker image:
   ```shell
   $ docker build -t substratee -f DockerfileM2 .
   ```
   This may take some time (~2h on a recent MacBook), so grab a cup of :coffee: or :tea: - or two.

3. Start the docker image and get an interactive shell:
   ```shell
   $ docker run -v $(pwd):/substraTEE/backup -ti substratee
   ```
   The `-v $(pwd):/substraTEE/backup` is used to save the files generated by the enclave for later use and can also be omitted.

   If you are in a PowerShell on Windows, replace the `$(pwd)` with `${PWD}`.

4. Start the development substraTEE-node in the background and log the output in a file:
   ```shell
   root@<DOCKERID>:/substraTEE# /substraTEE/substraTEE-node-M1/target/release/substratee-node --dev > node.log 2>&1 &
   ```
   The node now runs in the background and the output can be inspected by calling: `tail -f /substraTEE/node.log`.

5. Start the substraTEE-worker and generate the keys:
   ```shell
   root@<DOCKERID>:/substraTEE# cd /substraTEE/substraTEE-worker-M2
   root@<DOCKERID>:/substraTEE/substraTEE-worker-M2# ./bin/substratee_worker getpublickey
   root@<DOCKERID>:/substraTEE/substraTEE-worker-M2# ./bin/substratee_worker getsignkey
   ```
   This will generate the sealed (= encrypted) RSA3072 keypair (`./bin/rsa3072_key_sealed.bin`), the sealed ED25519 keypair (`./bin/ed25519_key_sealed.bin`) and the unencrypted public keys (`./bin/rsa_pubkey.txt` and `./bin/ecc_pubkey.txt`). The sealed keypairs can only be decrypted by your specific SGX enclave.

6. Start the substraTEE-worker in the background and log the output in a file:
   ```shell
   root@<DOCKERID>:/substraTEE/substraTEE-worker-M2# ./bin/substratee_worker worker > /substraTEE/worker.log 2>&1 &
   ```
   The worker now runs in the background and the output can be inspected by calling: `tail -f /substraTEE/worker.log`.

7. Get the SHA256 hash of the WASM module:
   ```shell
   root@<DOCKERID>:/substraTEE/substraTEE-worker-M2# sha256sum ./bin/worker_enclave.compact.wasm
   ```
   This will output something like the following, where the actual values may be different:
   ```shell
   d7331d5344a99696a8135212475e2c6b605cea88e9edd594773181205dda1531  ./bin/worker_enclave.compact.wasm
   ```
   The first long number is the SHA256 hash of the WASM code. Copy this value (in the example case `d733...1531`) into the clipboard (Control-C).

8. Start the substraTEE-client to send an extrinsic to the substraTEE-node that is then forwarded and processed by the substraTEE-worker. The code to increment the counter comes from the WASM file (`bin/worker_enclave.compact.wasm`). The user provides the hash of the code he wants to execute.
   ```shell
   root@<DOCKERID>:/substraTEE/substraTEE-worker-M2# ./bin/substratee_client --sha256wasm <COPIED_CONTENT_FROM_STEP_7> | tee /substraTEE/client.log
   ```
   The output of the client is also logged to the file `/substraTEE/client.log` and can be inspected by `less /substraTEE/client.log`.

   You will see on the last lines of the output the two hashes of the transaction (expected and actual). These should match indicating that all commands were processed successfully.
   ```shell
   Expected Hash: [...]
   Actual Hash:   [...]
   ```

9. Query the counter from the substraTEE-worker:
   ```shell
   root@<DOCKERID>:/substraTEE/substraTEE-worker-M2# ./bin/substratee_client getcounter | tee /substraTEE/counter.log
   ```
   After the first iteration, the counter of Alice will have the value 52. This is correct as the following code is executed in the WASMI in the enclave: `new = old + increment + 10` (see `substraTEE-worker/enclave/wasm/src/lib.rs`).

10. Check the output of the substraTEE-worker by calling `less /substraTEE/worker.log`. The most important section is (near the end)
    ```
    [>] Decrypt and process the payload
        ...
        [Enclave] SHA256 of WASM code identical
        ...
    [<] Message decoded and processed in the enclave
    ```
    which indicates that the SHA256 hash passed by the client matches the calculated hash of the code that should be executed.

11. When sending a different hash from the substraTEE-client to the substraTEE-worker, the code will not be executed and the counter therefore not updated.

     The client will wait infinitely for the callConfirmed event which will never be sent by the worker as the code was not executed. The client must be killed (Control-C) and the log file of the worker can be inspected with `less /substraTEE/worker.log`. At the end of the log file there is a different output than before
     ```
     [>] Decrypt and process the payload
         ...
         [Enclave] SHA256 of WASM code not matching
         [Enclave]   Wanted by client    : [...]
         [Enclave]   Calculated by worker: [...]
         [Enclave] Returning ERROR_UNEXPECTED and not updating STF
     ```
     which indicates that the SHA256 hash passed by the client **DOES NOT** match the calculated hash of the code that should be executed.

Whenever you perform the steps 8. and 9., you will see the counter incrementing.

## Acknowledgements

The development of substraTEE is financed by [web3 foundation](https://web3.foundation/)'s grant programme.

We also thank the teams at

* [Parity Technologies](https://www.parity.io/) for building [substrate](https://github.com/paritytech/substrate) and supporting us during development.
* [Baidu's Rust-SGX-SDK](https://github.com/baidu/rust-sgx-sdk) for their very helpful support and contributions.
