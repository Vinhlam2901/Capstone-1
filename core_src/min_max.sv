//===========================================================================================
// Project         : UART & RVV
// Module          : Module Comparator for VALU
// File            : min_max.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 12/03/2026
// Updated date    : 12/03/2026
//===========================================================================================
module min_max #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] i_vrs1_data,
    input  wire [WIDTH-1:0] i_vrs2_data,
    input  wire             i_cp_un,     // 1 if unsign, 0 if sign
    output wire [WIDTH-1:0] o_max,
    output wire [WIDTH-1:0] o_maxu,
    output wire [WIDTH-1:0] o_min,
    output wire [WIDTH-1:0] o_minu,
    output wire             o_eq
);
//===============================================DECLARATION=========================================
  wire [WIDTH-1:0] vsub_o;
  wire cout, same_sign, diff_sign;
  wire o_cp_equal;
  wire o_cp_less_uns, o_cp_less_s;
  wire o_cp_less1, o_cp_less2, o_cp_less3;
//===============================================CODE================================================
  add_subtract #(.WIDTH(WIDTH)) S1 (.a_i(i_vrs1_data),.b_i(i_vrs2_data),.cin_i(1'b1),.result_o(vsub_o),.cout_o(cout));
  // sign check
  assign  same_sign     = ~(i_vrs1_data[WIDTH-1] ^ i_vrs2_data[WIDTH-1]);  // if same sign : 1
  assign  diff_sign     = i_vrs1_data[WIDTH-1] ^ i_vrs2_data[WIDTH-1];  // if diff sign : 1
  //o_cp_less
  assign  o_cp_less1    = same_sign && vsub_o[WIDTH-1];                  // same sign and have cout
  assign  o_cp_less2    = diff_sign && i_vrs1_data[WIDTH-1];    // diff sign and rs1[WIDTH-1] = 1 (neg)
  assign  o_cp_less3    = (((i_vrs1_data[WIDTH-1] ^ i_vrs2_data[WIDTH-1]) && (i_vrs1_data[WIDTH-1] ^ vsub_o[WIDTH-1])) ^ vsub_o[WIDTH-1]); // ovf
  assign  o_cp_less_s   = o_cp_less1 || o_cp_less2 || o_cp_less3;
  assign  o_cp_less_uns = cout;
  //compare block
  assign o_cp_equal = ~(|vsub_o);
//===============================================RESULT=========================================
  assign o_max   = (o_cp_less_s   && ~i_cp_un) ? i_vrs2_data : i_vrs1_data;
  assign o_maxu  = (o_cp_less_uns &&  i_cp_un) ? i_vrs2_data : i_vrs1_data;
  assign o_min   = (o_cp_less_s   && ~i_cp_un) ? i_vrs1_data : i_vrs2_data;
  assign o_minu  = (o_cp_less_uns &&  i_cp_un) ? i_vrs1_data : i_vrs2_data;
  assign o_eq    = (o_cp_equal               );
endmodule