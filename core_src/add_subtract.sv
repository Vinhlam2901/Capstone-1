//===========================================================================================================
// Project         : UART & RVV
// Module          : Adder Subtracter Unit
// File            : add_subtract.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 12/12/2025
// Updated date    : 12/03/2026
//============================================================================================================
module add_subtract #(
  parameter WIDTH = 32
)(
    input  wire [WIDTH-1:0] a_i,
    input  wire [WIDTH-1:0] b_i,
    input                   cin_i,     // 0: Cộng, 1: Trừ
    output wire [WIDTH-1:0] result_o,
    output                  cout_o
);
  wire [WIDTH-2:0] c;
  wire [WIDTH-1:0] b_mod_i;
  wire raw_cout;
  genvar i;
  // Tính b XOR cin cho từng bit
  assign b_mod_i      = b_i ^ {WIDTH{cin_i}}; // nếu b_i là [3:0] và cin_i là 1 bit
  // FA[0]
  generate
    assign result_o[0]  =  a_i[0]  ^ b_mod_i[0]   ^ cin_i;
    assign c[0]         = (a_i[0]  & b_mod_i[0])  | ((a_i[0] ^ b_mod_i[0]) & cin_i);
    for(i = 1; i < WIDTH-1; i = i + 1) begin
      assign result_o[i]  =  a_i[i]  ^ b_mod_i[i]   ^ c[i-1];
      assign c[i]         = (a_i[i]  & b_mod_i[i])  | ((a_i[i] ^ b_mod_i[i]) & c[i-1]);
    end
  endgenerate

  assign result_o[WIDTH-1] = a_i[WIDTH-1] ^ b_mod_i[WIDTH-1]  ^ c[WIDTH-2];
  assign cout_o            = cin_i ? ~((a_i[WIDTH-1] & b_mod_i[WIDTH-1]) | ((a_i[WIDTH-1] ^ b_mod_i[WIDTH-1]) & c[WIDTH-2])) :
                                      (a_i[WIDTH-1] & b_mod_i[WIDTH-1]) | ((a_i[WIDTH-1] ^ b_mod_i[WIDTH-1]) & c[WIDTH-2]);
endmodule
