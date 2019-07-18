#!/bin/bash

# clear the console
clear

# start the dev node
#  with specific ws-port and listening to external connections
/substraTEE/substraTEE-node-master/target/release/substratee-node --dev --ws-port 9977 --ws-external 2>&1 | tee /substraTEE/backup/node.log
