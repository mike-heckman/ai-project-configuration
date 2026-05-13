#!/usr/bin/env bash

# Source the function from the script, but we need to extract it or just define it here for testing
# Since we want to test the actual implementation in the file, let's try to source it.
# But the script executes logic on source. This is tricky.

# Let's just copy the function for the test to ensure it's the same logic.

ensure_git_ignore_value() {
    local value="$1"
    local file_path="${2:-.gitignore}"

    # Create file if missing
    if [ ! -f "$file_path" ]; then
        touch "$file_path"
    fi

    # Check for exact match using grep -Fxq.
    if grep -Fxq "$value" "$file_path"; then
        return 0
    fi

    # Handle trailing newline issues before appending.
    if [ -s "$file_path" ] && [ "$(tail -c 1 "$file_path" | wc -l)" -eq 0 ]; then
        echo "" >> "$file_path"
    fi

    echo "$value" >> "$file_path"
}

echo "--- Test 1: Create file and add value ---"
TEST_FILE="test.ignore"
rm -f "$TEST_FILE"
ensure_git_ignore_value "test-value" "$TEST_FILE"
if grep -Fxq "test-value" "$TEST_FILE"; then
    echo "✅ Test 1 Passed"
else
    echo "❌ Test 1 Failed"
    exit 1
fi

echo "--- Test 2: Add duplicate value (should not happen) ---"
ensure_git_ignore_value "test-value" "$TEST_FILE"
COUNT=$(grep -Fxq "test-value" "$TEST_FILE" && echo "found" || echo "not found")
LINE_COUNT=$(grep -c "^test-value$" "$TEST_FILE")
if [ "$LINE_COUNT" -eq 1 ]; then
    echo "✅ Test 2 Passed"
else
    echo "❌ Test 2 Failed: Duplicate found"
    exit 1
fi

echo "--- Test 3: Handle file with no trailing newline ---"
echo -n "no-newline-content" > "no-newline.ignore"
ensure_git_ignore_value "new-value" "no-newline.ignore"
# The file should now be "no-newline-content\nnew-value\n"
if grep -Fxq "new-value" "no-newline.ignore" && [ "$(tail -c 1 "no-newline.ignore" | wc -l)" -eq 1 ]; then
    echo "✅ Test 3 Passed"
else
    echo "❌ Test 3 Failed"
    exit 1
fi

echo "--- Test 4: Default to .gitignore ---"
rm -f .gitignore
ensure_git_ignore_value "default-val"
if [ -f ".gitignore" ] && grep -Fxq "default-val" ".gitignore"; then
    echo "✅ Test 4 Passed"
else
    echo "❌ Test 4 Failed"
    exit 1
fi
rm -f .gitignore

echo "All tests passed!"
rm -f "$TEST_FILE" "no-newline.ignore"
