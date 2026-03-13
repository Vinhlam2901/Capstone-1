//===========================================================================================
// Project         : Single Cycle of RISV - V
// Module          : Module Shift Right Logic 8bit for VALU
// File            : srl_8bit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 9/9/2025
// Updated date    : 6/11/2025 - Finished
//===========================================================================================
module srl_8bit (
  input  wire [7:0] vrs1_data,
  input  wire [7:0] vrs2_data,
  output wire [7:0] vrd_data
);
//chi dich 3 bit thap nhat cua vrs2_data
//dich phai zero extend
  wire [7:0] s0, s1;
  assign s0       = vrs2_data[0] ? {1'b0, vrs1_data[7:1]} : vrs1_data; //dich phai 1 bit hoac 0 dich
  assign s1       = vrs2_data[1] ? {2'b0,        s0[7:2]} : s0;       //dich phai 2 bit hoac 0 dich
  assign vrd_data = vrs2_data[2] ? {4'b0,        s1[7:4]} : s1;      //dich phai 16 bit hoac 0 dich
endmodule
