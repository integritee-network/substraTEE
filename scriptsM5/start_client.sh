#!/bin/bash

clear

# wait until the worker is ready
sleep 32s

# start the client and perform an incognito transfer
cd /substraTEE/substraTEE-worker/bin
./substratee_client -p 9977 -a 192.168.10.10 2>&1 | tee /substraTEE/output/client.log

read -p "Press enter to continue"