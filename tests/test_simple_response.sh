#!/bin/bash

# Test script specifically for the simple response extraction
# This script tests the function with the fallback disabled

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

# Source the ai.sh file to get access to the extract_commands function
source "$PARENT_DIR/ai.sh"

# Create temporary files for testing
TEMP_COMMANDS=$(mktemp)

# Set debug mode to 0 to disable the fallback extraction
DEBUG=0

# Function to test extraction on a file
test_file() {
    local file="$1"
    local filename=$(basename "$file")

    echo "===================================================="
    echo "Testing extraction on: $filename (with fallback disabled)"
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

# Test only the simple response file
test_file "$SCRIPT_DIR/ai_response_simple.md"

# Clean up
rm -f "$TEMP_COMMANDS"

echo "Test completed!"
