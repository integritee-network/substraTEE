# Code Documentation for M4
This page describes the implemented functions of M4 with corresponding code references.

## substraTEE-node
- This is the substrate runtime with an additional module called _substratee-registry_.
- The previous module (_substratee-proxy_) was merged into this new module.
- Our substrate-registry module exposes the following functions:
  - `call_worker`: [runtime/src/substratee_registry.rs:88](https://github.com/scs/substraTEE-node/blob/M4/runtime/src/substratee_registry.rs#L88)
    - This function is used to forward the payload from the substraTEE-client to the substraTEE-worker.
  - `confirm_call`: [runtime/src/substratee_registry.rs:97](https://github.com/scs/substraTEE-node/blob/M4/runtime/src/substratee_registry.rs#L97)
    - This function is used to indicate that the payload was processed in the enclave and is sent from the substraTEE-worker to the substraTEE-client.
  - `register_enclave`: [runtime/src/substratee_registry.rs:71](https://github.com/scs/substraTEE-node/blob/M4/runtime/src/substratee_registry.rs#L71)
    - This function is used to register a new enclave in the substraTEE-registry and is sent from the substraTEE-worker to the substraTEE-node.
  - `unregister_enclave`: [runtime/src/substratee_registry.rs:80](https://github.com/scs/substraTEE-node/blob/M4/runtime/src/substratee_registry.rs#L80)
    - This function is used to unregister an enclave from the substraTEE-registry and is sent from the substraTEE-worker to the substraTEE-node.
- In case they get called, the corresponding event is fired
  - `Forwarded`: [runtime/src/substratee_registry.rs:91](https://github.com/scs/substraTEE-node/blob/M4/runtime/src/substratee_registry.rs#L91)
  - `CallConfirmed`: [runtime/src/substratee_registry.rs:104](https://github.com/scs/substraTEE-node/blob/M4/runtime/src/substratee_registry.rs#L104)
  - `AddedEnclave`: [runtime/src/substratee_registry.rs:76](https://github.com/scs/substraTEE-node/blob/M4/runtime/src/substratee_registry.rs#L76)
  - `RemovedEnclave`: [runtime/src/substratee_registry.rs:84](https://github.com/scs/substraTEE-node/blob/M4/runtime/src/substratee_registry.rs#L84)
- The module has a storage (called _substraTEERegistry_) which is updated with the corresponding call and contains the following information:
  - `EnlaveRegistry`: [runtime/src/substratee_registry.rs:58](https://github.com/scs/substraTEE-node/blob/M4/runtime/src/substratee_registry.rs#L58): A list of all the registered enclaves with their public key and the URL
  - `EnclaveCount`: [runtime/src/substratee_registry.rs:59](https://github.com/scs/substraTEE-node/blob/M4/runtime/src/substratee_registry.rs#L59): A counter for all the registered enclaves
  - `EnclaveIndex`: [runtime/src/substratee_registry.rs:60](https://github.com/scs/substraTEE-node/blob/M4/runtime/src/substratee_registry.rs#L60): The index of a specific enclave in the registry
  - `LatestIPFSHash`: [runtime/src/substratee_registry.rs:61](https://github.com/scs/substraTEE-node/blob/M4/runtime/src/substratee_registry.rs#L61): The IPFS hash of the latest state which is updated after a `confirm_call`

## substraTEE-worker
### Description of the functionality
The substraTEE-worker implements mainly the following functions:
1. Instruct the enclave to generate a RSA3072 key pair which is used for encrypting the payload sent from the substraTEE-client to the substraTEE-worker. This is done with the command `getpublickey`.
   - **Important**: only the public key leaves the enclave while the private key stays in the enclave.

2. Instruct the enclave to generate a ED25519 key pair which is used for signing the extrinsic sent from the substraTEE-worker to the substraTEE-node. This is done with the command `getsignkey`.
    - **Important**: only the public key leaves the enclave while the private key stays in the enclave.

**With the `worker` command the following functions are executed in subsequent order:**

3. Get a remote attestation report from Intel and send the report as an extrinsic (computed in the enclave) to the substraTEE-registry that checks validity of the report and adds the worker to the set of registered workers.

4. Upon successful registration it checks in the substraTEE-registry if more workers are registered. If yes, it performs mutual remote attestation with the first registered worker and fetches afterwards the RSA3072 key, the state encryption key and the state with a TLS connection.

5. Subscribe to substraTEE-registry events, forward any received payload to the enclave and send a confirmation as an extrinsic (that is composed in the enclave) back to the substraTEE-node. All registered workers now compute redundantly the state updates. This part remains almost unchanged since M2.

Since M2, the substraTEE-worker compares the SHA256 hash of the WASM to be executed to the SHA256 hash given by the substraTEE-client. The code is executed only if the two hashes match - this gives the end user the confirmation and trust that the correct STF is executed.

### Implementation
The functions are implemented at the following places:

**Important**: The functions defined in the [enclave/Enclave.edl](https://github.com/scs/substraTEE-worker/blob/M4/enclave/Enclave.edl) are the only entry points from the untrusted world to the trusted world inside the enclave. All arguments and return values need to be defined there.

#### Funtion 1: RSA3072 key pair generation
- [worker/src/enclave_wrappers.rs:215](https://github.com/scs/substraTEE-worker/blob/M4/worker/src/enclave_wrappers.rs#L215): The enclave is started
- [worker/src/enclave_wrappers.rs:234](https://github.com/scs/substraTEE-worker/blob/M4/worker/src/enclave_wrappers.rs#L234): The public RSA3072 key is requested from the enclave
  - [enclave/src/lib.rs:101](https://github.com/scs/substraTEE-worker/blob/M4/enclave/src/lib.rs#L101): Enter the function `get_rsa_encryption_pubkey`
  - [enclave/src/lib.rs:107](https://github.com/scs/substraTEE-worker/blob/M4/enclave/src/lib.rs#L107): The enclave checks if a key pair file (`./bin/rsa3072_key_sealed.bin`) is already present and if not, create a new one
  - [enclave/src/lib.rs:114](https://github.com/scs/substraTEE-worker/blob/M4/enclave/src/lib.rs#L114): Read the key pair file and extract the public key
  - [enclave/src/lib.rs:127](https://github.com/scs/substraTEE-worker/blob/M4/enclave/src/lib.rs#L127): Return the public key
- [worker/src/enclave_wrappers.rs:255](https://github.com/scs/substraTEE-worker/blob/M4/worker/src/enclave_wrappers.rs#L255): The received public RSA3072 key is written to an unencrypted text file (./bin/rsa_pubkey.txt)

#### Function 2: ED25519 key pair generation
Same principle as Function 1 but starting at line 163 in the [worker/src/enclave_wrappers.rs](https://github.com/scs/substraTEE-worker/blob/M4/worker/src/enclave_wrappers.rs#L163)

#### Function 3: Perform remote attestation
- [worker/src/main.rs:152](https://github.com/scs/substraTEE-worker/blob/M4/worker/src/main.rs#L152): The enclave is started
- [worker/src/main.rs:166](https://github.com/scs/substraTEE-worker/blob/M4/worker/src/main.rs#L166): The worker initializes the SGXWASM specific driver engine in the previously created enclave
- [worker/src/main.rs:185](https://github.com/scs/substraTEE-worker/blob/M4/worker/src/main.rs#L185): The worker spawns a server for mutual remote attestation requests.
- [worker/src/main.rs:191](https://github.com/scs/substraTEE-worker/blob/M4/worker/src/main.rs#L191): The worker calls the substrate-api-client and collects all the necessary information such that the TEE can compose a valid extrinsic.
- [worker/src/main.rs:217](https://github.com/scs/substraTEE-worker/blob/M4/worker/src/main.rs#L217): Enter the enclave via the `perform_ra`.
  - [enclave/src/attestation.rs:585](https://github.com/scs/substraTEE-worker/blob/M4/enclave/src/attestation.rs#L585): Create the attestation report with signature from Intel. The steps to create the attestation report are quite technical. Hence, details are omitted here, but the code follows the exact steps from [ATTESTATION.md](https://github.com/scs/substraTEE/blob/master/ATTESTATION.md#attestation-registry-on-chain).
  - [enclave/src/attestation.rs:590](https://github.com/scs/substraTEE-worker/blob/M4/enclave/src/attestation.rs#L590): Compose the extrinsic to register the enclave and return it.
- [worker/src/main.rs:247](https://github.com/scs/substraTEE-worker/blob/M4/worker/src/main.rs#L247): Send the extrinsic to the node and wait until its finalized.

#### Function 4: Mutual Remote Attestation
- [worker/src/main.rs:251](https://github.com/scs/substraTEE-worker/blob/M4/worker/src/main.rs#L251): Query the node for the amount of registered workers.
- [worker/src/main.rs:261](https://github.com/scs/substraTEE-worker/blob/M4/worker/src/main.rs#L261): If other workers are registered. Get a worker's information from the node in order to connect to it via a websocket.
- [worker/src/main.rs:265](https://github.com/scs/substraTEE-worker/blob/M4/worker/src/main.rs#L265): Query the other worker for the port it has running the mutual remote attestation server.
- [worker/src/main.rs:269](https://github.com/scs/substraTEE-worker/blob/M4/worker/src/main.rs#L269): Perform a mutual remote attestation with the other worker.
  - [worker/src/enclave_tls_ra.rs](https://github.com/scs/substraTEE-worker/blob/M4/worker/src/enclave_tls_ra.rs#L91): Setup a TCP connection and hand the socket into the enclave to perform the mutual remote attestation.
    - [enclave/src/tls_ra.rs](https://github.com/scs/substraTEE-worker/blob/M4/enclave/src/tls_ra.rs)
      - Server ([line #94](https://github.com/scs/substraTEE-worker/blob/M4/enclave/src/tls_ra.rs#L94)) and client ([line #161](https://github.com/scs/substraTEE-worker/blob/M4/enclave/src/tls_ra.rs#L161)) both get a remote attestation report from Intel.
      - A TLS session is established. The `rustls` Server ([line #62](https://github.com/scs/substraTEE-worker/blob/M4/enclave/src/tls_ra.rs#L62)) and client ([line #26](https://github.com/scs/substraTEE-worker/blob/M4/enclave/src/tls_ra.rs#L26)) authentication procedure has been extended to automatically check the remote attestation report upon session establishment.
      - [MU-RA Server] Reads the keys from storage and  sends them via TLS ([line #112](https://github.com/scs/substraTEE-worker/blob/M4/enclave/src/tls_ra.rs#L112))
      - [MU-RA Server] Writes the encrypted state to an IPFS node through a call to the host system ([line #141](https://github.com/scs/substraTEE-worker/blob/5190921c0c0950b974f5501442c9cca6c917157b/enclave/src/tls_ra.rs#L141)), which returns a CID (= a hash corresponding to an IPFS address).
      - [MU-RA Server] Sends the CID to the client ([line #152](https://github.com/scs/substraTEE-worker/blob/5190921c0c0950b974f5501442c9cca6c917157b/enclave/src/tls_ra.rs#L152)).
      - [MU-RA Client] Reads the keys and the CID ([line 183](https://github.com/scs/substraTEE-worker/blob/M4/enclave/src/tls_ra.rs#L183)).
      - [MU-RA Client] Reads the encrypted state from the IPFS node through a call to the host system ([line 265](https://github.com/scs/substraTEE-worker/blob/M4/enclave/src/tls_ra.rs#L265)).

#### Function 5: Process encrypted payload from the substraTEE-node
- [worker/src/main.rs:277](https://github.com/scs/substraTEE-worker/blob/M4/worker/src/main.rs#L277): The worker calls the substrate-api-client and subscribes to events from the substraTEE-node
- [worker/src/main.rs:299](https://github.com/scs/substraTEE-worker/blob/M4/worker/src/main.rs#L299): When it receives a Balances event, it prints out the decoded information
- [worker/src/main.rs:325](https://github.com/scs/substraTEE-worker/blob/M4/worker/src/main.rs#L315): When it receives a substraTEE-registry `Forwarded` event, it forwards the received (encrypted) payload to the function `process_forwarded_payload`. Other substraTEE-registry events are simply printed.
  - [worker/src/enclave_wrappers.rs:53](https://github.com/scs/substraTEE-worker/blob/M4/worker/src/enclave_wrappers.rs#L53): The (encrypted) payload is forwarded to the function `decrypt_and_process_payload`
    - [worker/src/enclave_wrappers.rs:106](https://github.com/scs/substraTEE-worker/blob/M4/worker/src/enclave_wrappers.rs#L108): The WASM code is read from the file `bin/worker_enclave.compact.wasm`
    - [worker/src/enclave_wrappers.rs:109](https://github.com/scs/substraTEE-worker/blob/M4/worker/src/enclave_wrappers.rs#L109): The SHA256 hash of the WASM code is calculated
    - [worker/src/enclave_wrappers.rs:125](https://github.com/scs/substraTEE-worker/blob/M4/worker/src/enclave_wrappers.rs#L125): The (encrypted) payload, the calculated SHA256 hash and additional information to compose a valid extrinsic is given to the function `call_counter_wasm` in the enclave
      - [enclave/src/lib.rs:206](https://github.com/scs/substraTEE-worker/blob/M4/enclave/src/lib.rs#L206): The payload is decoded using the RSA3072 private key of the enclave
      - [enclave/src/lib.rs:208](https://github.com/scs/substraTEE-worker/blob/M4/enclave/src/lib.rs#L208): The account, the increment and the expected SHA256 hash are read from the decrypted payload
      - [enclave/src/lib.rs:219](https://github.com/scs/substraTEE-worker/blob/M4/enclave/src/lib.rs#L219): The calculated and the expected SHA256 hashes are compared. If they don't match, the enclave returns an error
      - [enclave/src/lib.rs:223](https://github.com/scs/substraTEE-worker/blob/M4/enclave/src/lib.rs#L223): If the hashes match, the encrypted state it read from file and decrypted
      - [enclave/src/lib.rs:245](https://github.com/scs/substraTEE-worker/blob/M4/enclave/src/lib.rs#L245): The wasm action is invoked, which performs the state update
      - [enclave/src/lib.rs:250](https://github.com/scs/substraTEE-worker/blob/M4/enclave/src/lib.rs#L250): The updated counter state is encrypted
      - [enclave/src/lib.rs:257](https://github.com/scs/substraTEE-worker/blob/M4/enclave/src/lib.rs#L257): The hash of the encrypted state is calculated, which is later written to the substraTEE-registry
      - [enclave/src/lib.rs:259](https://github.com/scs/substraTEE-worker/blob/M4/enclave/src/lib.rs#L259): The updated encrypted state is written back to the disk
      - [enclave/src/lib.rs:273](https://github.com/scs/substraTEE-worker/blob/M4/enclave/src/lib.rs#L273): The enclave composes the extrinsic with the hash of the (unencrypted) payload that is returned to the worker. The target module is the function `confirm_call` of the substraTEE-registry
  - [worker/src/enclave_wrappers.rs:74](https://github.com/scs/substraTEE-worker/blob/M4/worker/src/enclave_wrappers.rs#L74): The extrinsic is sent to the substraTEE-node through the substrate-api-client

## substraTEE-client
The client is a sample implementation and only serves the purpose to demonstrate the functionalities of the substraTEE-node and substraTEE–worker. It implements the following sequence:
- [client/src/main.rs:70](https://github.com/scs/substraTEE-worker/blob/M4/client/src/main.rs#L70): The number of registered enclaves (or substraTEE-workers) is queried from the substraTEE-node
  - If (at least) one enclave is registered, the public key and the URL of the first substraTEE-worker is extracted
- [client/src/main.rs:97](https://github.com/scs/substraTEE-worker/blob/M4/client/src/main.rs#L97): The SHA256 hash of the WASM file is calculated. This is either the same file as the enclave is using or the user can specify a custom file.
- [client/src/main.rs:105](https://github.com/scs/substraTEE-worker/blob/M4/client/src/main.rs#L105): The free balance from //Alice is queried
- [client/src/main.rs:108](https://github.com/scs/substraTEE-worker/blob/M4/client/src/main.rs#L108): The current account nonce of //Alice is queried
- [client/src/main.rs:111](https://github.com/scs/substraTEE-worker/blob/M4/client/src/main.rs#L111): The account //Alice is funded with 1_000_000 units
- [client/src/main.rs:115](https://github.com/scs/substraTEE-worker/blob/M4/client/src/main.rs#L115): 1000 units are transferred from //Alice to the account of the enclave (identified by the public ED25519 key of the enclave)
- [client/src/main.rs:119](https://github.com/scs/substraTEE-worker/blob/M4/client/src/main.rs#L119): The public RSA3072 key of the enclave is requested from the substraTEE-worker
- [client/src/main.rs:131](https://github.com/scs/substraTEE-worker/blob/M4/client/src/main.rs#L131): An extrinsic with an encrypted payload (using the public RSA3072 key of the enclave) is composed
  - The payload contains the account (default `//Alice`), the increment (default `42`) and the SHA256 hash of the WASM
- [client/src/main.rs:136](https://github.com/scs/substraTEE-worker/blob/M4/client/src/main.rs#L136): The extrinsic is sent to the substraTEE-node to the function “call_worker” of the substratee-registry module. The client waits for the confirmation that the transaction got finalized
- [client/src/main.rs:143](https://github.com/scs/substraTEE-worker/blob/M4/client/src/main.rs#L143): Use the substrate-api-client to subscribe to the event `CallConfirmed` of the substraTEE-node
- [client/src/main.rs:145](https://github.com/scs/substraTEE-worker/blob/M4/client/src/main.rs#L145): When the event was received, print out the calculated and the received hash of the (unencrypted) payload
