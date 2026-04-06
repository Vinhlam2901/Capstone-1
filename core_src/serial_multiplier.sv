module serial_multiplier #(
  parameter WIDTH = 8 // Có thể đổi thành 64, 128 tùy ý
)(
  input  wire                 i_clk,
  input  wire                 i_reset,
  input  wire                 i_start,     // Xung trigger bắt đầu tính toán
  input  wire [WIDTH-1:0]     i_op_a,      // Số nhân (Multiplier)
  input  wire [WIDTH-1:0]     i_op_b,      // Số bị nhân (Multiplicand)
  output reg  [2*WIDTH-1:0]   o_result,    // Kết quả 2*WIDTH bit
  output reg                  o_done       // Cờ báo hiệu tính xong (lên 1 trong 1 chu kỳ)
);
  typedef enum logic {IDLE, BUSY} state_t;
  state_t state;

  reg [WIDTH-1:0]       reg_a;       // Thanh ghi chứa Số nhân (sẽ bị dịch phải dần)
  reg [2*WIDTH-1:0]     reg_b;       // Thanh ghi chứa Số bị nhân (sẽ được dịch trái dần)
  reg [2*WIDTH-1:0]     reg_p;       // Thanh ghi chứa Tổng tích lũy (Accumulator)
  reg [$clog2(WIDTH):0] counter;     // Bộ đếm chu kỳ (Ví dụ WIDTH=32 thì cần đếm từ 32 về 0)
	wire                  sign_a, sign_b, result_sign;
  wire [WIDTH-1:0]      abs_a;
	wire [WIDTH-1:0]      abs_b;
//=============================SIGN=======================================================================================
  assign sign_a      = i_op_a[WIDTH-1];
  assign sign_b      = i_op_b[WIDTH-1];
  assign result_sign = sign_a ^ sign_b; // Dấu của kết quả cuối cùng
  assign abs_a   = (sign_a) ? (~i_op_a + 1) : i_op_a;
  assign abs_b   = (sign_b) ? (~i_op_b + 1) : i_op_b;
//=============================FSM & DATAPATH=======================================================================================
  always_ff @(posedge i_clk) begin
    if (~i_reset) begin
      state    <= IDLE;
      reg_a    <= '0;
      reg_b    <= '0;
      reg_p    <= '0;
      counter  <= '0;
      o_done   <= 1'b0;
      o_result <= '0;
    end else begin
      case (state)
        IDLE: begin
          o_done <= 1'b0;
          if (i_start) begin
            reg_a   <= abs_a;
            reg_b   <= {{WIDTH{1'b0}}, abs_b}; // Mở rộng op_b lên gấp đôi trước khi dịch
            reg_p   <= '0;
            counter <= WIDTH;                  // Đặt bộ đếm bằng số bit (VD: 32)
            state   <= BUSY;
          end
        end
        BUSY: begin
          if (counter > 0) begin
            // 1. Phép CỘNG: Nếu bit lsb (bit 0) của reg_a là 1, thì cộng dồn reg_b vào reg_p
            if (reg_a[0]) reg_p <= reg_p + reg_b; 
            // 2. Phép DỊCH: Luôn luôn dịch mỗi chu kỳ
            reg_a <= reg_a >> 1; // Dịch phải để test bit tiếp theo
            reg_b <= reg_b << 1; // Dịch trái để nhân 2 trọng số
            // 3. Đếm lùi
            counter <= counter - 1'b1;
          end else begin
            o_done <= 1'b1;
            // Áp dụng lại dấu cho kết quả: Nếu âm thì bù 2, nếu dương thì giữ nguyên
            o_result <= result_sign ? (~reg_p + 1'b1) : reg_p;
            state <= IDLE;
          end
        end
      endcase
    end
  end
endmodule