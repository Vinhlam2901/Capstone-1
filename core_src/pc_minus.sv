//===========================================================================================
// Project         : Single Cycle of RISV - V
// Module          : Program Counter Register
// File            : pc_reg.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 9/9/2025
// Updated date    : 13/9/2025
//===========================================================================================
module pc_minus (
  input  wire  [31:0]  pc_reg,
  input  wire  [31:0]  op,
  output reg   [31:0]  pc_o
);
  add_subtract a1 (
    .a_i(pc_reg),
    .b_i(op),
    .cin_i(1'b1),
    .result_o(pc_o),
    .cout_o()
  );

endmodule
