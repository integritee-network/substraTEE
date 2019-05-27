# Code Documentation for M1
This page describes the implemented functions of M1 with corresponding code references.

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
1) Instruct the enclave to generate a RSA3072 key pair which is used for encrypting the payload sent from the substraTEE-client to the substraTEE-worker. This is done with the command `getpublickey`.
   - **Important**: only the public key leaves the enclave while the private key stays in the enclave.

2) Instruct the enclave to generate a ED25519 key pair which is used for signing the extrinsic sent from the substraTEE-worker to the substraTEE-node. This is done with the command `getsignkey`.
    - **Important**: only the public key leaves the enclave while the private key stays in the enclave.

3) Subscribe to substraTEE-proxy events, forward any received payload to the enclave and send the extrinsic (that is composed in the enclave) back to the substraTEE-node. This is done with the command `worker`.

### Implementation
The functions are implemented at the following places:

**Important**: Only the functions defined in [enclave/Enclave.edl](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/enclave/Enclave.edl) are allowed to be called in the enclave. The return values also have to be defined here.

#### Funtion 1: RSA3072 key pair generation
- [worker/src/enclave_wrappers.rs:159](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/worker/src/enclave_wrappers.rs#L159): The enclave is started
- [worker/src/enclave_wrappers.rs:178](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/worker/src/enclave_wrappers.rs#L178): The public RSA3072 key is requested from the enclave
  - [enclave/src/lib.rs:80](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/enclave/src/lib.rs#L80): Enter the function `get_rsa_encryption_pubkey`
  - [enclave/src/lib.rs:83](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/enclave/src/lib.rs#L83): The enclave checks if a key pair file (`./bin/rsa3072_key_sealed.bin`) is already present and if not, create a new one
  - [enclave/src/lib.rs:96](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/enclave/src/lib.rs#L96): Read the key pair file and extract the public key
  - [enclave/src/lib.rs:108](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/enclave/src/lib.rs#L108): Return the public key
- [worker/src/enclave_wrappers.rs:200](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/worker/src/enclave_wrappers.rs#L200): The received public RSA3072 key is written to an unencrypted text file (./bin/rsa_pubkey.txt)

#### Function 2: ED25519 key pair generation
Same principle as Function 1 but starting at line 107 in the [worker/src/enclave_wrappers.rs](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/worker/src/enclave_wrappers.rs#L107)

#### Function 3: Process encrypted payload from the substraTEE-node

- [worker/src/main.rs:87](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/worker/src/main.rs#L87): The enclave is started
- [worker/src/main.rs:106](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/worker/src/main.rs#L106): The worker calls the substrate-api-client and subscribes to events from the substraTEE-node
- [worker/src/main.rs:131](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/worker/src/main.rs#L131): When it receives a Balances event, it prints out the decoded information
- [worker/src/main.rs:146](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/worker/src/main.rs#L146): When it receives a substraTEE-proxy event, it forwards the received (encrypted) payload to the function `process_forwarded_payload`
  - [worker/src/enclave_wrappers.rs:47](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/worker/src/enclave_wrappers.rs#L47): The (encrypted) payload is forwarded to the function `decrypt_and_process_payload`
    - [worker/src/enclave_wrappers.rs:63](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/worker/src/enclave_wrappers.rs#L63): The (encrypted) payload and additional information to compose a valid extrinsic is given to the function `call_counter` in the enclave
      - [enclave/src/lib.rs:194](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/enclave/src/lib.rs#L194): The payload is decoded using the RSA3072 private key of the enclave
      - [enclave/src/lib.rs:195](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/enclave/src/lib.rs#L195): The account and the increment are read from the decrypted payload
      - [enclave/src/lib.rs:199](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/enclave/src/lib.rs#L199): The sealed counter is read by the enclave
      - [enclave/src/lib.rs:209](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/enclave/src/lib.rs#L209): The increment is added to the correct account
      - [enclave/src/lib.rs:210](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/enclave/src/lib.rs#L210): The updated counter is written back to the disk, as sealed file
      - [enclave/src/lib.rs:219](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/enclave/src/lib.rs#L219): The enclave composes the extrinsic with the hash of the (unencrypted) payload that is returned to the worker. The target module is the function `confirm_call` of the substraTEE-proxy
  - [worker/src/enclave_wrappers.rs:59](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/worker/src/enclave_wrappers.rs#L59): The extrinsic is sent through the substrate-api-client to the substraTEE-node

## substraTEE-client
The client is a sample implementation and only serves the purpose to demonstrate the functionalities of the substraTEE-node and –worker. It implements the following sequence:
 - [client/src/main.rs:59](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/client/src/main.rs#L59): Get the free balance from //Alice
 - [client/src/main.rs:62](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/client/src/main.rs#L62): Get the current account nonce of //Alice
 - [client/src/main.rs:65](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/client/src/main.rs#L65): Fund //Alice with 1_000_000
 - [client/src/main.rs:70](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/client/src/main.rs#L70): Transfer 1000 from //Alice to the account of the TEE (identified by the public ED25519 key of the enclave)
 - [client/src/main.rs:73](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/client/src/main.rs#L73): Compose an extrinsic with an encrypted payload (using the public RSA3072 key of the enclave).
     - The payload contains the string `Alice,42` which means that the account of Alice will be incremented by 42 in the enclave
 - [client/src/main.rs:86](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/client/src/main.rs#L86): Send the extrinsic to the substraTEE-node to the function “call_worker” of the substratee-proxy module and wait for the confirmation that the transaction got finalized
 - [client/src/main.rs:92](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/client/src/main.rs#L92): Use the substrate-api-client to subscribe to the event `CallConfirmed` of the substraTEE-node
 - [client/src/main.rs:94](https://github.com/scs/substraTEE-worker/blob/fddcdb995f1eccf1fd9eeb89e5c70aa835f8db6c/client/src/main.rs#L94): When the event was received, print out the calculated and the received hash of the (unencrypted) payload




