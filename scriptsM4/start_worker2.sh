#!/bin/bash

clear

# configure and start the ipfs daemon
ipfs init
ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080
ipfs daemon > /substraTEE/output/ipfs_daemon2.log &

# wait until the worker 1 and the client have interacted
sleep 1m

# start the worker 2
cd /substraTEE/substraTEE-worker-M4/bin
./substratee_worker getsignkey 2>&1 | tee /substraTEE/output/worker2_getsignkey.log
./substratee_worker getpublickey 2>&1 | tee /substraTEE/output/worker2_getpublickey.log
./substratee_worker -p 9977 -w 9112 -r 8112 --ns 192.168.10.10 --ws 192.168.10.22 worker 2>&1 | tee /substraTEE/output/worker2.log

read -p "Press enter to continue"