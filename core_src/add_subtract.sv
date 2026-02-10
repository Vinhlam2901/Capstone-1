//===========================================================================================
// Project         : Single Cycle of RISV - V
// Module          : Module Adder and Subtractor Selectable
// File            : add_subtract.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 9/9/2025
// Updated date    : 6/11/2025 - Finished
//===========================================================================================
module add_subtract (
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    input              cin_i,     // 0: Cộng, 1: Trừ
    output wire [31:0] result_o,
    output             cout_o
);
  wire [30:0] c;
  wire [31:0] b_mod_i;
  wire raw_cout;
  // Tính b XOR cin cho từng bit
  assign b_mod_i      = b_i ^ {32{cin_i}}; // nếu b_i là [3:0] và cin_i là 1 bit
  // FA[0]
  assign result_o[0]  =  a_i[0]  ^ b_mod_i[0]   ^ cin_i;
  assign c[0]         = (a_i[0]  & b_mod_i[0])  | ((a_i[0] ^ b_mod_i[0]) & cin_i);

  assign result_o[1]  =  a_i[1]  ^ b_mod_i[1]   ^ c[0];
  assign c[1]         = (a_i[1]  & b_mod_i[1])  | ((a_i[1] ^ b_mod_i[1]) & c[0]);

  assign result_o[2]  =  a_i[2]  ^ b_mod_i[2]   ^ c[1];
  assign c[2]         = (a_i[2]  & b_mod_i[2])  | ((a_i[2] ^ b_mod_i[2]) & c[1]);

  assign result_o[3]  =  a_i[3]  ^ b_mod_i[3]   ^ c[2];
  assign c[3]         = (a_i[3]  & b_mod_i[3])  | ((a_i[3] ^ b_mod_i[3]) & c[2]);

  assign result_o[4]  =  a_i[4]  ^ b_mod_i[4]   ^ c[3];
  assign c[4]         = (a_i[4]  & b_mod_i[4])  | ((a_i[4] ^ b_mod_i[4]) & c[3]);

  assign result_o[5]  =  a_i[5]  ^ b_mod_i[5]   ^ c[4];
  assign c[5]         = (a_i[5]  & b_mod_i[5])  | ((a_i[5] ^ b_mod_i[5]) & c[4]);

  assign result_o[6]  =  a_i[6]  ^ b_mod_i[6]   ^ c[5];
  assign c[6]         = (a_i[6]  & b_mod_i[6])  | ((a_i[6] ^ b_mod_i[6]) & c[5]);

  assign result_o[7]  =  a_i[7]  ^ b_mod_i[7]   ^ c[6];
  assign c[7]         = (a_i[7]  & b_mod_i[7])  | ((a_i[7] ^ b_mod_i[7]) & c[6]);

  assign result_o[8]  =  a_i[8]  ^ b_mod_i[8]   ^ c[7];
  assign c[8]         = (a_i[8]  & b_mod_i[8])  | ((a_i[8] ^ b_mod_i[8]) & c[7]);

  assign result_o[9]  =  a_i[9]  ^ b_mod_i[9]   ^ c[8];
  assign c[9]         = (a_i[9]  & b_mod_i[9])  | ((a_i[9] ^ b_mod_i[9]) & c[8]);

  assign result_o[10] =  a_i[10] ^ b_mod_i[10]  ^ c[9];
  assign c[10]        = (a_i[10] & b_mod_i[10]) | ((a_i[10] ^ b_mod_i[10]) & c[9]);

  assign result_o[11] =  a_i[11] ^ b_mod_i[11]  ^ c[10];
  assign c[11]        = (a_i[11] & b_mod_i[11]) | ((a_i[11] ^ b_mod_i[11]) & c[10]);

  assign result_o[12] =  a_i[12] ^ b_mod_i[12]  ^ c[11];
  assign c[12]        = (a_i[12] & b_mod_i[12]) | ((a_i[12] ^ b_mod_i[12]) & c[11]);

  assign result_o[13] =  a_i[13] ^ b_mod_i[13]  ^ c[12];
  assign c[13]        = (a_i[13] & b_mod_i[13]) | ((a_i[13] ^ b_mod_i[13]) & c[12]);

  assign result_o[14] =  a_i[14] ^ b_mod_i[14]  ^ c[13];
  assign c[14]        = (a_i[14] & b_mod_i[14]) | ((a_i[14] ^ b_mod_i[14]) & c[13]);

  assign result_o[15] =  a_i[15] ^ b_mod_i[15]  ^ c[14];
  assign c[15]        = (a_i[15] & b_mod_i[15]) | ((a_i[15] ^ b_mod_i[15]) & c[14]);

  assign result_o[16] =  a_i[16] ^ b_mod_i[16]  ^ c[15];
  assign c[16]        = (a_i[16] & b_mod_i[16]) | ((a_i[16] ^ b_mod_i[16]) & c[15]);

  assign result_o[17] =  a_i[17] ^ b_mod_i[17]  ^ c[16];
  assign c[17]        = (a_i[17] & b_mod_i[17]) | ((a_i[17] ^ b_mod_i[17]) & c[16]);

  assign result_o[18] =  a_i[18] ^ b_mod_i[18]  ^ c[17];
  assign c[18]        = (a_i[18] & b_mod_i[18]) | ((a_i[18] ^ b_mod_i[18]) & c[17]);

  assign result_o[19] =  a_i[19] ^ b_mod_i[19]  ^ c[18];
  assign c[19]        = (a_i[19] & b_mod_i[19]) | ((a_i[19] ^ b_mod_i[19]) & c[18]);

  assign result_o[20] =  a_i[20] ^ b_mod_i[20]  ^ c[19];
  assign c[20]        = (a_i[20] & b_mod_i[20]) | ((a_i[20] ^ b_mod_i[20]) & c[19]);

  assign result_o[21] =  a_i[21] ^ b_mod_i[21]  ^ c[20];
  assign c[21]        = (a_i[21] & b_mod_i[21]) | ((a_i[21] ^ b_mod_i[21]) & c[20]);

  assign result_o[22] =  a_i[22] ^ b_mod_i[22]  ^ c[21];
  assign c[22]        = (a_i[22] & b_mod_i[22]) | ((a_i[22] ^ b_mod_i[22]) & c[21]);

  assign result_o[23] =  a_i[23] ^ b_mod_i[23]  ^ c[22];
  assign c[23]        = (a_i[23] & b_mod_i[23]) | ((a_i[23] ^ b_mod_i[23]) & c[22]);

  assign result_o[24] =  a_i[24] ^ b_mod_i[24]  ^ c[23];
  assign c[24]        = (a_i[24] & b_mod_i[24]) | ((a_i[24] ^ b_mod_i[24]) & c[23]);

  assign result_o[25] =  a_i[25] ^ b_mod_i[25]  ^ c[24];
  assign c[25]        = (a_i[25] & b_mod_i[25]) | ((a_i[25] ^ b_mod_i[25]) & c[24]);

  assign result_o[26] =  a_i[26] ^ b_mod_i[26]  ^ c[25];
  assign c[26]        = (a_i[26] & b_mod_i[26]) | ((a_i[26] ^ b_mod_i[26]) & c[25]);

  assign result_o[27] =  a_i[27] ^ b_mod_i[27]  ^ c[26];
  assign c[27]        = (a_i[27] & b_mod_i[27]) | ((a_i[27] ^ b_mod_i[27]) & c[26]);

  assign result_o[28] =  a_i[28] ^ b_mod_i[28]  ^ c[27];
  assign c[28]        = (a_i[28] & b_mod_i[28]) | ((a_i[28] ^ b_mod_i[28]) & c[27]);

  assign result_o[29] =  a_i[29] ^ b_mod_i[29]  ^ c[28];
  assign c[29]        = (a_i[29] & b_mod_i[29]) | ((a_i[29] ^ b_mod_i[29]) & c[28]);

  assign result_o[30] =  a_i[30] ^ b_mod_i[30]  ^ c[29];
  assign c[30]        = (a_i[30] & b_mod_i[30]) | ((a_i[30] ^ b_mod_i[30]) & c[29]);

  assign result_o[31] =  a_i[31] ^ b_mod_i[31]  ^ c[30];
  assign cout_o       = cin_i ? ~((a_i[31] & b_mod_i[31]) | ((a_i[31] ^ b_mod_i[31]) & c[30])) :
                                 (a_i[31] & b_mod_i[31]) | ((a_i[31] ^ b_mod_i[31]) & c[30]);
endmodule
