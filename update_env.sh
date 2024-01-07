#!/usr/bin/env bash
#

set -e

function get_addr()
{
	local reg=$1
	local addr=$(jq -r ".transactions[] | select(.contractName==\"${reg}\") | select(.transactionType==\"CREATE2\") | .contractAddress" /tmp/deploy.s.sol/31337/run-latest.json)
	eval $reg="'$addr'"
}

get_addr RelayReg
echo "RELAY_REGISTRY_ADDRESS=$RelayReg"

get_addr StoreReg
echo "STORE_REGISTRY_ADDRESS=$StoreReg"

get_addr PaymentFactory
echo "PAYMENT_FACTORY_ADDRESS=$PaymentFactory"
