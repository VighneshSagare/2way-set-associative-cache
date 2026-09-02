# 2-Way Set-Associative Cache

A compact synthesizable SystemVerilog cache model designed to demonstrate cache organization and address decomposition.

## Configuration
Default configuration:
- 32-bit address
- 256-byte data capacity
- 8-byte cache line
- 2-way set associativity
- 16 sets

Formula:
```text
sets = capacity / (line_size * ways)
     = 256 / (8 * 2)
     = 16
```

## Features
- Tag / index / offset decomposition
- 2-way set associative lookup
- Valid bits
- LRU replacement bit per set
- Read hit / miss
- Write hit / miss
- Write-back dirty bit
- Line refill interface
- Parameterized geometry

This project is intentionally focused on the cache controller rather than a full CPU.

## Run
```bash
iverilog -g2012 -o sim src/cache_2way.s tb/tb_cache_2way.s
vvp sim
```
