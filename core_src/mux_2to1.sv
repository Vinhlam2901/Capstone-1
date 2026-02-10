module mux_2to1 (
    input       [31:0] d0_i,
    input       [31:0] d1_i,
    input              s_i,
    output wire [31:0] y_o
); //da hal check va khong co loi

  assign y_o = (s_i) ? d1_i : d0_i;

endmodule
