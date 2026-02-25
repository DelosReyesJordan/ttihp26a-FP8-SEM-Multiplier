/*
 * Copyright (c) 2026 Jordan Delos Reyes
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_DelosReyesJordan_SEM (
    input  wire [7:0] ui_in,    // Dedicated inputs  -> A
    output wire [7:0] uo_out,   // Dedicated outputs -> Result
    input  wire [7:0] uio_in,   // Bidirectional IOs -> B (input only)
    output wire [7:0] uio_out,  // Not used
    output wire [7:0] uio_oe,   // Output enable (0=input, 1=output)
    input  wire       ena,      // Always 1 (can ignore)
    input  wire       clk,      // Clock
    input  wire       rst_n     // Active LOW reset
);

    // Convert active-low reset to active-high
    wire reset = ~rst_n;

    // Internal result wire
    wire [7:0] result_internal;

    // Instantiate top module
    top sem_multiplier (
        .clk(clk),
        .reset(reset),
        .A(ui_in),
        .B(uio_in),
        .Result(result_internal)
    );

    // Output assignment
    assign uo_out = result_internal;

    // We are NOT using bidirectional outputs
    assign uio_out = 8'b00000000;

    // 0 = input mode
    assign uio_oe  = 8'b00000000;

    // Prevent unused warnings
    wire _unused = &{ena, 1'b0};

endmodule
