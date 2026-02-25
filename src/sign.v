`timescale 1ns / 1ps

/*
    Sign Logic (XOR): 
    1 * 1 = 1
    1 * -1 = -1
    -1 * 1 = -1 
    -1 * -1 = 1
*/

module sign (
        input clk, reset,
        input A_sign, B_sign, 
        output reg Sign_out
    );
    
    always @(posedge clk or posedge reset) begin
    
        if (reset) begin
            // Pressing Resets to 0
            Sign_out <= 1'b0;
        end 
        
        else begin    
            Sign_out <= A_sign ^ B_sign;
        end
    end 
    
endmodule
