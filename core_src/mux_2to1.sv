module mux_2to1 #(
  parameter WIDTH = 32
)(
    input       [WIDTH-1:0] d0_i,
    input       [WIDTH-1:0] d1_i,
    input                   s_i,
    output wire [WIDTH-1:0] y_o
); //da hal check va khong co loi

  assign y_o = (s_i) ? d1_i : d0_i;

endmodule
