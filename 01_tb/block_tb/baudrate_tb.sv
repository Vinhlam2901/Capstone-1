module baudrate_tb;

  // -----------------------------------------------------------
  // 1. KHAI BÁO TÍN HIỆU
  // -----------------------------------------------------------
  logic clk;
  logic rst_n;
  logic rx_in;
  
  // Tín hiệu từ rx_sync
  logic rx_sync_out;
  logic start_en;

  // Tín hiệu từ baudrate_counter
  logic [15:0] divisor;
  logic        tick_out;
// -------------INSTANTIATION-----------------------------------------
  rx_sync dut_sync (
    .i_clk(clk),
    .ni_rst(rst_n),
    .i_rx_signal(rx_in),
    .o_rx_sync(rx_sync_out),
    .o_start_en(start_en)
  );

  baudrate_counter #(.WIDTH(16)) dut_baud (
    .i_clk(clk),
    .ni_rst(rst_n),
    .i_divisor(divisor),
    .o_tick(tick_out)
  );
// -------------DECLARATION-----------------------------------------
  logic       fsm_running;
  logic [3:0] tick_count; // Đếm từ 0 đến 15 (16 lát cắt)

// -------------FSM-----------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      fsm_running <= 1'b0;
      tick_count  <= 4'd0;
    end else begin
      // Khi phát hiện cạnh xuống và FSM đang ngủ -> Đánh thức FSM
      if (start_en && !fsm_running) begin
        fsm_running <= 1'b1;
        tick_count  <= 4'd0;
        $display(">>> [%0t] FSM THỨC DẬY: Bat dau dem 16 tick...", $time);
      end 
      // Khi FSM đang chạy và có 1 nhịp tick nảy lên
      else if (fsm_running && tick_out) begin
        // Kiểm tra tại hồng tâm (tick thứ 8, index = 7)
        if (tick_count == 4'd7) begin
          if (rx_in == 1'b1) begin
            $display("    [!] [%0t] FSM KTRA TICK 8: rx_in=1 -> NHIEU GIA! Huy bo.", $time);
            fsm_running <= 1'b0; // Hủy, quay về ngủ
          end else begin
            $display("    [V] [%0t] FSM KTRA TICK 8: rx_in=0 -> START BIT THAT!", $time);
            tick_count <= tick_count + 1;
          end
        end
        // Hoàn tất 1 bit (16 tick)
        else if (tick_count == 4'd15) begin
          $display(">>> [%0t] FSM HOAN TAT 1 BIT. Chuyen sang bit tiep theo.", $time);
          fsm_running <= 1'b0; // Trong TB này chỉ test 1 bit rồi dừng
        end 
        // Đang đếm bình thường
        else begin
          tick_count <= tick_count + 1;
        end
      end
    end
  end

// -------------WAVEFORM-----------------------------------------
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, baudrate_tb);
  end

// -------------CLOCK-----------------------------------------
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // Chu kỳ 10ns.
  end
// -------------TESTCASE-----------------------------------------
  initial begin
    // Khởi tạo
    rst_n   = 0;
    rx_in   = 1;
    // Cho Divisor = 4 để tick_out chớp nhanh (40ns/tick), dễ nhìn trên Waveform
    divisor = 16'd4; 
    #15 rst_n = 1;

  // -------------SHORT GLITCH-----------------------------------------
    #20;
    $display("[%0t] KB1: Nhieu ngan (Glitch) khong trung suon Clock", $time);
    #2;  // 37ns
    rx_in = 0; 
    #2;  // 39ns (Chưa tới sườn 45ns)
    rx_in = 1;
    #60;

  // -------------EDGE GLITCH-----------------------------------------
    $display(" ");
    $display("[%0t] KB2: Nhieu trung ngay suon len (Gay tin gia)", $time);
    // Sườn lên tiếp theo ở 115ns. Ta cho rớt ở 114ns, kéo lên ở 116ns.
    #15; // Lên 114ns
    rx_in = 0;
    #2;  // Qua mốc 115ns
    rx_in = 1;
    // Đợi FSM đếm đến tick 8 (Sẽ mất khoảng 8 * 40ns = 320ns)
    #400;
  // -------------START BIT-----------------------------------------
    $display(" ");
    $display("[%0t] KB3: Start Bit that, keo dai hon 16 tick", $time);
    rx_in = 0; // Giữ nguyên ở mức 0 rất lâu
    #800;      // Đợi quá 16 lần tick (16 * 40ns = 640ns)
    rx_in = 1; // Kết thúc Start bit

    #100;
    $finish;
  end

endmodule