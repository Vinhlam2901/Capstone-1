//===========================================================================================================
// Project         : UART & RVV
// Module          : Shift Left Logic 8bit for VALU
// File            : sll_8bit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 12/12/2025
// Updated date    : 12/03/2026
//============================================================================================================
module sll_8bit (
  input  wire [7:0] vrs1_data,
  input  wire [7:0] vrs2_data,
  output wire [7:0] vrd_data
);
//chi dich 3 bit thap nhat cua vrs2_data
//dich trai zero extend
  wire [7:0] s0, s1;
  assign s0       = vrs2_data[0] ? {vrs1_data[6:0], 1'b0} : vrs1_data; //dich phai 1 bit hoac 0 dich
  assign s1       = vrs2_data[1] ? {       s0[5:0], 2'b0} : s0;       //dich phai 2 bit hoac 0 dich
  assign vrd_data = vrs2_data[2] ? {       s1[2:0], 4'b0} : s1;       //dich phai 4 bit hoac 0 dich
endmodule
