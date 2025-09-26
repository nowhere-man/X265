#!/bin/bash

file_extensions=("h" "hpp" "c" "cc" "cpp")

if ! command -v clang-format &> /dev/null; then
    echo "can not find clang-format"
    exit 1
fi

for ext in "${file_extensions[@]}"; do
    find . -type f -name "*.${ext}" -exec clang-format -i {} \;
done

echo "finish"