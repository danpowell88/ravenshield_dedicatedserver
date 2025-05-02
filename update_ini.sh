#!/bin/bash

# Check if required arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 ENV_PREFIX INI_FILE"
    echo "Example: $0 SERVER_ /path/to/server.ini"
    exit 1
fi

ENV_PREFIX=$1
INI_FILE=$2

# Verify the INI file exists
if [ ! -f "$INI_FILE" ]; then
    echo "Error: INI file '$INI_FILE' not found"
    exit 1
fi

# Process environment variables with the given prefix
for var in $(env | grep "^${ENV_PREFIX}.*="); do
    # Parse the environment variable
    env_name=$(echo "$var" | cut -d= -f1)
    env_value=$(echo "$var" | cut -d= -f2-)
    
    # Remove prefix and split remaining parts
    config_path=${env_name#${ENV_PREFIX}}
    
    # Replace __ with dots for section separation
    config_path=${config_path//__/_}
    
    # Split into section and key
    section=$(echo "$config_path" | rev | cut -d_ -f2- | rev | tr '_' '.')
    key=$(echo "$config_path" | rev | cut -d_ -f1 | rev)
    
    echo "Updating [$section] $key=$env_value in $INI_FILE"
    crudini --set "$INI_FILE" "$section" "$key" "$env_value"
done