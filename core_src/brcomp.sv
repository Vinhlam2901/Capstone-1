//===========================================================================================
// Project         : Single Cycle of RISV - V
// Module          : Branch Compararison
// File            : brcomp.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 10/9/2025
// Updated date    : 6/11/2025 - Finished
//===========================================================================================
module brcomp (
    input  wire [31:0] i_rs1_data,
    input  wire [31:0] i_rs2_data,
    input  wire        i_br_un,   // 1 if unsign, 0 if sign
    output wire        o_br_equal,
    output wire        o_br_less
);
//===============================================DECLARATION=========================================
  wire [31:0] sub_o;
  wire cout, same_sign, diff_sign;
  wire o_br_less_uns, o_br_less_s;
  wire o_br_less1, o_br_less2, o_br_less3;
//===============================================CODE================================================
  add_subtract S1 (.a_i(i_rs1_data),.b_i(i_rs2_data),.cin_i(1'b1),.result_o(sub_o),.cout_o(cout));
  // sign check
  assign  same_sign     = (i_rs1_data[31] && i_rs2_data[31]) ? 1'b1 : 1'b0;  // if same sign : 1
  assign  diff_sign     = (i_rs1_data[31] ^  i_rs2_data[31]) ? 1'b1 : 1'b0;  // if diff sign : 1
  //o_br_less
  assign  o_br_less1    = (same_sign && sub_o[31]     ) ? 1'b1 :1'b0;     // same sign and have cout
  assign  o_br_less2    = (diff_sign && i_rs1_data[31]) ? 1'b1 : 1'b0;    // diff sign and rs1[31] = 1 (neg)
  assign  o_br_less3    = (((i_rs1_data[31] ^ i_rs2_data[31]) && (i_rs1_data[31] ^ sub_o[31])) ^ sub_o[31]); // ovf
  assign  o_br_less_s   = o_br_less1 || o_br_less2 || o_br_less3;
  assign  o_br_less_uns = cout;
  assign  o_br_less     = (i_br_un) ? (o_br_less_uns) : (o_br_less_s);
  //compare block
  assign  o_br_equal    = (sub_o[0]  ^ 1'b1) & (sub_o[1]  ^ 1'b1) & (sub_o[2]  ^ 1'b1) &
                          (sub_o[3]  ^ 1'b1) & (sub_o[4]  ^ 1'b1) & (sub_o[5]  ^ 1'b1) &
                          (sub_o[6]  ^ 1'b1) & (sub_o[7]  ^ 1'b1) & (sub_o[8]  ^ 1'b1) &
                          (sub_o[9]  ^ 1'b1) & (sub_o[10] ^ 1'b1) & (sub_o[11] ^ 1'b1) &
                          (sub_o[12] ^ 1'b1) & (sub_o[13] ^ 1'b1) & (sub_o[14] ^ 1'b1) &
                          (sub_o[15] ^ 1'b1) & (sub_o[16] ^ 1'b1) & (sub_o[17] ^ 1'b1) &
                          (sub_o[18] ^ 1'b1) & (sub_o[19] ^ 1'b1) & (sub_o[20] ^ 1'b1) &
                          (sub_o[21] ^ 1'b1) & (sub_o[22] ^ 1'b1) & (sub_o[23] ^ 1'b1) &
                          (sub_o[24] ^ 1'b1) & (sub_o[25] ^ 1'b1) & (sub_o[26] ^ 1'b1) &
                          (sub_o[27] ^ 1'b1) & (sub_o[28] ^ 1'b1) & (sub_o[29] ^ 1'b1) &
                          (sub_o[30] ^ 1'b1) & (sub_o[31] ^ 1'b1);
endmodule
