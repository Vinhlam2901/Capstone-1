//===========================================================================================
// Project         : Single Cycle of RISV - V
// Module          : Module Shift Right Arithmetic
// File            : sra.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 9/9/2025
// Updated date    : 6/11/2025 - Finished
//===========================================================================================
module sra (
  input       [31:0] rs1_data,
  input       [31:0] rs2_data,
  output wire [31:0] rd_data
);
//chi dich 5 bit thap nhat cua rs2_data
//dich phai msb extend
  wire [31:0] s0, s1, s2, s3;
  // dich phai voi msb = 1
  assign s0           = rs2_data[0] ? {rs1_data[31],      rs1_data[31:1] } : rs1_data;
  assign s1           = rs2_data[1] ? {{2{rs1_data[31]}},       s0[31:2] } : s0;
  assign s2           = rs2_data[2] ? {{4{rs1_data[31]}},       s1[31:4] } : s1;
  assign s3           = rs2_data[3] ? {{8{rs1_data[31]}},       s2[31:8] } : s2;
  assign rd_data      = rs2_data[4] ? {{16{rs1_data[31]}},      s3[31:16]} : s3;
endmodule
