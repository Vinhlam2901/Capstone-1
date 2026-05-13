//===========================================================================================================
// Project         : UART & RVV
// Module          : MODULE UART TRANSMITER
// File            : uart_rx.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 25/12/2025
// Updated date    : 31/01/2025
//=============================================================================================================
import package_param::*;
module uart_tx (
  input  wire       i_clk,
  input  wire       ni_rst,
  input  wire       i_s_tick,       // Tick 16x baudrate
  // Kết nối với FIFO
  input  wire       i_fifo_empty,   // FIFO báo: "Tui rỗng rồi"
  input  wire [7:0] i_fifo_data,    // Dữ liệu đầu ra của FIFO
  output reg        o_fifo_rden,   // TX ra lệnh: "Đưa data đây!"
  // Kết nối ra ngoài
  output reg        o_tx_serial,    // Chân TX
  output reg        o_tx_done_tick  // Báo xong 1 byte (để Debug)
);
//========================DECLEARATION===============================================================================
  typedef enum {IDLE, START, DATA, STOP} state_type;
  state_type state, next_state;
//========================INSTANTIAION===============================================================================
  reg [3:0] s_tick_count; // Đếm mẫu (0-15)
  reg [2:0] n_bit_count;  // Đếm số bit (0-7)
  reg [7:0] tx_shift_reg; 
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
// KHỐI 2: NEXT STATE LOGIC (Combinational)
//===========================================================================
  always_comb begin
    next_state = state;
    case (state)
      IDLE: begin
        if(~i_fifo_empty) begin
          next_state = START;
        end
      end
      START: begin
        if(i_s_tick && s_tick_count == 15) begin
          next_state = DATA;
        end 
      end
      DATA: begin
        if (i_s_tick && s_tick_count == 15) begin // Hết 1 chu kỳ bit
          if (n_bit_count == 7) begin // Đủ 8 bit
            next_state = STOP;
          end else begin
            next_state = DATA;
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
  always_ff @( posedge i_clk or negedge ni_rst ) begin : blockName
    if(~ni_rst) begin
      s_tick_count   <= '0;
      n_bit_count    <= '0;
      tx_shift_reg   <= '0;
      o_fifo_rden    <= '0;
      o_tx_done_tick <= '0;
      o_tx_serial    <= 1'b1;
    end else begin
      case (state)
        IDLE: begin
          if (~i_fifo_empty) begin
            o_tx_serial    <= 1'b1;
            s_tick_count   <= 1'b0;
            n_bit_count    <= 1'b0;
            o_tx_done_tick <= 1'b0;
            o_fifo_rden    <= 1'b1;
            tx_shift_reg   <= i_fifo_data;
            // ---------------------------------------------------------
            // 😈 CHỌC PHÁ TẠI ĐÂY: Cố tình lật bit số 7 (MSB) của dữ liệu
            // Thay vì: tx_shift_reg <= i_fifo_data;
            // Bạn viết lại thành:
            // tx_shift_reg   <= { ~i_fifo_data[7], i_fifo_data[6:0] };
            // ---------------------------------------------------------
            
          end
        end
        START: begin
          o_tx_serial <= 1'b0;
          o_fifo_rden <= '0;
          if (i_s_tick) begin
            if(s_tick_count == 15) begin
              s_tick_count <= '0;
            end else begin
              s_tick_count <= s_tick_count + 1;
            end
          end
        end
        DATA: begin
          o_tx_serial <= tx_shift_reg[n_bit_count];
          if(i_s_tick) begin
            if(s_tick_count == 15) begin
              s_tick_count <= '0;
              n_bit_count  <= n_bit_count + 1;
            end else begin
              s_tick_count <= s_tick_count + 1;
            end
          end
        end
        STOP: begin
          o_tx_serial <= 1'b1;
          if (i_s_tick) begin
             if (s_tick_count == 15) begin
               o_tx_done_tick <= 1'b1; // Xong
               // Tự động về IDLE do Khối 2 điều khiển
             end else begin
               s_tick_count <= s_tick_count + 1;
             end
          end  
        end
        default: begin
          s_tick_count   <= '0;
          n_bit_count    <= '0;
          tx_shift_reg   <= '0;
          o_fifo_rden    <= '0;
          o_tx_done_tick <= '0;
          o_tx_serial    <= 1'b1;
        end
      endcase
    end
  end
endmodule