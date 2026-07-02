//===========================================================================================
// Project         : Single Cycle of RISV - V
// Module          : Multiplexer 32 to 1
// File            : mux_32to1.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 9/9/2025
// Updated date    : 6/11/2025 - Finished
//===========================================================================================
module mux_2to1 #(
  parameter WIDTH = 32
)(
    input  wire [WIDTH-1:0] d0_i, d1_i,
    input  wire             sel_i,
    output reg  [WIDTH-1:0] y_o
);

  always_comb begin : result_ouput
    y_o = sel_i ? d1_i : d0_i;
  end
endmodule
