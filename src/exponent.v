`timescale 1ns / 1ps

/*
    Exponents:
    Represents 2^(Exp_out - Bias), for 4 exponent bits, Bias = 7
    So 2^1110 represents the value of 2^(7), NOT 2^14
    
    Operation: Multiplying same base means adding exponent
    But we need to account for the double bias so we subtract it
    We also have exponent increments from our mantissa (values range from 0-2)
    A_Exp + B_Exp - 7 + Exp_Inc = exp_temp (6 bit-signed)
    
    Edge cases in pseudo code:
        
        if (exp_temp > 15) { 
            * Set Exp_Out to Saturation '1110' and Saturate_Mantissa to HIGH *
        } else if (exp_temp < 1) {
            * Set Exp_Encoded to subnormal '0000' and Saturate_Mantissa to LOW * 
        } else {
            * Do nothing to Exp_Encoded and set Saturate_Mantissa to LOW *
        }
        
*/

module exponent (
    input clk,
    input reset,
    input [3:0] A_Exp,
    input [3:0] B_Exp,
    
    // This is if we need to increment exponent from our Mantissa
    input [1:0] Exp_Inc,

    output reg [3:0] Exp_Out,
    
    // This is for telling the Mantissa to Saturate if we set Exp_Unbiased to Saturation
    output reg Saturate_Mantissa
);

    /*
    We will use a temporary wider register to deal with edge cases, it's range is from -32 to 31
    The range of A and B (encoded) is 0 to 15 each (+2 for possible increment)
    So the range needed for our sum should be between -7 to 25
     
    With edge cases, we only need our output hold values between 0 and 15;
    However, with wrapping, a maximun sum of 25 is going to turn into -10,
    Thus converting what should be a saturation result to a subnormal one
    
    To counteract this, we use our temporary holder to deal with edge cases
    */ 
    
    wire signed [5:0] exp_temp;
    parameter BIAS = 7;
    
    // Addition will be combinational, we will force value to be signed
    assign exp_temp =
        $signed({2'b00, A_Exp}) +
        $signed({2'b00, B_Exp}) -
        $signed(BIAS) +
        $signed(Exp_Inc);

    always @(posedge clk or posedge reset) begin
    
        if (reset) begin
            // Pressing Resets defaults to the subnormal case
            Exp_Out <= 4'd0;
            Saturate_Mantissa <= 1'b0;
        end 
        
        else begin

        if (exp_temp > 15) begin
            Exp_Out <= 4'b1111;
            Saturate_Mantissa <= 1'b1;
        end

        else if (exp_temp < 1) begin
            Exp_Out <= 4'b0000;
            Saturate_Mantissa <= 1'b0;
        end

        else begin
            // Here, we truncate exp_temp to fit into Exp_out
            Exp_Out <= exp_temp[3:0];
            Saturate_Mantissa <= 1'b0;
        end
    end
end
endmodule

