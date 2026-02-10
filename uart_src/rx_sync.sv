/* signal from rx receiving from pc is async signal (bc it can be 0/1 anytime)
we need 2 FF, the 1st catching the rx from pc to make the signal more stable,
the 2nd catching signal ftom 1st FF - which is stable by CLK_FPGA 
then using signal form 2nd FF to use
and using one more FF to check between 2 signal previous and after through FF, if they 
r the same then there is no metastability 
*/
//===========================================================================================================
// Project         : UART Protocol
// Module          : Rx Synchronous
// File            : rx_sync.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 21/12/2025
// Updated date    : 25/01/2025
//=============================================================================================================
module rx_sync (
  input  wire i_clk,
  input  wire ni_rst,
  input  wire i_rx_signal,
  output reg  o_rx_sync,
  output wire o_start_en
);
// Detect metastablity - CDC - Clock Domain Crossing
  reg rx_ff1;
  reg rx_prev;

  always_ff @( posedge i_clk or negedge ni_rst ) begin : first_ff
    if(~ni_rst) begin
        rx_ff1    <= 1'b1;
        o_rx_sync <= 1'b1;
    end else begin
        rx_ff1 <= i_rx_signal;
        o_rx_sync <= rx_ff1;
    end
  end

  always_ff @( posedge i_clk or negedge ni_rst ) begin : rx_ff
    if(~ni_rst) begin
        rx_prev <= 1'b1;
    end else begin
        rx_prev <= o_rx_sync;
    end
  end

  assign o_start_en = ~o_rx_sync && rx_prev;
endmodule