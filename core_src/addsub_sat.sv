//===========================================================================================
// Project         : UART & RVV
// Module          : Module Adder Subtractor Saturation for VALU
// File            : addsub_sat.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 12/03/2026
// Updated date    : 12/03/2026
//===========================================================================================
module addsub_sat #(
  parameter WIDTH = 8
)(
  input  wire [WIDTH-1:0] vrs1_i,
	input  wire [WIDTH-1:0] vrs2_i,
	input                   i_sign,		// 1: sign, 0: uns
	input                   vcin_i,   // 0: Cộng, 1: Trừ
	output wire [WIDTH-1:0] vsat_o,
	output                  vcout_o
);
//=================DECLARATION==========================================================================
	wire [WIDTH-1:0] vrd_add, vrd_sub, result;
	wire             vrs1_sign, vrs2_sign, vrd_sign;
	wire             add_ovf, sub_ovf, ovf;
	wire             vcout;
	wire [WIDTH-1:0] MAX_UNS = {WIDTH{1'b1}};                     // VD: 8'hFF (255)
  wire [WIDTH-1:0] MIN_UNS = {WIDTH{1'b0}};                   // VD: 8'h00 (0)
  wire [WIDTH-1:0] MAX_S   = {1'b0, {(WIDTH-1){1'b1}}};       // VD: 8'h7F (+127)
  wire [WIDTH-1:0] MIN_S   = {1'b1, {(WIDTH-1){1'b0}}};       // VD: 8'h80 (-128)
//===========================================================================================
	add_subtract #(.WIDTH(WIDTH)) add_sub (
																					.a_i     (vrs1_i),
																					.b_i     (vrs2_i),
																					.cin_i   (vcin_i),
																					.result_o(result),
																					.cout_o  (vcout)
																				);
	//============SIGN=================
	assign vrs1_sign = vrs1_i[WIDTH-1];
	assign vrs2_sign = vrs2_i[WIDTH-1];
	assign vrd_sign  = result[WIDTH-1];
	//===========OVERFLOW================================================
	// add: same sign but diff sign result
	assign add_ovf = ~(vrs1_sign ^ vrs2_sign) && (vrs1_sign ^ vrd_sign);
	// sub: diff sign but diff sign vrs1
	assign sub_ovf = (vrs1_sign ^ vrs2_sign) && (vrs1_sign ^ vrd_sign);
	// ovf
	assign ovf = vcin_i ? sub_ovf : add_ovf;
	//===========RESULT_ADD=================================================
	assign vrd_add = (~i_sign) ? (																											// khong dau
																	(~vcout) ? result :	MAX_UNS													// binh thuong ~vcout        : 100 + 50 = 150
																																											// co tran so khong dau vcout: 100 + 200 = 300 -> 255
															 ) 
															:																												// co dau
															 (
																	(~ovf) ? result :	((~vrs1_sign) ? MAX_S  : MIN_S) 	// binh thuong ~ovf    : 100 + (-50) = 50
																																											// ovf va A la so duong: 100 + 100 = 200 -> 127
																																											// ovf va A la so am   : -100 + (-100) = -200 -> -127
															 );
	//===========RESULT_SUB================================================
	assign vrd_sub = (~i_sign) ? (																											// khong dau
																	(~vcout) ? result :	MIN_UNS													// binh thuong: 100 - 50 = 50
																																											// co tran so khong dau: 100 - 200 = -100 -> 0
															 ) 
															:																												// co dau
															 (
																	(~ovf) ? result :	((~vrs1_sign) ? MAX_S  : MIN_S) 	// binh thuong ~ovf: 100 - 50 = 50
																																											// ovf va A la so duong: 100 - (-50) = 150 -> 127 
																																											// ovf va A la so am: -100 - 50 = -150 -> -127
															 );		
												 
	//===========RESULT_SAT================================================
	assign vsat_o = (vcin_i) ? vrd_sub : vrd_add;
	assign vcout_o = vcout;
endmodule
