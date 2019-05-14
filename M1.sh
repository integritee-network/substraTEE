#!/bin/bash

# command to start the docker container
# docker run -v $(pwd):/substraTEE/backup -ti substratee

echo "start the node in the backgroud"
/substraTEE/substraTEE-node-M1/target/release/substratee-node --dev > /substraTEE/node.log 2>&1 &

echo ""
echo "start the worker to generate the keys"
cd /substraTEE/substraTEE-worker-M1
./bin/substratee_worker getpublickey
./bin/substratee_worker getsignkey

echo ""
echo "Start the worker in the background"
./bin/substratee_worker worker > /substraTEE/worker.log 2>&1 &

echo ""
echo "Start the client"
./bin/substratee_client | tee /substraTEE/client.log

echo ""
echo "Query the counter"
./bin/substratee_client getcounter | tee /substraTEE/counter.log
