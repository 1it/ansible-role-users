#!/bin/bash

# Test runner for validating the empty users_group_list fix
# This script runs the test to ensure no "[]" group is created

set -e

echo "=== Running Empty Group List Test ==="
echo "Testing fix for users_group_list: [] issue..."
echo

# Change to the role directory
cd "$(dirname "$0")/.."

# Run the test playbook
echo "Executing test playbook..."
ansible-playbook -i tests/inventory tests/test_empty_group_list.yml -v

echo
echo "=== Test Results ==="
if [ $? -eq 0 ]; then
    echo "✅ SUCCESS: Empty group list test passed!"
else
    echo "❌ FAILURE: Empty group list test failed!"
    exit 1
fi

echo
echo "=== Additional Verification ==="
echo "Checking for any groups with suspicious names..."
getent group | grep -E '\[|\]' || echo "No suspicious group names found."

echo
echo "Test completed successfully! 🎉"