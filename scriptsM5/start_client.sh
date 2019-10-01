#!/bin/bash

clear

# wait until the worker 1 is ready
sleep 32s

# start the client and send first transaction
cd /substraTEE/substraTEE-worker/bin
./substratee_client -p 9977 -a 192.168.10.10 2>&1 | tee /substraTEE/output/client_first.log

# wait until worker 2 registered
sleep 30s

# start the client and send second transaction
cd /substraTEE/substraTEE-worker/bin
./substratee_client -p 9977 -a 192.168.10.10 2>&1 | tee /substraTEE/output/client_second.log

# wait until transaction is processed
sleep 30s

# start the client and send third transaction
cd /substraTEE/substraTEE-worker/bin
./substratee_client -p 9977 -a 192.168.10.10 2>&1 | tee /substraTEE/output/client_second.log

read -p "Press enter to continue"