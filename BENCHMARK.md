# Benchmark

ops  				| call_counter_wasm 	| call_counter 			| no compose_extrinsic 	| msg decryption		| counter update 		| sgx_file_read     | counter update + no_ops ocall
--------------------|-----------------------|-----------------------|-----------------------|-----------------------|-----------------------|-------------------------------|---------------------------
ecall				| &#9745;				| &#9745;				| &#9745;				| &#9745;				| &#9745;				| &#9745;		    | &#9745;
sgx::fs::read (rsa key)	| &#9745;			| &#9745;				| &#9745;				| &#9745;				| 						| &#9745;           | &#9745;
rsa msg decryption	| &#9745;				| &#9745;				| &#9745;				| &#9745;				| 						|       			| &#9745;				
wasm sha256 computation	| &#9745;				
wasm invokation 	| &#9745;				
std::file::read		| &#9745;				| &#9745;				| &#9745;				| 						| &#9745;				|       			| &#9745;
sgx::fs::read (aes key)	| &#9745;			| &#9745;				| &#9745;				| 						| &#9745;	    		|       			| &#9745;				
aes decryption		| &#9745;				| &#9745;				| &#9745;				| 						| &#9745;				|   				| &#9745;				
aes decryption		| &#9745;				| &#9745;				| &#9745;				| 						| &#9745;				| 					| &#9745;				
std::file::write	| &#9745;				| &#9745;				| &#9745;				| 						| &#9745;				| 					| &#9745;				
no_ops_ocall    	|						| 						| 						| 						| 						| 					| 
compose extrinsic 	| &#9745;				| &#9745;				| 						| 						| 						| 					| &#9745;
**invokations/s**	| 332					| 342					| 365					| 400					| 5000					| 8196				| 4587


- **call_counter** represents the operations that are performed in an milestone 1 counter state update.
- **call_counter_wasm** represents the operations that are performed in milestone 2 counter state update.
- **sgx::fs::read:** an SGX call that accesses the sealed enclave storage, which is only readable by one specific enclave instance.
- **no_ops_ocall:** an ocall (a call from the enclave to the host) that does nothing in order to see the impact of an ocall itself.
- **invokations/s:** stands for the number of executions per seconds that can be achieved. This does roughly correspond to tx/s.

## Analysis
- RSA decryption is by far the most expensive step in the whole pipeline. This, however, is hard to migitate as long as no more efficient asymmetric encryption exists.
- The effect of sgx::fs::read does only have a small impact.
- wasm invokation's impact is negligible
- If the current RSA de/-encryption process is optimized >1000 tx/s, is achievable.

