#!/bin/bash

clear

# copy the intel SGX keys for remote attestation
cp /substraTEE/intel_cert/*.txt /substraTEE/substraTEE-worker/bin/

# configure and start the ipfs daemon
echo "* Initialize the IPFS daemon"
ipfs init
ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080
ipfs daemon > /substraTEE/output/ipfs_daemon1.log &
echo ""

# allow the node to get ready
sleep 3s

# setup the worker
echo "* Setup the worker"
cd /substraTEE/substraTEE-worker/bin
./substratee-worker signing-key 2>&1 | tee /substraTEE/output/worker_signing-key.log
./substratee-worker shielding-key 2>&1 | tee /substraTEE/output/worker_shielding-key.log
./substratee-worker init-shard 2>&1 | tee /substraTEE/output/worker_init-shard.log
echo ""

# start the worker
echo "* Start the worker"
./substratee-worker -p 9977 -w 9111 -r 8111 --ns ws://192.168.10.10 --ws 192.168.10.20 run 2>&1 | tee /substraTEE/output/worker.log

read -p "Press enter to exit"
