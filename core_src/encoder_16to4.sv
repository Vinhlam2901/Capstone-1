module encoder_16to4 (
    input       [15:0] y_i,
    output wire [3:0]  out_o
);
  assign out_o = (y_i[15]) ? 4'd15 :
                 (y_i[14]) ? 4'd14 :
                 (y_i[13]) ? 4'd13 :
                 (y_i[12]) ? 4'd12 :
                 (y_i[11]) ? 4'd11 :
                 (y_i[10]) ? 4'd10 :
                 (y_i[9])  ? 4'd9  :
                 (y_i[8])  ? 4'd8  :
                 (y_i[7])  ? 4'd7  :
                 (y_i[6])  ? 4'd6  :
                 (y_i[5])  ? 4'd5  :
                 (y_i[4])  ? 4'd4  :
                 (y_i[3])  ? 4'd3  :
                 (y_i[2])  ? 4'd2  :
                 (y_i[1])  ? 4'd1  :
                 (y_i[0])  ? 4'd0  : 4'd0;  // default
endmodule
