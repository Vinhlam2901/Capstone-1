//===========================================================================================================
// Project         : UART & RVV
// Module          : Baudrate Generator (16x Mode)
// Author          : Chau Tran Vinh Lam
// Description     : Tạo ra xung tick với tần số = Baudrate * 16
// Create date     : 25/12/2025
// Updated date    : 18/1/2026
//=============================================================================================================
module baudrate_counter #(
  parameter WIDTH = 16
)(
  input  wire             i_clk,
  input  wire             ni_rst,
  input  wire [WIDTH-1:0] i_divisor, // Giá trị từ {DLM, DLL}
  output reg              o_tick     // Xung mẫu (Sampling tick)
);

  reg [WIDTH-1:0] counter;

  always_ff @(posedge i_clk or negedge ni_rst) begin
    if (!ni_rst) begin
        counter <= '0;
        o_tick  <= 1'b0;
    end else begin
        o_tick <= 1'b0;
        // Chỉ chạy khi divisor khác 0 để tránh treo hoặc lỗi chia
        if (i_divisor) begin
            if (counter >= (i_divisor - 1)) begin
                counter <= 0;
                o_tick  <= 1'b1; // Bật xung 1 chu kỳ clock
            end else begin
                counter <= counter + 1;
            end
        end else begin
            counter <= '0;
        end
    end
  end
endmodule