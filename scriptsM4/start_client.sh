#!/bin/bash

clear

# wait until the worker 1 is ready
sleep 30s

# start the client and send first transaction
cd /substraTEE/substraTEE-worker-master/bin
./substratee_client -p 9977 2>&1 | tee /substraTEE/output/client_first.log

# wait until worker 2 registered
sleep 10s

# start the client and send second transaction
cd /substraTEE/substraTEE-worker-master/bin
./substratee_client -p 9977 2>&1 | tee /substraTEE/output/client_second.log

# wait until transaction is processed
sleep 20s

# query the counter
cd /substraTEE/substraTEE-worker-master/bin
./substratee_client -p 9977 getcounter 2>&1 | tee /substraTEE/output/client_counter.log

echo "Client finished"

read -p "Press enter to continue"