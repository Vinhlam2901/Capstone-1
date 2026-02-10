//===========================================================================================
// Project         : Single Cycle of RISV - V
// Module          : Module Shift Right Logicsrl
// File            : srl.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 9/9/2025
// Updated date    : 6/11/2025 - Finished
//===========================================================================================
module srl (
  input       [31:0] rs1_data,
  input       [31:0] rs2_data,
  output wire [31:0] rd_data
);
//chi dich 5 bit thap nhat cua rs2_data
//dich phai zero extend
  wire [31:0] s0, s1, s2, s3, s4;
  assign s0 = rs2_data[0] ? {1'b0, rs1_data[31:1]}   : rs1_data; //dich phai 1 bit hoac 0 dich
  assign s1 = rs2_data[1] ? {2'b0, s0[31:2]}         : s0;       //dich phai 2 bit hoac 0 dich
  assign s2 = rs2_data[2] ? {4'b0, s1[31:4]}         : s1;       //dich phai 4 bit hoac 0 dich
  assign s3 = rs2_data[3] ? {8'b0, s2[31:8]}         : s2;       //dich phai 8 bit hoac 0 dich
  assign s4 = rs2_data[4] ? {16'b0, s3[31:16]}       : s3;      //dich phai 16 bit hoac 0 dich
  assign rd_data = s4;
endmodule
