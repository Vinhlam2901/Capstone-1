//===========================================================================================
// Project         : Single Cycle of RISV - V
// Module          : Program Counter Register
// File            : pc_reg.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 9/9/2025
// Updated date    : 13/9/2025
//===========================================================================================
module pc_reg (
  input  wire  [31:0]  pc_reg,
  input  wire  [31:0]  op,
  output reg   [31:0]  pc_o
);
  full_adder_32bit PCplus4 (
    .A_i(pc_reg),
    .Y_i(op),
    .C_i(1'b0),
    .Sum_o(pc_o),
    .c_o()
  );

endmodule
