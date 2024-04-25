#!/bin/bash

# Extract worldAddress using awk
worldAddress=$(awk -F'"' '/"31337":/{getline; print $4}' worlds.json)

# Start constructing the command
command="pnpm mud test --worldAddress='${worldAddress}' --forgeOptions='-vvv"

# Conditionally append the user-provided test option
if [[ -n "$1" ]]; then
  command+=" $1'"
else
  command+="'"
fi

# Loop through all arguments to check for the --prod flag
for arg in "$@"
do
  if [ "$arg" = "--verbose" ]; then
    echo "Running in verbose mode"
    command="GAS_REPORTER_ENABLED=true pnpm mud test --worldAddress='${worldAddress}' --forgeOptions='-vvv"

    # Conditionally append the user-provided test option
    if [[ -n "$2" ]]; then
      command+=" $2' | pnpm gas-report --stdin"
    else
      command+="' | pnpm gas-report --stdin"
    fi

    break  # Exit the loop once the --prod flag is found
  fi
done


# Output the command
echo "Running command: $command"

# Execute the command and display output as it runs
eval $command