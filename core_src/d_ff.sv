module d_ff #(
    parameter int DATA_WIDTH = 32
)(
    input  wire                 i_clk,
    input  wire                 i_reset,
    input  wire                 i_enb,
    input  reg [DATA_WIDTH-1:0] i_q,
    output reg [DATA_WIDTH-1:0] o_out
);

  always_ff @( posedge i_clk) begin
    if(~i_reset) begin
        o_out <= 32'b0;
    end else if (i_enb) begin
        o_out <= i_q;
    end
  end

endmodule

// học cách dfng typedef struct
