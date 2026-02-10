module decoder_5to32 (
    input       [4:0]  a_i,
    output wire [31:0] out_o
);
  assign out_o[0]  = ~a_i[4] & ~a_i[3] & ~a_i[2] & ~a_i[1] & ~a_i[0];
  assign out_o[1]  = ~a_i[4] & ~a_i[3] & ~a_i[2] & ~a_i[1] &  a_i[0];
  assign out_o[2]  = ~a_i[4] & ~a_i[3] & ~a_i[2] &  a_i[1] & ~a_i[0];
  assign out_o[3]  = ~a_i[4] & ~a_i[3] & ~a_i[2] &  a_i[1] &  a_i[0];
  assign out_o[4]  = ~a_i[4] & ~a_i[3] &  a_i[2] & ~a_i[1] & ~a_i[0];
  assign out_o[5]  = ~a_i[4] & ~a_i[3] &  a_i[2] & ~a_i[1] &  a_i[0];
  assign out_o[6]  = ~a_i[4] & ~a_i[3] &  a_i[2] &  a_i[1] & ~a_i[0];
  assign out_o[7]  = ~a_i[4] & ~a_i[3] &  a_i[2] &  a_i[1] &  a_i[0];
  assign out_o[8]  = ~a_i[4] &  a_i[3] & ~a_i[2] & ~a_i[1] & ~a_i[0];
  assign out_o[9]  = ~a_i[4] &  a_i[3] & ~a_i[2] & ~a_i[1] &  a_i[0];
  assign out_o[10] = ~a_i[4] &  a_i[3] & ~a_i[2] &  a_i[1] & ~a_i[0];
  assign out_o[11] = ~a_i[4] &  a_i[3] & ~a_i[2] &  a_i[1] &  a_i[0];
  assign out_o[12] = ~a_i[4] &  a_i[3] &  a_i[2] & ~a_i[1] & ~a_i[0];
  assign out_o[13] = ~a_i[4] &  a_i[3] &  a_i[2] & ~a_i[1] &  a_i[0];
  assign out_o[14] = ~a_i[4] &  a_i[3] &  a_i[2] &  a_i[1] & ~a_i[0];
  assign out_o[15] = ~a_i[4] &  a_i[3] &  a_i[2] &  a_i[1] &  a_i[0];
  assign out_o[16] =  a_i[4] & ~a_i[3] & ~a_i[2] & ~a_i[1] & ~a_i[0];
  assign out_o[17] =  a_i[4] & ~a_i[3] & ~a_i[2] & ~a_i[1] &  a_i[0];
  assign out_o[18] =  a_i[4] & ~a_i[3] & ~a_i[2] &  a_i[1] & ~a_i[0];
  assign out_o[19] =  a_i[4] & ~a_i[3] & ~a_i[2] &  a_i[1] &  a_i[0];
  assign out_o[20] =  a_i[4] & ~a_i[3] &  a_i[2] & ~a_i[1] & ~a_i[0];
  assign out_o[21] =  a_i[4] & ~a_i[3] &  a_i[2] & ~a_i[1] &  a_i[0];
  assign out_o[22] =  a_i[4] & ~a_i[3] &  a_i[2] &  a_i[1] & ~a_i[0];
  assign out_o[23] =  a_i[4] & ~a_i[3] &  a_i[2] &  a_i[1] &  a_i[0];
  assign out_o[24] =  a_i[4] &  a_i[3] & ~a_i[2] & ~a_i[1] & ~a_i[0];
  assign out_o[25] =  a_i[4] &  a_i[3] & ~a_i[2] & ~a_i[1] &  a_i[0];
  assign out_o[26] =  a_i[4] &  a_i[3] & ~a_i[2] &  a_i[1] & ~a_i[0];
  assign out_o[27] =  a_i[4] &  a_i[3] & ~a_i[2] &  a_i[1] &  a_i[0];
  assign out_o[28] =  a_i[4] &  a_i[3] &  a_i[2] & ~a_i[1] & ~a_i[0];
  assign out_o[29] =  a_i[4] &  a_i[3] &  a_i[2] & ~a_i[1] &  a_i[0];
  assign out_o[30] =  a_i[4] &  a_i[3] &  a_i[2] &  a_i[1] & ~a_i[0];
  assign out_o[31] =  a_i[4] &  a_i[3] &  a_i[2] &  a_i[1] &  a_i[0];
endmodule
