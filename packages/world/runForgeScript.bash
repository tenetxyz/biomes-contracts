#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <filename>"
  exit 1
fi

chainId="31337" # Default to dev mode chain ID
rpcUrl="http://127.0.0.1:8545"  # Default to dev mode URL

# Loop through all arguments to check for the --prod flag
for arg in "$@"
do
  if [ "$arg" = "--prod" ]; then
    echo "Running in prod mode"
    rpcUrl="https://rpc.garnetchain.com"
    chainId="17069"
    break  # Exit the loop once the --prod flag is found
  fi
done

# Extract worldAddress using awk
worldAddress=$(awk -v id="$chainId" -F'"' '$2 == id {getline; print $4}' worlds.json)

command="forge script $1 --sig 'run(address)' '${worldAddress}' --broadcast --rpc-url ${rpcUrl} -vvvv"

echo "Running script: $command"

eval "$command"