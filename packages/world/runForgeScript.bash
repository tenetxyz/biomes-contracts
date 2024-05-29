#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <filename>"
  exit 1
fi

chainId="31337" # Default to dev mode chain ID
rpcUrl="http://127.0.0.1:8545"  # Default to dev mode URL

# Loop through all arguments to check for the --prod flag
if [ "$NODE_ENV" = "testnet" ]; then
  rpcUrl="https://rpc.garnetchain.com"
  chainId="17069"
elif [ "$NODE_ENV" = "mainnet" ]; then
  rpcUrl="https://rpc.redstonechain.com"
  chainId="690"
fi

echo "Using RPC: $rpcUrl"
echo "Using Chain Id: $chainId"

# Extract worldAddress using awk
worldAddress=$(awk -v id="$chainId" -F'"' '$2 == id {getline; print $4}' worlds.json)

echo "Using WorldAddress: $worldAddress"

command="forge script $1 --sig 'run(address)' '${worldAddress}' --broadcast --rpc-url ${rpcUrl}"

# Loop through all arguments to check for the --verbose flag
for arg in "$@"
do
  if [ "$arg" = "--verbose" ]; then
    echo "Running in verbose mode"
    command="${command} -vvvv"
    break  # Exit the loop once the --verbose flag is found
  fi
done

echo "Running script: $command"

eval "$command"