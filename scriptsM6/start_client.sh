#!/bin/bash

clear

# wait until the worker is ready
read -p "Press enter to start the client"

# start the client and perform actions
cd /substraTEE/substraTEE-worker/client

NURL=ws://192.168.10.10
NPORT=9977
WURL=192.168.10.20
WPORT=9111

CLIENT="../target/release/substratee-client --node-url ${NURL} --node-port ${NPORT}"
WORKERPORT=" --worker-url ${WURL} --worker-port ${WPORT}"

AMOUNTSHIELD=50000000000
AMOUNTTRANSFER=25000000000
AMOUNTUNSHIELD=15000000000

echo "* Query on-chain enclave registry:"
${CLIENT} list-workers
echo ""

# TODO: This does not work when multiple workers are in the registry
echo "* Reading MRENCLAVE of first worker"
read MRENCLAVE <<< $(${CLIENT} list-workers | awk '/  MRENCLAVE: / { print $2 }')
echo "  MRENCLAVE = ${MRENCLAVE}"
echo ""

echo "* Get balance of Alice's on-chain account"
${CLIENT} balance "//Alice"
echo ""

echo "* Get balance of Bob's on-chain account"
${CLIENT} balance "//Bob"
echo ""

echo "* Create a new incognito account for Alice"
ICGACCOUNTALICE=$(${CLIENT} trusted new-account ${WORKERPORT} --mrenclave ${MRENCLAVE})
echo "  Alice's incognito account = ${ICGACCOUNTALICE}"
echo ""

echo "* Create a new incognito account for Bob"
ICGACCOUNTBOB=$(${CLIENT} trusted new-account ${WORKERPORT} --mrenclave ${MRENCLAVE})
echo "  Bob's incognito account = ${ICGACCOUNTBOB}"
echo ""

echo "* Shield ${AMOUNTSHIELD} tokens to Alice's incognito account"
${CLIENT} shield-funds //Alice ${ICGACCOUNTALICE} ${AMOUNTSHIELD} ${MRENCLAVE} ${WORKERPORT}
echo ""

echo "* Waiting 10 seconds"
sleep 10
echo ""

echo -n "Get balance of Alice's incognito account"
${CLIENT} trusted balance ${ICGACCOUNTALICE} ${WORKERPORT} --mrenclave ${MRENCLAVE}
echo ""

echo "* Get balance of Alice's on-chain account"
${CLIENT} balance "//Alice"
echo ""

echo "* Send ${AMOUNTTRANSFER} funds from Alice's incognito account to Bob's incognito account"
$CLIENT trusted transfer ${ICGACCOUNTALICE} ${ICGACCOUNTBOB} ${AMOUNTTRANSFER} ${WORKERPORT} --mrenclave ${MRENCLAVE}
echo ""

echo "* Get balance of Alice's incognito account"
${CLIENT} trusted balance ${ICGACCOUNTALICE} ${WORKERPORT} --mrenclave ${MRENCLAVE}
echo ""

echo "* Bob's incognito account balance"
${CLIENT} trusted balance ${ICGACCOUNTBOB} ${WORKERPORT} --mrenclave ${MRENCLAVE}
echo ""

echo "* Un-shield ${AMOUNTUNSHIELD} tokens from Alice's incognito account"
${CLIENT} trusted unshield-funds ${ICGACCOUNTALICE} //Alice ${AMOUNTUNSHIELD} ${MRENCLAVE} ${WORKERPORT} --mrenclave ${MRENCLAVE} --xt-signer //Alice
echo ""

echo "* Waiting 10 seconds"
sleep 10
echo ""

echo -n "Get balance of Alice's incognito account"
${CLIENT} trusted balance ${ICGACCOUNTALICE} ${WORKERPORT} --mrenclave ${MRENCLAVE}
echo ""

echo "* Get balance of Alice's on-chain account"
${CLIENT} balance "//Alice"
echo ""

read -p "Press enter to exit"
