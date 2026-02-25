`timescale 1ns / 1ps

/*
    Mantissas:
    Represents 1.MMM (for 3 Mantissa bits) -- there is an implicit leading 1.
    Where each Mantissa bit represents 2^-(Bit Index Starting from 1)
    So Mantissa = 111 represents 1 + 0.5 + 0.25 + 0.125 = 1.875, NOT 0.875
    
    Operation: Multiply Mantissas
    A.MMM * B.MMM = Out.MMMMMM
    Since our final product cannot hold more than 3 mantissa bits,
    We will keep the three most signifiant mantissa bits (MSMB)
    
    Our range is from 1.000 x 1.000 = 1.000 
    to 1.111 x 1.111 = 11.xxxx base (2) = 1.875 x 1.875 = 3.515625 (base 10)
    We also see that our "prefix" can change from 1.MMM to 11.MMM
    This also requires some case-based shifting
    
    If our final mantissa is between: [1, 2) (decimal scale), we do nothing
    Instead if our final mantissa is between (2, 4], we shift right once and increase our exponent by 1
    
    For FP8, we also need to round, we will use RNE (Round Nearest Even) logic for that.
    This means that our Exp_inc can increment twice (once for normalization the once again for rounding)
    But actually that is impossible as we do not have a large enough product for both normalization and rounding
    
    One final rule: If the input exponents are subnormal,
    then the implicit leading 1 is changed to an implicit leading 0
*/

module mantissa (
    input clk,
    input reset,
    input [2:0] A_Mant,
    input [2:0] B_Mant,
    
    // We need our exponents to check if we have a subnormal
    input [3:0] A_Exp,
    input [3:0] B_Exp,
    
    // This is if we have saturation from our exponents
    input Saturate_Mantissa,
        
    output reg [2:0] Mant_Out,
        
    // This is for telling our exponent to increment if we shift mantissa to the right
    output reg [1:0] Exp_Inc
);

    // We have to add the leading 1 or leading 0 for subnormals
    wire [3:0] A_sig;
    wire [3:0] B_sig;
    
    // The 8 bits are as follows: XX.XXXXXX (base 2), a 4x4 multiply results in 8 bits product
    wire [7:0] product;
    
    // We need another wire connection for the normalization step, this is how we select our mantissa output
    wire [2:0] normalized;
    
    // (1) Building Significands
    assign A_sig = (A_Exp == 4'b0000) ? {1'b0, A_Mant} // Subnormal
                                      : {1'b1, A_Mant}; // Normal
                                      
    assign B_sig = (B_Exp == 4'b0000) ? {1'b0, B_Mant} // Subnormal
                                      : {1'b1, B_Mant}; // Normal
                                      
    // (2) Multiplying   
    
    assign product = A_sig * B_sig;
    
    /* Tried using IP here, it needs a clock to work                            
    mult_gen_0 mantissa_mult (
        .A(A_sig),
        .B(B_sig),
        .P(product)
    );
    */
    
    // (3) Looking at MSB to see if it is 1 or 0 and shifting
    wire shift_right;
    assign shift_right = product[7];
    assign normalized = (shift_right) ? product[6:4]   // shift right 1, so we select X(X.XX)XXXX
                                     : product[5:3];  // already normalized, so we select XX.(XXX)XXX
    
    // (4) RNE Logic
    wire guard, round_bit, sticky, round_up;
    
    assign guard = (shift_right) ? product[3] : product[2];
    assign round_bit = (shift_right) ? product[2] : product[1];
    assign sticky = shift_right ? (|product[2:0]) : (|product[1:0]);
    assign round_up = guard && (round_bit || sticky || normalized[0]);
    
    // Rounding
    wire [3:0] mant_rounded;
    assign mant_rounded = {1'b0, normalized} + round_up;

    // Detect rounding overflow (i.e., 1.111 -> 10.000)
    wire round_overflow;
    assign round_overflow = mant_rounded[3];

    // (5) Final mantissa selection
    wire [2:0] mant_final;
    assign mant_final = (round_overflow) ? 3'b000
                                         : mant_rounded[2:0];
    
    // (6) Declaring Exp_inc
    wire [1:0] exp_increment_total;
    assign exp_increment_total = shift_right + round_overflow;
    
    // (7) Putting it all together
    always @(posedge clk or posedge reset) begin
    if (reset) begin
        // Pressing resets to 000 for Mantissa
        Mant_Out <= 3'd0;
        Exp_Inc <= 2'b0;
    end
    
    // 3 cases (1) If exponent is saturated (2-3) If exponent is not saturated and mantissa is shifted/not shifted
    else begin
        if (Saturate_Mantissa) begin
            Mant_Out <= 3'b110; // This is max normal number, 111 would be used for NaN values
            Exp_Inc  <= 1'b0;
        end
        else begin
            Mant_Out <= mant_final;
            Exp_Inc  <= exp_increment_total; // Again (X)X.XXXXXX determines to increment or not
        end
    end
end
    
endmodule
