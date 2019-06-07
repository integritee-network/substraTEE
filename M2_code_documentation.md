# Code Documentation for M2
This page describes the implemented functions of M2 with corresponding code references.

## substraTEE-node
 - This is the substrate runtime with an additional module called substratee-proxy.
 - Our substrate-proxy module exposes two functions:
   - `call_worker`: [runtime/src/substratee_proxy.rs:32](https://github.com/scs/substraTEE-node/blob/fbfa785ead3506fac2280a157a11274ae4e45a3a/runtime/src/substratee_proxy.rs#L32)
     - This function is used to forward the payload from the substraTEE-client to the substraTEE-worker.
    - `confirm_call`: [runtime/src/substratee_proxy.rs:41](https://github.com/scs/substraTEE-node/blob/fbfa785ead3506fac2280a157a11274ae4e45a3a/runtime/src/substratee_proxy.rs#L41)
      - This function is used to indicate that the payload was processed in the enclave and is sent from the substraTEE-worker to the substraTEE-client.
 - In case they get called, the corresponding event is fired
   - `Forwarded`: [runtime/src/substratee_proxy.rs:16](https://github.com/scs/substraTEE-node/blob/fbfa785ead3506fac2280a157a11274ae4e45a3a/runtime/src/substratee_proxy.rs#L16)
   - `CallConfirmed`: [runtime/src/substratee_proxy.rs:17](https://github.com/scs/substraTEE-node/blob/fbfa785ead3506fac2280a157a11274ae4e45a3a/runtime/src/substratee_proxy.rs#L17)

## substraTEE-worker
### Description of the functionality
The substraTEE-worker implements three main functions:
1. Instruct the enclave to generate a RSA3072 key pair which is used for encrypting the payload sent from the substraTEE-client to the substraTEE-worker. This is done with the command `getpublickey`.
   - **Important**: only the public key leaves the enclave while the private key stays in the enclave.

2. Instruct the enclave to generate a ED25519 key pair which is used for signing the extrinsic sent from the substraTEE-worker to the substraTEE-node. This is done with the command `getsignkey`.
    - **Important**: only the public key leaves the enclave while the private key stays in the enclave.

3. Subscribe to substraTEE-proxy events, forward any received payload to the enclave and send the extrinsic (that is composed in the enclave) back to the substraTEE-node. This is done with the command `worker`.

   For M2, the substraTEE-worker compares the SHA256 hash of the WASM to be executed to the SHA256 hash given by the substraTEE-client. The code is executed only if the two hashes match - this gives the end user the confirmation and trust that the correct STF is executed.

### Implementation
The functions are implemented at the following places:

**Important**: Only the functions defined in [enclave/Enclave.edl](https://github.com/scs/substraTEE-worker/blob/M2/enclave/Enclave.edl) are allowed to be called in the enclave. The return values also have to be defined here.

#### Funtion 1: RSA3072 key pair generation
- [worker/src/enclave_wrappers.rs:216](https://github.com/scs/substraTEE-worker/blob/M2/worker/src/enclave_wrappers.rs#L216): The enclave is started
- [worker/src/enclave_wrappers.rs:235](https://github.com/scs/substraTEE-worker/blob/M2/worker/src/enclave_wrappers.rs#L235): The public RSA3072 key is requested from the enclave
  - [enclave/src/lib.rs:96](https://github.com/scs/substraTEE-worker/blob/M2/enclave/src/lib.rs#L96): Enter the function `get_rsa_encryption_pubkey`
  - [enclave/src/lib.rs:99](https://github.com/scs/substraTEE-worker/blob/M2/enclave/src/lib.rs#L99): The enclave checks if a key pair file (`./bin/rsa3072_key_sealed.bin`) is already present and if not, create a new one
  - [enclave/src/lib.rs:109](https://github.com/scs/substraTEE-worker/blob/M2/enclave/src/lib.rs#L109): Read the key pair file and extract the public key
  - [enclave/src/lib.rs:125](https://github.com/scs/substraTEE-worker/blob/M2/enclave/src/lib.rs#L125): Return the public key
- [worker/src/enclave_wrappers.rs:257](https://github.com/scs/substraTEE-worker/blob/M2/worker/src/enclave_wrappers.rs#L257): The received public RSA3072 key is written to an unencrypted text file (./bin/rsa_pubkey.txt)

#### Function 2: ED25519 key pair generation
Same principle as Function 1 but starting at line 164 in the [worker/src/enclave_wrappers.rs]((https://github.com/scs/substraTEE-worker/blob/M2/worker/src/enclave_wrappers.rs#L164)

#### Function 3: Process encrypted payload from the substraTEE-node

- [worker/src/main.rs:100](https://github.com/scs/substraTEE-worker/blob/M2/worker/src/main.rs#L100): The enclave is started
- [worker/src/main.rs:116](https://github.com/scs/substraTEE-worker/blob/M2/worker/src/main.rs#L116): The worker initializes the SGXWASM specific driver engine in the previously created enclave
- [worker/src/main.rs:132](https://github.com/scs/substraTEE-worker/blob/M2/worker/src/main.rs#L132): The worker calls the substrate-api-client and subscribes to events from the substraTEE-node
- [worker/src/main.rs:157](https://github.com/scs/substraTEE-worker/blob/M2/worker/src/main.rs#L157): When it receives a Balances event, it prints out the decoded information
- [worker/src/main.rs:172](https://github.com/scs/substraTEE-worker/blob/M2/worker/src/main.rs#L172): When it receives a substraTEE-proxy event, it forwards the received (encrypted) payload to the function `process_forwarded_payload`
  - [worker/src/enclave_wrappers.rs:64](https://github.com/scs/substraTEE-worker/blob/M2/worker/src/enclave_wrappers.rs#L64): The (encrypted) payload is forwarded to the function `decrypt_and_process_payload`
    - [worker/src/enclave_wrappers.rs:108](https://github.com/scs/substraTEE-worker/blob/M2/worker/src/enclave_wrappers.rs#L108): The WASM code is read from the file `bin/worker_enclave.compact.wasm`
    - [worker/src/enclave_wrappers.rs:111](https://github.com/scs/substraTEE-worker/blob/M2/worker/src/enclave_wrappers.rs#L111): The SHA256 hash of the WASM code is calculated
    - [worker/src/enclave_wrappers.rs:127](https://github.com/scs/substraTEE-worker/blob/M2/worker/src/enclave_wrappers.rs#L127): The (encrypted) payload, the calcuated SHA256 hash and additional information to compose a valid extrinsic is given to the function `call_counter_wasm` in the enclave
      - [enclave/src/lib.rs:224](https://github.com/scs/substraTEE-worker/blob/M2/enclave/src/lib.rs#L224): The payload is decoded using the RSA3072 private key of the enclave
      - [enclave/src/lib.rs:226](https://github.com/scs/substraTEE-worker/blob/M2/enclave/src/lib.rs#L226): The account, the increment and the expected SHA256 hash are read from the decrypted payload
      - [enclave/src/lib.rs:242](https://github.com/scs/substraTEE-worker/blob/M2/enclave/src/lib.rs#L242): The calculated and the expected SHA256 hashes are compared. If they don't match, the enclave returns an error
      - [enclave/src/lib.rs:255](https://github.com/scs/substraTEE-worker/blob/M2/enclave/src/lib.rs#L255): If the hashes match, the current value of the desired account's counter is read from the sealed file
      - [enclave/src/lib.rs:285](https://github.com/scs/substraTEE-worker/blob/M2/enclave/src/lib.rs#L285): The arguments for the WASM are prepared (old value and increment)
      - [enclave/src/lib.rs:290](https://github.com/scs/substraTEE-worker/blob/M2/enclave/src/lib.rs#L290): The WASM code is executed
      - [enclave/src/lib.rs:296](https://github.com/scs/substraTEE-worker/blob/M2/enclave/src/lib.rs#L296): If the execution was successful, the updated value is written back to the account's counter
      - [enclave/src/lib.rs:310](https://github.com/scs/substraTEE-worker/blob/M2/enclave/src/lib.rs#L310): The updated counter is written back to the disk, as sealed file
      - [enclave/src/lib.rs:319](https://github.com/scs/substraTEE-worker/blob/M2/enclave/src/lib.rs#L319): The enclave composes the extrinsic with the hash of the (unencrypted) payload that is returned to the worker. The target module is the function `confirm_call` of the substraTEE-proxy
  - [worker/src/enclave_wrappers.rs:74](https://github.com/scs/substraTEE-worker/blob/M2/worker/src/enclave_wrappers.rs#L74): The extrinsic is sent through the substrate-api-client to the substraTEE-node

## substraTEE-client
The client is a sample implementation and only serves the purpose to demonstrate the functionalities of the substraTEE-node and substraTEE–worker. It implements the following sequence:
 - [client/src/main.rs:73](https://github.com/scs/substraTEE-worker/blob/M2/client/src/main.rs#L73): The length of the provided argument `sha256wasm` is checked
 - [client/src/main.rs:88](https://github.com/scs/substraTEE-worker/blob/M2/client/src/main.rs#L88): The free balance from //Alice is queried
 - [client/src/main.rs:91](https://github.com/scs/substraTEE-worker/blob/M2/client/src/main.rs#L91): The current account nonce of //Alice is queried
 - [client/src/main.rs:94](https://github.com/scs/substraTEE-worker/blob/M2/client/src/main.rs#L94): The account //Alice is funded with 1_000_000
 - [client/src/main.rs:99](https://github.com/scs/substraTEE-worker/blob/M2/client/src/main.rs#L99): 1000 units are transferred from //Alice to the account of the TEE (identified by the public ED25519 key of the enclave)
 - [client/src/main.rs:73](https://github.com/scs/substraTEE-worker/blob/M2/client/src/main.rs#L73): An extrinsic with an encrypted payload (using the public RSA3072 key of the enclave) is composed
     - The payload contains the account (default `//Alice`), the increment (default `42`) and the SHA256 hash of the WASM provided by the user
 - [client/src/main.rs:116](https://github.com/scs/substraTEE-worker/blob/M2/client/src/main.rs#L116): The extrinsic is sent to the substraTEE-node to the function “call_worker” of the substratee-proxy module. The client waits for the confirmation that the transaction got finalized
 - [client/src/main.rs:123](https://github.com/scs/substraTEE-worker/blob/M2/client/src/main.rs#L123): Use the substrate-api-client to subscribe to the event `CallConfirmed` of the substraTEE-node
 - [client/src/main.rs:125](https://github.com/scs/substraTEE-worker/blob/M2/client/src/main.rs#L125): When the event was received, print out the calculated and the received hash of the (unencrypted) payload




