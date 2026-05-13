module register_nbit #(
  parameter WIDTH = 32
)(
    input  wire        i_clk,
    input  wire        nrst_i,
    input  wire        en_i,
    input  wire [WIDTH-1:0] d_i,
    output reg  [WIDTH-1:0] q_o
); //da hal check va khong co loi

  always @(posedge i_clk) begin
    if (~nrst_i) begin
      q_o <= 0;
    end else if (en_i) begin
      q_o <= d_i;
    end else begin
        q_o <= q_o;
    end
  end
endmodule

