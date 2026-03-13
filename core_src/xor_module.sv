//===========================================================================================
// Project         : Single Cycle of RISV - V
// Module          : XOR 32 bit
// File            : xor_32bit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 9/9/2025
// Updated date    : 12/03/2025 - Finished
//===========================================================================================
module xor_module #(
  parameter WIDTH = 32
)(
  input  wire [WIDTH-1:0] rs1_i,
  input  wire [WIDTH-1:0] rs2_i,
  output wire [WIDTH-1:0] rd_o
);
//=================INSTANTIATION========================================================================
  genvar i;
//=================LOOP========================================================================
  generate
    for (i = 0; i < WIDTH; i = i + 1 ) begin
      xor Gi (rd_o[i], rs1_i[i], rs2_i[i]);
    end
  endgenerate
endmodule
