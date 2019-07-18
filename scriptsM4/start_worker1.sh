#!/bin/bash

clear

# configure and start the ipfs daemon
ipfs init
ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080
ipfs daemon > /substraTEE/output/ipfs_daemon1.log &

# allow the node to get ready
sleep 3s

# start the worker 1
cd /substraTEE/substraTEE-worker-M4/bin
./substratee_worker getsignkey 2>&1 | tee /substraTEE/output/worker1_getsignkey.log
./substratee_worker getpublickey 2>&1 | tee /substraTEE/output/worker1_getpublickey.log
./substratee_worker -p 9977 -w 9111 -r 8111 --ns 192.168.10.10 --ws 192.168.10.21 worker 2>&1 | tee /substraTEE/output/worker1.log

read -p "Press enter to continue"