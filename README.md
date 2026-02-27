# 8-bit SEM Floating-Point Multiplier

This project implements an experimental **8-bit Sign–Exponent–Mantissa (SEM) floating-point multiplier** for TinyTapeout

## Project Overview

The design operates on two 8-bit inputs encoded in the format:

S EEEE MMM

Where:

- 1 sign bit  
- 4 exponent bits  
- 3 mantissa bits  

The output is also an 8-bit SEM-formatted number.

## Features

- Synchronous datapath architecture  
- Special numerical case handling:
  - Canonical NaN detection  
  - Zero detection  
- Pipeline-friendly computation  
- Hardware-oriented normalization behavior  

Priority rule:

NaN > Zero > Normal multiplication

## Functional Description

The multiplier is divided into three computational blocks:

### Sign Block
- Computes output sign using XOR logic.

### Mantissa Block
- Performs multiplication and normalization operations.

### Exponent Block
- Computes exponent adjustment and saturation behavior.

The final result is registered and updated on the rising edge of the clock.

## Input and Output Mapping

| Signal | Description |
|---|---|
| ui_in[7:0] | Operand A (SEM format) |
| uio_in[7:0] | Operand B (SEM format) |
| uo_out[7:0] | Multiplication result |
| clk | System clock |
| rst_n | Active-low reset |
| ena | Enable signal |

## Special Numerical Cases

### NaN Representation

If an input equals:

S.1111.111

The output is forced to canonical NaN:

0_1111_111

---

### Zero Representation

If an input equals:

S.0000.000

The output is forced to zero.

## Testing

The project includes a cocotb-based verification testbench.

To run tests locally:

cd test
make clean
make

## External Hardware Requirements

This design is fully digital and does not require external components.

## Project Purpose

This project explores hardware-efficient floating-point datapath design for low-precision computation and experimental arithmetic architectures.

## License

Apache 2.0

## Acknowledgements

Built for educational and experimental silicon design using Tiny Tapeout infrastructure.
