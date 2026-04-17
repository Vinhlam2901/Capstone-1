module serial_multiplier #(
  parameter WIDTH = 8 // Có thể đổi thành 64, 128 tùy ý. Số bit = số chu kỳ thực hiện
)(
  input  wire               i_clk,
  input  wire               i_reset,
  input  wire               i_start,     // Xung trigger bắt đầu tính toán
  input  wire [WIDTH-1:0]   i_op_a,      // Số nhân (Multiplier)
  input  wire [WIDTH-1:0]   i_op_b,      // Số bị nhân (Multiplicand)
  output reg  [2*WIDTH-1:0] o_result,    // Kết quả 2*WIDTH bit
  output reg                o_done       // Cờ báo hiệu tính xong (lên 1 trong 1 chu kỳ)
);
  typedef enum logic {IDLE, BUSY} state_t;
  state_t state;

  reg [WIDTH-1:0]       reg_a;                         // Thanh ghi chứa Số nhân
  reg [WIDTH-1:0]       reg_b;                         // Thanh ghi chứa Số bị nhân
  reg [WIDTH-1:0]       reg_ext;                       // Thanh ghi chứa Tổng tích lũy (Accumulator)
  reg [$clog2(WIDTH):0] counter;                       // Bộ đếm chu kỳ (Ví dụ WIDTH=32 thì cần đếm từ 32 về 0)
	wire                  sign_a, sign_b, result_sign;
  wire [WIDTH-1:0]      abs_a;
	wire [WIDTH-1:0]      abs_b;
  wire [WIDTH:0]        adder_out;
//=============================SIGN=======================================================================================
  assign sign_a      = i_op_a[WIDTH-1];
  assign sign_b      = i_op_b[WIDTH-1];
  assign abs_a       = (sign_a) ? (~i_op_a + 1) : i_op_a;
  assign abs_b       = (sign_b) ? (~i_op_b + 1) : i_op_b;
  assign result_sign = sign_a ^ sign_b;                     // Dấu của kết quả cuối cùng
  //=============================FSM & DATAPATH=======================================================================================
  assign adder_out   = {1'b0, reg_ext} + {1'b0, reg_b};
  always_ff @(posedge i_clk) begin
    if (~i_reset) begin
      state    <= IDLE;
      reg_a    <= '0;
      reg_b    <= '0;
      reg_ext  <= '0;
      counter  <= '0;
      o_done   <= '0;
      o_result <= '0;
    end else begin
      case (state)
        IDLE: begin
          o_done    <= 1'b0;
          if (i_start) begin
            reg_a   <= abs_a;
            reg_b   <= abs_b;
            reg_ext <= '0;
            counter <= WIDTH;                  // Đặt bộ đếm bằng số bit (VD: 32)
            state   <= BUSY;
          end
        end
        BUSY: begin
          if (counter > 0) begin
            // 1. add. if lsb's abs_a == 1 -> add the high byte of reg_ext with reg b -> still using full_adder (WIDTH) bit
            // exp: abs_a = 01 -> reg_ext = 00_01 -> add: reg_ext = 00 + reg_b
            if (reg_a[0]) begin
              reg_ext <= adder_out[WIDTH:1];       // can instance full_adder 
              // 2. shift right 1 bit the reg_ext
              reg_a <= {adder_out[0], reg_a[WIDTH-1:1]};
              // 3. counter back
            end else if (~reg_a[0]) begin
              reg_ext <= {1'b0, reg_ext[WIDTH-1:1]};
              reg_a   <= {reg_ext[0], reg_a[WIDTH-1:1]};
            end

            counter <= counter - 1'b1;
          end else begin
            o_done <= 1'b1;
            // Áp dụng lại dấu cho kết quả: Nếu âm thì bù 2, nếu dương thì giữ nguyên
            o_result <= result_sign ? (~{reg_ext, reg_a} + 1'b1) : {reg_ext, reg_a};
            state <= IDLE;
          end
        end
      endcase
    end
  end
endmodule