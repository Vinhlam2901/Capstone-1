module full_adder_16bit (
        input       [15:0] A_i,
        input       [15:0] Y_i,
        input              C_i,
        output wire [15:0] Sum_o,
        output wire        c_o
    );
    wire [14:0] c;
    wire w1, w2, w3;
    assign Sum_o[0]  =  A_i[0]  ^ Y_i[0]   ^ C_i;
    assign c[0]      = (A_i[0]  & Y_i[0])  | ((A_i[0] ^ Y_i[0]) & C_i);
    assign Sum_o[1]  =  A_i[1]  ^ Y_i[1]   ^ c[0];
    assign c[1]      = (A_i[1]  & Y_i[1])  | ((A_i[1] ^ Y_i[1]) & c[0]);
    assign Sum_o[2]  =  A_i[2]  ^ Y_i[2]   ^ c[1];
    assign c[2]      = (A_i[2]  & Y_i[2])  | ((A_i[2] ^ Y_i[2]) & c[1]);
    assign Sum_o[3]  =  A_i[3]  ^ Y_i[3]   ^ c[2];
    assign c[3]      = (A_i[3]  & Y_i[3])  | ((A_i[3] ^ Y_i[3]) & c[2]);
    assign Sum_o[4]  =  A_i[4]  ^ Y_i[4]   ^ c[3];
    assign c[4]      = (A_i[4]  & Y_i[4])  | ((A_i[4] ^ Y_i[4]) & c[3]);
    assign Sum_o[5]  =  A_i[5]  ^ Y_i[5]   ^ c[4];
    assign c[5]      = (A_i[5]  & Y_i[5])  | ((A_i[5] ^ Y_i[5]) & c[4]);
    assign Sum_o[6]  =  A_i[6]  ^ Y_i[6]   ^ c[5];
    assign c[6]      = (A_i[6]  & Y_i[6])  | ((A_i[6] ^ Y_i[6]) & c[5]);
    assign Sum_o[7]  =  A_i[7]  ^ Y_i[7]   ^ c[6];
    assign c[7]      = (A_i[7]  & Y_i[7])  | ((A_i[7] ^ Y_i[7]) & c[6]);
    assign Sum_o[8]  =  A_i[8]  ^ Y_i[8]   ^ c[7];
    assign c[8]      = (A_i[8]  & Y_i[8])  | ((A_i[8] ^ Y_i[8]) & c[7]);
    assign Sum_o[9]  =  A_i[9]  ^ Y_i[9]   ^ c[8];
    assign c[9]      = (A_i[9]  & Y_i[9])  | ((A_i[9] ^ Y_i[9]) & c[8]);
    assign Sum_o[10] =  A_i[10] ^ Y_i[10]  ^ c[9];
    assign c[10]     = (A_i[10] & Y_i[10]) | ((A_i[10] ^ Y_i[10]) & c[9]);
    assign Sum_o[11] =  A_i[11] ^ Y_i[11]  ^ c[10];
    assign c[11]     = (A_i[11] & Y_i[11]) | ((A_i[11] ^ Y_i[11]) & c[10]);
    assign Sum_o[12] =  A_i[12] ^ Y_i[12]  ^ c[11];
    assign c[12]     = (A_i[12] & Y_i[12]) | ((A_i[12] ^ Y_i[12]) & c[11]);
    assign Sum_o[13] =  A_i[13] ^ Y_i[13]  ^ c[12];
    assign c[13]     = (A_i[13] & Y_i[13]) | ((A_i[13] ^ Y_i[13]) & c[12]);
    assign Sum_o[14] =  A_i[14] ^ Y_i[14]  ^ c[13];
    assign c[14]     = (A_i[14] & Y_i[14]) | ((A_i[14] ^ Y_i[14]) & c[13]);
    assign Sum_o[15] =  A_i[15] ^ Y_i[15]  ^ c[14];
    assign c_o       = (A_i[15] & Y_i[15]) | ((A_i[15] ^ Y_i[15]) & c[14]);
    endmodule
