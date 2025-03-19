#!/usr/bin/env -S deno run --allow-read

import { keccak_256 } from "npm:@noble/hashes/sha3";
import { bytesToHex } from "npm:@noble/hashes@1.6.1/utils";

/**
 * Generate a selector from a signature using keccak256
 * @param signature The function signature
 * @returns The selector (first 4 bytes of the hash)
 */
function generateSelector(signature: string): string {
  const encoder = new TextEncoder();
  const data = encoder.encode(signature);
  const hash = keccak_256(data);
  const hashHex = bytesToHex(hash);
  return "0x" + hashHex.substring(0, 8);
}

async function main() {
  // Check arguments
  if (Deno.args.length < 1) {
    console.error("Usage: find_error.ts <abi_filename> [0xerror_selector]");
    Deno.exit(1);
  }

  const abiFilename = Deno.args[0];
  let errorSelector = Deno.args.length > 1 ? Deno.args[1].toLowerCase() : null;
  
  // Ensure error selector starts with 0x if provided
  if (errorSelector && !errorSelector.startsWith("0x")) {
    errorSelector = "0x" + errorSelector;
  }

  try {
    // Read and parse the ABI file
    const abiContent = await Deno.readTextFile(abiFilename);
    const abi = JSON.parse(abiContent);

    // Extract all error types from the ABI
    const errors = abi.filter((item: any) => item.type === "error");
    
    // Process each error
    for (const error of errors) {
      const name = error.name;
      
      // Build the error signature by joining input types
      const inputs = error.inputs.map((input: any) => input.type).join(",");
      const errorSignature = `${name}(${inputs})`;
      
      // Generate the selector
      const selector = generateSelector(errorSignature);
      
      if (!errorSelector) {
        console.log(`Found error type: ${name} with selector: ${selector}`);
      }
      
      // Check if this selector matches the one we're looking for (if provided)
      if (errorSelector && selector.startsWith(errorSelector)) {
        console.log(`Matched Error: ${errorSignature} -> ${selector}`);
        Deno.exit(0);
      }
    }

    // If we get here and a selector was provided, no match was found
    if (errorSelector) {
      console.log(`No matching error found for selector ${errorSelector}`);
    }
  } catch (error) {
    console.error(`Error processing ABI file: ${error.message}`);
    Deno.exit(1);
  }
}

main();
