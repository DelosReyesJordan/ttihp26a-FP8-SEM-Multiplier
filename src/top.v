`timescale 1ns / 1ps

/*
    Top module:
    This is where it all comes together, we run our sign, mantissa, and exponent code
    We also have two specific exceptions
    (1) NaN: if an input is S.1111.111, then the output must also be S.1111.111
    (2) Zero: if an input is S.0000.000, then the output must also be S.0000.000
    
    Priority: NaN > Zero > All other cases
*/ 

module top (
    input clk,
    input reset,

    input  [7:0] A,
    input  [7:0] B,

    output reg [7:0] Result        
    );
    
    // Break inputs into Sign, Exponent, and Mantissa portions
    wire sign_A = A[7];
    wire sign_B = B[7];

    wire [3:0] exp_A  = A[6:3];
    wire [3:0] exp_B  = B[6:3];

    wire [2:0] mant_A = A[2:0];
    wire [2:0] mant_B = B[2:0];
    
    // NaN detection (S.1111.111)
    wire A_is_nan = (exp_A == 4'b1111) && (mant_A == 3'b111);
    wire B_is_nan = (exp_B == 4'b1111) && (mant_B == 3'b111);

    wire any_nan = A_is_nan || B_is_nan;
    
    // Zero detection (S.0000.000)
    wire A_is_zero = (exp_A == 4'b0000) && (mant_A == 3'b000);
    wire B_is_zero = (exp_B == 4'b0000) && (mant_B == 3'b000);
    
    wire any_zero = A_is_zero || B_is_zero;
    
    // Sign
    wire sign_out;
    
    sign sign_block (
        .clk(clk),
        .reset(reset),
        .A_sign(sign_A),
        .B_sign(sign_B),
        .Sign_out(sign_out)
    );
    
    // Mantissa
    wire [2:0] mant_out;
    wire [1:0] exp_inc;
    
    wire saturate_mantissa;

    mantissa mant_block (
        .clk(clk),
        .reset(reset),
        .A_Mant(mant_A),
        .B_Mant(mant_B),
        .A_Exp(exp_A),
        .B_Exp(exp_B),
        .Saturate_Mantissa(saturate_mantissa),
        .Mant_Out(mant_out),
        .Exp_Inc(exp_inc)
    );
    
    // Exponent
    wire [3:0] exp_out;

    exponent exp_block (
        .clk(clk),
        .reset(reset),
        .A_Exp(exp_A),
        .B_Exp(exp_B),
        .Exp_Inc(exp_inc),
        .Exp_Out(exp_out),
        .Saturate_Mantissa(saturate_mantissa)
    );
    
    // Final Part: Putting it all together
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            Result <= 8'd0;
        end
        else begin
            if (any_nan) begin
                // Canonical NaN
                Result <= 8'b0_1111_111;
            end
            else if (any_zero) begin
                Result <= 8'b0_0000_000;
            end
            else begin
                Result <= {sign_out, exp_out, mant_out};
            end
        end
    end
    
endmodule
