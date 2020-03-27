# Use Case CDN Subscriptions

SubstraTEE could be used to restrict (narrow- or broadband) content delivery to paying users. Examples could be blogs, articles, video streaming, video on-demand, music streaming or on-deman aso.

## Basic SubstraTEE application for CDN

* Subscriptions are managed on-chain, as are payments (can be flat subscription fees or pay-per-use)
* SubstraTEE-worker holds the content-encryption key pair (CEK). Only the worker enclave(s) can read this RSA private key. 
No consumers or publishers nor operators have access
* publishers commit their content (encrypted with the CEK (RSA+AES)) to IPFS and register the content on-chain, providing the IPFS url
* consumers request content from the substraTEE-worker over a TLS channel (can be https, wss, json-rpc, REST), which 
  * authenticates the consumer and looks up subscription status on-chain
  * fetches the requested content from IPFS
  * decrypts the content
  * sends the content to the consumer over the previously established TLS channel
  
## CEK turnover
As a first implementation, the CEK can stay constant over time. However, we should be able to rotate this key if we need to revoke.

## Access to Archive Prior to Subscription
Because the private CEK is known to all worker enclaves and never needs to be known to publishers or subscribers we do not need to trans-encrypt content. 
It doesn't matter at what time a consumer subscribes. The worker can deliver all prior content to the subscriber. 
The subscription metadata can include restrictions to archive access. 

## Pay per use
Pay per use bears the risks of leaking private information. We'd suggest to maintain subscription balances within the worker enclave, not onchain. This way, the public doesn't learn detailed usage patterns. See our [private-tx example](./M5_DEMO.md) for how this could work.
