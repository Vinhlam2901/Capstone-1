`timescale 1ns/1ps

module aoi_tb();

  // ===================================================================
  // 1. CẤU HÌNH THÔNG SỐ (PARAMETERS) - Theo chuẩn rvv_addsat
  // ===================================================================
  parameter CLK_FREQ   = 50_000_000;  // 50MHz 
  parameter BAUD_RATE  = 3125000;     // Tốc độ cao Fast-forward Baudrate 
  parameter BIT_PERIOD = 1_000_000_000 / BAUD_RATE; // ~320ns per bit 

  // ===================================================================
  // 2. KHAI BÁO TÍN HIỆU & BIẾN MÔ PHỎNG
  // ===================================================================
  logic clk;
  logic rst_n;
  logic rx;
  logic tx;
  // Mảng đệm lưu ảnh trong Testbench
  reg [7:0] image_correct [0:63]; 
  reg [7:0] image_fault [0:63]; 
  // Các biến đếm điều khiển Scoreboard & File I/O
  integer out_file_id;
  integer p, k, fd;
  integer rcv_count = 0;
  integer err_count = 0;
  integer total_test_bytes = 64; // Kích thước ảnh kết quả cần thu về 
  logic [7:0] tx_data;
  logic [7:0] expected_val;
  // =========================================================================
  // 3. GẮN LÕI VI XỬ LÝ (DUT - DESIGN UNDER TEST)
  // =========================================================================
  pipelined_fwd u_soc (
      .i_clk(clk),
      .i_reset(rst_n),   // Đồng bộ dùng chân rst_n 
      .i_uart_rx(rx),    // Đồng bộ chân rx 
      .o_uart_tx(tx),    // Đón dây tx để theo dõi 
      .i_io_sw(32'b0),
      .o_pc_debug(),
      .o_insn_vld(),
      .o_io_ledr(), .o_io_ledg(), .o_io_lcd(),
      .o_io_hex0(), .o_io_hex1(), .o_io_hex2(), .o_io_hex3(),
      .o_io_hex4(), .o_io_hex5(), .o_io_hex6(), .o_io_hex7(),
      .o_ctrl(),    .o_mispred()
  );
  // ===================================================================
  // 4. KHỞI TẠO XUNG NHỊP CLOCK (50MHz - Chu kỳ 20ns)
  // ===================================================================
  initial begin
    clk = 0;
    forever #10 clk = ~clk; // Dọn dẹp lỗi nhân đôi clock cũ 
  end
  initial begin
    $shm_open("wave.vcd");
    $shm_probe(aoi_tb, "ASM");
  end
  // =========================================================================
  // 5. TASK: MÁY PHÁT UART RX (Truyền tốc độ cao theo BIT_PERIOD)
  // =========================================================================
  task send_uart_byte(input logic [7:0] data_byte);
    integer i;
    begin
      rx = 1'b0; #(BIT_PERIOD); // Start bit 184]
      for (i = 0; i < 8; i = i + 1) begin
        rx = data_byte[i]; #(BIT_PERIOD); // 8 Data bits (LSB first) 185]
      end
      rx = 1'b1; #(BIT_PERIOD); // Stop bit 186]
      #(BIT_PERIOD * 2);        // Khoảng nghỉ an toàn giữa các byte 
    end
  endtask
  // ===================================================================
  // 6. KHỐI THEO DÕI UART TX TRẢ VỀ (AUTOMATED SCOREBOARD)
  // ===================================================================
  initial begin
    out_file_id = $fopen("../01_tb/image_test/output_dog_aoi.hex", "w");
    forever begin
      @(negedge tx); // Phát hiện Start bit từ chip truyền ra 
      #(BIT_PERIOD / 2); #(BIT_PERIOD); // Lấy mẫu tại trung điểm của bit 
      for (int i = 0; i < 8; i++) begin
        tx_data[i] = tx; // Thu thập 8 bit dữ liệu 
        #(BIT_PERIOD);
      end
      // Ghi byte nhận được vào file báo cáo kết quả 
      $fwrite(out_file_id, "%02x\n", tx_data);
      // Tự động kiểm tra dữ liệu bằng thuật toán Trị tuyệt đối: |Ảnh A - Ảnh B|
      if (rcv_count < total_test_bytes) begin
        if (image_correct[rcv_count] >= image_fault[rcv_count])
          expected_val = image_correct[rcv_count] - image_fault[rcv_count];
        else
          expected_val = image_fault[rcv_count] - image_correct[rcv_count]; 
        // Đối chiếu giá trị thực tế nhận từ TX với giá trị kỳ vọng của Scoreboard 192]
        if (tx_data !== expected_val) begin
          $display("[%0t ns] [❌ ERROR] Pixel %0d | Kỳ vọng: %02h | Thực tế: %02h", 
                    $time, rcv_count, expected_val, tx_data); 
          err_count++; // Tăng biến đếm lỗi 
        end else if (expected_val != 8'h00) begin
          $display("[%0t ns] [🎯 DETECTED] Tìm thấy điểm sai lệch tại Pixel %0d! Sai số: %02h", 
                    $time, rcv_count, tx_data);
        end
      end
      rcv_count++; // Tăng số lượng byte đã nhận thành công 
    end
  end
  // =========================================================================
  // 7. KỊCH BẢN ĐIỀU KHIỂN CHÍNH (MAIN TEST FLOW)
  // =========================================================================
  initial begin
    // Khởi tạo trạng thái đường truyền và Reset cứng 
    rx = 1'b1;
    rst_n = 0;
    #100;
    rst_n = 1; // Nhả reset 
    // Nạp dữ liệu ảnh từ ổ cứng vào bộ nhớ tạm 
    $readmemh("../01_tb/image_test/dog_correct.hex", image_correct);
    $display("📂 Đã nạp thành công file image_correct.hex vao Testbench!");
    $readmemh("../01_tb/image_test/dog_fault.hex", image_fault);
    $display("📂 Đã nạp thành công file image_fault.hex vao Testbench!");
    #5000; // Chờ lõi CPU thực thi xong toàn bộ mã cấu hình thanh ghi UART
    $display("\n🚀 [TB] BẮT ĐẦU TRUYỀN 64 BYTE ẢNH A (CORRECT)...");
    for (p = 0; p < 64; p = p + 1) begin
      send_uart_byte(image_correct[p]); 
    end
    $display("\n🚀 [TB] BẮT ĐẦU TRUYỀN 64 BYTE ẢNH B (FAULT)...");
    for (p = 0; p < 64; p = p + 1) begin
      send_uart_byte(image_fault[p]);
    end
    $display("\n✅ [TB] ĐÃ BẮN XONG 128 BYTE ẢNH! Đang đợi bộ xử lý phản hồi qua cổng TX...");

    // --- CƠ CHẾ TIMEOUT KHÉP KÍN (FORK JOIN) --- 
    fork
      wait(rcv_count == total_test_bytes); // Điều kiện dừng lý tưởng: Nhận đủ 64 byte kết quả 
      #3500000;                            // Bộ định thời an toàn (Timeout) phòng khi kẹt vòng lặp 
    join_any 
    disable fork; // Đóng luồng chờ 
    $fclose(out_file_id);

    // --- ĐỒNG THỜI XUẤT DIRECT DUMP TỪ DRAM ĐỂ ĐỐI CHIẾU SONG SONG ---
    begin : DIRECT_DRAM_DUMP
      fd = $fopen("../01_tb/image_test/result_aoi.hex", "w"); 
      if (fd) begin
        // Sửa lại phân cấp chính xác theo tên u_soc. Địa chỉ kết quả 0x80 nằm từ index 16 -> 23
        for (k = 16; k < 24; k = k + 1) begin
          $fdisplay(fd, "%016x", u_soc.lsu.memory.mem[k]); 
        end
        $fclose(fd);
        $display("💾 [DRAM DUMP] Đã kết xuất thêm file cấu trúc bộ nhớ nội bộ: result_aoi.hex");
      end
    end

    // --- IN BÁO CÁO KẾT QUẢ TỔNG HỢP --- 
    $display("\n=================================================="); 
    $display(" Tổng số byte kết quả thu về từ TX : %0d / %0d", rcv_count, total_test_bytes); 
    $display(" Tổng số pixel bị sai lệch thực tế : %0d", err_count); 
    if (rcv_count == total_test_bytes && err_count == 0)
      $display("*** [ PASS ] ***"); 
    else
      $display("*** [ FAIL ] ***"); 
    $display("==================================================\n");
    
    $finish; 
  end

endmodule