#!/bin/bash
rm -rf build
mkdir -p build
cmake -DCMAKE_BUILD_TYPE=Debug -S./source -B./build
cmake --build ./build --parallel --config=Debug
cmake --install ./build --cofig=Debug