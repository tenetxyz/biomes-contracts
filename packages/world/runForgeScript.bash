#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <filename> [--verbose] [--sig 'customSignature(args)'] [arg1 arg2 ...] [-- forge_args]"
  exit 1
fi

# Set chain ID from environment variable or default to local development
chainId=${CHAIN_ID:-31337}

# Set RPC URL based on chain ID
case "${chainId}" in
  "695569")
    rpcUrl="https://rpc.pyropechain.com"
    ;;
  "17069")
    rpcUrl="https://rpc.garnetchain.com"
    ;;
  "690")
    rpcUrl="https://rpc.redstonechain.com"
    ;;
  *)
    # Default to local development
    rpcUrl="http://127.0.0.1:8545"
    ;;
esac

echo "Using RPC: $rpcUrl"
echo "Using Chain Id: $chainId"

# Extract worldAddress using awk
worldAddress=$(awk -v id="$chainId" -F'"' '$2 == id {getline; print $4}' worlds.json)

echo "Using WorldAddress: $worldAddress"

# Initialize variables
scriptFile=$1
shift  # Remove the first argument (script filename)
verbose=false
customSig=""
args=()
forge_args=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --verbose)
      verbose=true
      shift
      ;;
    --sig)
      customSig=$2
      shift 2
      ;;
    --)
      shift
      forge_args="$@"
      break
      ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done

# Determine the signature and arguments
if [ -z "$customSig" ]; then
  if [[ $scriptFile == *"GiveScript"* ]]; then
    if [ ${#args[@]} -ne 1 ]; then
      echo "GiveScript requires 1 argument: <playerAddress>"
      exit 1
    fi
    signature="run(address,address)"
    scriptArgs="'${worldAddress}' '${args[0]}'"
  elif [[ $scriptFile == *"TeleportScript"* ]]; then
    if [ ${#args[@]} -ne 4 ]; then
      echo "TeleportScript requires 4 arguments: <playerAddress> <x> <y> <z>"
      exit 1
    fi
    signature="run(address,address,int32,int32,int32)"
    # Quote each argument individually
    scriptArgs="'${worldAddress}' '${args[0]}' '${args[1]}' '${args[2]}' '${args[3]}'"
  else
    signature="run(address)"
    scriptArgs="'${worldAddress}'"
  fi
else
  # Quote each argument for custom signatures too
  quoted_args=()
  for arg in "${args[@]}"; do
    quoted_args+=("'$arg'")
  done
  signature=$customSig
  scriptArgs="'${worldAddress}' ${quoted_args[@]}"
fi

# Build the command
command="forge script $scriptFile --sig '$signature' --broadcast --legacy --rpc-url ${rpcUrl}"

# Add verbose flag if specified
if [ "$verbose" = true ]; then
  command="${command} -vvvv"
fi

# Add script arguments after -- to handle negative numbers
command="${command} -- ${scriptArgs}"

# Add any additional forge arguments
if [ ! -z "$forge_args" ]; then
  command="$command $forge_args"
fi

echo "Running script: $command"
eval "$command"