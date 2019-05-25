# SubstraTEE Security
The following is an overview of security aspects of substraTEE, mainly focusing on Intel SGX properties. It is neither complete nor guaranteed to be accurate. It just reflects the best of our knowledge ATM.

## exploitable properties of SGX
* An enclave has no way to control how many instances of that enclave are instantiated.
* An enclave process can be interrupted at any point. 
* monotonic counter and trusted time provided by Platform Services (PSE) rely on Intel ME, which [doesn't have a good reputation for security](https://en.wikipedia.org/wiki/Intel_Management_Engine#Security_vulnerabilities).

See: [black hat presentation by Swami](https://youtu.be/0ZxBO3vLB-A)

## Attacks

### Rollback/Replay Attack
An enclave has no way to verify that it is operating on the latest state (i.e. read from a sealed file on disk).

It cannot be assured that calls to the enclave happen sequentially. They can happen in parallel, possibly leaking secrets i.e. because a secret with weak randomness is encrypted many times with the same nonce, weakening the confidentiality.

**Countermeasures**

* monotonic counter (i.e. Intel PSE, based on ME). If you choose to trust Intel ME!
* Blockchain registers the hash of the latest state, so a state update is only valid when it refers to the latest registered state. This doesn't solve the cause, but the symptoms.


### Global State Malleability
An enclave ecall can be interrupted at any time by interrupts. Instead of returning after the interrupt, an attacker can then call the same ecall again.

**Countermeasures**
* verify-first-write-last: not only for sealed storage, but also for global state variables.

### Reentrancy Attack / Global state Malleability
Can be a special case of the *Rollback Attack*.
Similar to smart contracts reentrancy.

[Explanation of reentrancy attack for smart contracts](https://medium.com/@gus_tavo_guim/reentrancy-attack-on-smart-contracts-how-to-identify-the-exploitable-and-an-example-of-an-attack-4470a2d8dfe4)

**Countermeasures**

* verify-first-write-last 

### Simulator Attacks

Some emulator pretends to be an enclave.

**Countermeasure**

* Remote Attestation with IAS

### Man-In-The-Middle Attack

Intel could attack a service provider by always replying to RA requests positively and put a simulated enclave as a MITM.
(Intel knows, which SP is requesting a RA as it knows the SPID)

**Countermeasure**

none.

See [black hat presentation by Swami](https://youtu.be/0ZxBO3vLB-A) at 34:50


### Foreshadow
This side-channel attack compromised both integrity and confidentiality (and therefore Remote Attestation as well). It has been fixed in Intel's recent microcode.

[Foreshadow](https://en.wikipedia.org/wiki/Foreshadow_(security_vulnerability))

**Countermeasures**

* update your SGX HW
* verify SGX is up-to-date for all substraTEE-workers (IAS tells us with their remote attestation report)

