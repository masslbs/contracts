#!/usr/bin/env python

import json
import argparse
from web3 import Web3

def generate_selector(signature):
    return Web3.keccak(text=signature).hex()[:10]

def find_matching_error(abi, error_selector_to_match):
    for item in abi:
        if item['type'] == 'error':
            # Generate the error signature
            error_signature = item['name'] + '(' + ','.join([input['type'] for input in item['inputs']]) + ')'
            # Generate the selector
            selector = generate_selector(error_signature)
            print(f"found error type: {item['name']} with selector: {selector}")

            # Compare with the known error selector
            if selector.startswith(error_selector_to_match):
                return error_signature, selector
    return None, None

def main():
    # Set up argument parser
    parser = argparse.ArgumentParser(description='Match Ethereum error selector with contract ABI.')
    parser.add_argument('abi_filename', type=str, help='The filename of the contract ABI JSON')
    parser.add_argument('error_selector', type=str, help='The error selector to match')

    args = parser.parse_args()

    # Ensure the error selector is in the correct format
    error_selector = args.error_selector.lower()

    # Load the ABI file
    with open(args.abi_filename, 'r') as abi_file:
        abi = json.load(abi_file)

    # Find matching error
    #print(f"looking for: {error_selector}")
    error_signature, selector = find_matching_error(abi, error_selector)

    if error_signature:
        print(f"Matched Error: {error_signature} -> {selector}")
    else:
        print(f"No matching error found for selector {args.error_selector}")

if __name__ == "__main__":
    main()
