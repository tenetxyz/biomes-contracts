#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <filename>"
  exit 1
fi

# Extract worldAddress using awk
worldAddress=$(awk -F'"' '/"31337":/{getline; print $4}' worlds.json)

command="forge script $1 --sig 'run(address)' '${worldAddress}' --broadcast --rpc-url http://127.0.0.1:8545 -vv"

echo "Running script: $command"

eval "$command"