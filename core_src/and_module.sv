//===========================================================================================================
// Project         : UART & RVV
// Module          : AND
// File            : and_32bit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 12/12/2025
// Updated date    : 04/03/2026
//============================================================================================================
module and_module #(
  parameter WIDTH = 32
) (
  input       [WIDTH-1:0] rs1_i,
  input       [WIDTH-1:0] rs2_i,
  output wire [WIDTH-1:0] rd_o
);
//=================INSTANTIATION========================================================================
  genvar i;
//=================LOOP========================================================================
  generate
    for (i = 0; i < WIDTH; i = i + 1 ) begin
      and andi (rd_o[i], rs1_i[i], rs2_i[i]);
    end
  endgenerate
endmodule
