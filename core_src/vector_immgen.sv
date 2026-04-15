//===========================================================================================================
// Project         : PIPELINED Model Forwarding of RISV - V
// Module          : Vector Immediate Generator
// File            : vector_immgen.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 1/04/2026
// Updated date    : 01/04/2026
//=============================================================================================================
import package_param::*;
module vector_immgen #(
	parameter SEW = 8
) (
	input  wire [31:0] inst_i,
	output reg  [63:0] vimm_o
);
	always_comb begin
        vimm_o = 64'b0;
        if(inst_i[`OPCODE] == VECTOR) begin
            if(inst_i[`FUNC3] == 3'b011) begin
                vimm_o = {8{ {3{inst_i[19]}}, inst_i[19:15] }};
            end
        end
    end

endmodule