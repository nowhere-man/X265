# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

x265 is an open source HEVC (H.265) video encoder. The codebase is ~100 C++ source files implementing the complete HEVC encoding pipeline with extensive SIMD optimizations for x86, ARM, and ARM64 architectures.

## Build Commands

**Quick build (Debug):**
```bash
./build.sh
```

**Manual CMake build:**
```bash
cmake -DCMAKE_BUILD_TYPE=Release -S./source -B./build
cmake --build ./build --parallel --config=Release
```

The source directory is `./source` (not the repo root). This is configured in `.vscode/settings.json` for CMake IntelliSense.

**Code formatting:**
```bash
./clang-format.sh
```

**Run unit tests:**
```bash
cmake --build ./build --target TestBench
./build/TestBench
```

## Architecture Overview

The codebase separates encoding logic from low-level primitives and data structures:

### Encoding Pipeline (source/encoder/)

- **api.cpp** - Implementation of public API defined in source/x265.h
- **encoder.cpp/h** - Top-level encoder orchestration, manages worker threads and GOP structure
- **frameencoder.cpp/h** - Per-frame encoding coordinator, manages CTU rows and wavefront processing
- **analysis.cpp/h** - Core mode decision logic: recursive CU partitioning, prediction mode selection
- **search.cpp/h** - Rate-distortion optimization (RDO) and transform coefficient optimization
- **motion.cpp/h** - Motion estimation algorithms
- **slicetype.cpp/h** - Lookahead analysis for slice type decision and rate control
- **entropy.cpp/h** - CABAC entropy encoder
- **framefilter.cpp/h** - Post-encoding deblocking and SAO filtering

### Core Data Structures (source/common/)

- **frame.cpp/h** - Picture buffer with reconstructed, original, and working pixel data
- **framedata.cpp/h** - Per-frame encoding state and statistics
- **cudata.cpp/h** - Coding Unit data: modes, motion vectors, partitioning decisions
- **lowres.cpp/h** - Half-resolution frames for lookahead analysis
- **slice.cpp/h** - Slice header and reference picture management
- **yuv.cpp/h** - Planar YUV buffer operations
- **primitives.cpp/h** - Function pointer tables for performance-critical operations
- **cpu.cpp/h** - Runtime CPU feature detection

### SIMD Optimizations

- **source/common/x86/** - SSE2/SSE4/AVX/AVX2/AVX512 assembly (NASM) and intrinsics
- **source/common/aarch64/** - ARM64 NEON, DotProd, I8MM, SVE, SVE2 intrinsics
- **source/common/arm/** - ARM NEON intrinsics

Primitives (SAD, SATD, DCT, prediction, filtering) have C reference implementations with SIMD overrides registered at encoder initialization based on CPU capabilities.

### I/O and Utilities

- **source/input/** - YUV and Y4M input file readers
- **source/output/** - Raw bitstream, Y4M, and reconstruction output writers
- **source/dynamicHDR10/** - HDR10+ dynamic metadata handling
- **source/test/** - TestBench harnesses for validating primitive implementations

## Key Concepts

**HEVC CTU Structure**: The encoder recursively analyzes Coding Tree Units (CTUs) in a quadtree, evaluating CU sizes from 64x64 down to 8x8, selecting optimal intra/inter prediction modes via RDO.

**Wavefront Parallel Processing (WPP)**: CTU rows are encoded in parallel with dependencies allowing row N to start after row N-1 completes 2 CTUs.

**Lookahead**: The slicetype module analyzes downscaled frames to determine slice types (I/P/B) and feeds data to the rate controller before full encoding.

**Rate Control Modes**:
- CQP: Constant quantization parameter
- CRF: Constant rate factor (perceptual quality target)
- ABR: Average bitrate with VBV buffer constraints

**API Flow**: Client calls `x265_encoder_open()` ’ `x265_encoder_encode()` repeatedly ’ `x265_encoder_close()`. The encode call may return compressed NAL units immediately or with delay due to frame reordering.

## Build Outputs

- `build/libx265.a` - Static library
- `build/libx265.{so,dylib}` - Shared library
- `build/cli` - Command-line encoder (if enabled)
- `build/TestBench` - Unit test executable