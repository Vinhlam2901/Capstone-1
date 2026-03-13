//===========================================================================================================
// Project         : UART & RVV
// Module          : Shift Right Arithmetic 8bit for VALU
// File            : sra_8bit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 12/03/2025
// Updated date    : 12/03/2026
//============================================================================================================
module sra_8bit (
  input       [7:0] vrs1_data,
  input       [7:0] vrs2_data,
  output wire [7:0] vrd_data
);
//chi dich 3 bit thap nhat cua vrs2_data: vi SEW = 2^3 = 8bit
//dich phai msb extend
  wire [7:0] s0, s1;
  // dich phai voi msb = 1
  assign s0       = vrs2_data[0] ? {vrs1_data[7],     vrs1_data[7:1] } : vrs1_data;
  assign s1       = vrs2_data[1] ? {{2{vrs1_data[7]}},       s0[7:2] } : s0;
  assign vrd_data = vrs2_data[2] ? {{4{vrs1_data[7]}},       s1[7:4]} : s1;
endmodule
