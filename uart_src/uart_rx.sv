//===========================================================================================================
// Project         : UART & RVV
// Module          : UART RX (Explicit FSM Style)
// Author          : Chau Tran Vinh Lam
// Create date     : 21/12/2025
// Updated date    : 31/1/2026
//=============================================================================================================
import package_param::*;
module uart_rx (
  input  wire       i_clk,
  input  wire       ni_rst,
  input  wire       i_rx_signal,    // Tín hiệu từ bên ngoài
  input  wire       i_s_tick,       // Sampling tick (16x Baudrate)
  output reg  [7:0] o_dout,
  output reg        o_rx_done_tick,
  output reg        o_framing_err
);

  // 1. Định nghĩa trạng thái
  typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_type;
  state_type state, next_state;

  reg [3:0] s_tick_count; // Đếm mẫu (0-15)
  reg [2:0] n_bit_count;  // Đếm số bit (0-7)
  reg [7:0] rx_shift_reg; 
  wire      start_detected;
  wire      rx_synced;
//========================INSTANTIAION===============================================================================
  rx_sync rx_sync_module (
    .i_clk      (i_clk),
    .ni_rst     (ni_rst), 
    .i_rx_signal(i_rx_signal),
    .o_rx_sync  (rx_synced),
    .o_start_en (start_detected)
  );
//===========================================================================
// KHỐI 1: STATE REGISTER (Sequential)
//===========================================================================
  always_ff @(posedge i_clk or negedge ni_rst) begin
    if (!ni_rst)
      state <= IDLE;
    else
      state <= next_state;
  end
//===========================================================================
// KHỐI 2: NEXT STATE LOGIC (Combinational) - Tường minh FSM
//===========================================================================
  always_comb begin
    next_state = state; // Mặc định giữ nguyên trạng thái
    case (state)
      IDLE: begin
        if (start_detected) begin // Phát hiện cạnh xuống (Start bit)
          next_state = START;
        end
      end
      START: begin
        if (i_s_tick && s_tick_count == 7) begin  // Giữa bit
           if (~rx_synced) begin                  // Vẫn là 0 -> Hợp lệ
             next_state = DATA;
           end else begin                         // Nhảy lên 1 -> Nhiễu -> Quay về
             next_state = IDLE;
           end
        end
      end
      DATA: begin
        if (i_s_tick && s_tick_count == 15) begin // Hết 1 chu kỳ bit
          if (n_bit_count == 7) begin // Đủ 8 bit
            next_state = STOP;
          end else begin 
            next_state = DATA; // Chưa đủ thì ở lại nhận tiếp
          end
        end
      end
      STOP: begin
        if (i_s_tick && s_tick_count == 15) begin // Hết chu kỳ Stop bit
          next_state = IDLE;
        end
      end
      default: next_state = IDLE;
    endcase
  end
  //===========================================================================
  // KHỐI 3: DATAPATH LOGIC (Sequential)
  //===========================================================================
  always_ff @(posedge i_clk or negedge ni_rst) begin
    if (!ni_rst) begin
      s_tick_count   <= '0;
      n_bit_count    <= '0;
      rx_shift_reg   <= '0;
      o_dout         <= '0;
      o_rx_done_tick <= '0;
      o_framing_err  <= '0;
    end else begin
      // Mặc định xóa cờ done (để tạo xung 1 clock)
      o_rx_done_tick <= 1'b0; 
      case (state)
        IDLE: begin
          // Khi phát hiện sắp chuyển sang START, reset bộ đếm ngay
          if (start_detected) begin
            s_tick_count <= '0;
            n_bit_count  <= '0;
          end
        end
        START: begin
          if (i_s_tick) begin
            // Logic đếm tick nằm ở đây (An toàn, không bị Loop)
            if (s_tick_count == 7) 
               s_tick_count <= '0; // Reset để chuẩn bị vào DATA
            else 
               s_tick_count <= s_tick_count + 1;
          end
        end
        DATA: begin
          if (i_s_tick) begin
            if (s_tick_count == 15) begin
               s_tick_count <= '0;
               rx_shift_reg <= {rx_synced, rx_shift_reg[7:1]};
               n_bit_count  <= n_bit_count + 1;
            end else begin
               s_tick_count <= s_tick_count + 1;
            end
          end
        end
        STOP: begin
          if (i_s_tick) begin
            if (s_tick_count == 15) begin
              // Đã xong trọn vẹn gói tin
              o_dout         <= rx_shift_reg;
              o_rx_done_tick <= 1'b1;
              // Kiểm tra Stop bit
              if (~rx_synced) begin
                o_framing_err <= 1'b1;  
              end else begin
                o_framing_err <= 1'b0;
              end
            end else begin
               s_tick_count <= s_tick_count + 1;
            end
          end
        end
      endcase
    end
  end
endmodule