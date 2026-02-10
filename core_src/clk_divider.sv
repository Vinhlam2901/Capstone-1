module clk_divider (
    input  wire i_clk,   // 50 MHz clock input
    input  wire i_reset,
    output reg  o_clk
);// 50 MHz / 250k = 200Hz toggle => 100Hz full period
    reg [31:0] counter;

    always @(posedge i_clk or negedge i_reset) begin
        if (~i_reset) begin
            counter <= 0;
            o_clk   <= 0;
        end else begin
            if (counter >= 125000 - 1) begin
                counter <= 0;
                o_clk   <= ~o_clk;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule
