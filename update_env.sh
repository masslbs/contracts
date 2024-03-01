#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 Mass Labs
#
# SPDX-License-Identifier: GPL-3.0-or-later

#

set -e
if [ -f "$1" ]; then
    fname="$1"
else
    fname="/tmp/deploy.s.sol/31337/run-latest.json" 
fi

function get_addr()
{
	local reg=$1
	local addr=$(jq -r ".transactions[] | select(.contractName==\"${reg}\") | select(.transactionType | startswith(\"CREATE\")) | .contractAddress" $fname)
	eval $reg="'$addr'"
}

get_addr RelayReg
echo "RELAY_REGISTRY_ADDRESS=$RelayReg"

get_addr StoreReg
echo "STORE_REGISTRY_ADDRESS=$StoreReg"

get_addr PaymentFactory
echo "PAYMENT_FACTORY_ADDRESS=$PaymentFactory"

get_addr EuroDollarToken
test -n "$EuroDollarToken" && echo "ERC20_TOKEN_ADDRESS=$EuroDollarToken"
