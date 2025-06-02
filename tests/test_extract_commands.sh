#!/bin/bash

# Test script for the extract_commands function
# This script tests the function against all example .md files

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

# Source the ai.sh file to get access to the extract_commands function
source "$PARENT_DIR/ai.sh"

# Create temporary files for testing
TEMP_COMMANDS=$(mktemp)

# Set debug mode to 1 to see detailed output
DEBUG=1

# Function to test extraction on a file
test_file() {
    local file="$1"
    local filename=$(basename "$file")
    
    echo "===================================================="
    echo "Testing extraction on: $filename"
    echo "===================================================="
    
    # Run the extract_commands function on the file
    extract_commands "$file" "$TEMP_COMMANDS" "$DEBUG"
    
    echo "Extracted commands:"
    echo "----------------------------------------------------"
    cat "$TEMP_COMMANDS"
    echo "----------------------------------------------------"
    echo "Found $(wc -l < "$TEMP_COMMANDS") commands"
    echo
}

# Test all example files
for file in "$SCRIPT_DIR"/ai_*.md; do
    test_file "$file"
done

# Clean up
rm -f "$TEMP_COMMANDS"

echo "All tests completed!"
