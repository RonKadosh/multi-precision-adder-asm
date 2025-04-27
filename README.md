# Arbitrary Size Integer Addition in Assembly (x86-32)

## Overview
This project implements an arbitrary-size integer adder in x86-32 Assembly language.  
It supports user input in hexadecimal format or randomly generated numbers via a custom Linear Feedback Shift Register (LFSR) pseudorandom generator.

Developed as part of the Extended System Programming Lab at BGU.

## Features
- Input arbitrary-size hexadecimal numbers manually or randomly generate them.
- Dynamic memory allocation (`malloc`) for flexible-sized structures.
- Manual implementation of addition for arbitrary-length numbers.
- Manual parsing of hexadecimal input from stdin.
- LFSR-based random number generator for random numbers.
- Fully implemented in pure Assembly (NASM syntax).
- Low-level system call usage (`int 0x80`) for program exit.

## Technologies
- Assembly x86-32 (NASM syntax).
- System Programming: `malloc`, `printf`, `fgets`, syscall exit.
- Memory Management: dynamic allocation and manual structure management.

## Build Instructions
Assuming NASM and GCC installed:
```bash
build
```

## Run Instructions
- Statically hard-coded numbers addition:
```bash
./multi
```

- For LFSR-based randon number generator:
```bash
./multi -R
```

- To input numbers manually from stdin:
```bash
./multi -I
```

## Notes
- Input must be in valid hexadecimal format.
- This is a low-level educational project focusing on manual memory and number management.
- Tested on Linux x86-32 environments.
