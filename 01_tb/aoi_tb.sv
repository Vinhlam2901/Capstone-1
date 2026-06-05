`timescale 1ns/1ps

module aoi_tb();

  // ===================================================================
  // 1. CẤU HÌNH THÔNG SỐ (PARAMETERS) - BẢNG ĐIỀU KHIỂN TRUNG TÂM
  // ===================================================================
  // --- A. Cấu hình hệ thống ---
  parameter CLK_FREQ   = 50_000_000;  // 50MHz 
  parameter BAUD_RATE  = 3125000;     // Tốc độ cao Fast-forward Baudrate 
  parameter BIT_PERIOD = 1_000_000_000 / BAUD_RATE; // ~320ns per bit 

  // --- B. Cấu hình kích thước ảnh (Tùy chỉnh tại đây) ---
  parameter IMG_WIDTH  = 48;          // Chiều rộng ảnh
  parameter IMG_HEIGHT = 48;          // Chiều cao ảnh
  parameter TOTAL_PIXELS = IMG_WIDTH * IMG_HEIGHT; // Tổng số byte (Ví dụ: 48x48 = 2304)

  // --- C. Cấu hình Vùng nhớ RAM (Đồng bộ với Assembly) ---
  // Bạn phải nhập địa chỉ cơ sở của mảng KẾT QUẢ (x16) trong code ASM vào đây
  // Ví dụ: ASM dùng 'li x16, 0x1200' -> Nhập 32'h1200
  parameter RESULT_BASE_ADDR = 32'h1200; 
  
  // Tự động tính toán Index để Dump RAM (Mỗi ô nhớ mem chứa 8 byte)
  parameter MEM_START_IDX = RESULT_BASE_ADDR / 8;
  parameter MEM_END_IDX   = MEM_START_IDX + (TOTAL_PIXELS / 8) - 1;

  // Tự động tính toán thời gian Timeout an toàn (20,000 ns cho mỗi byte)
  parameter SAFE_TIMEOUT  = TOTAL_PIXELS * 20_000; 

  // ===================================================================
  // 2. KHAI BÁO TÍN HIỆU & BIẾN MÔ PHỎNG
  // ===================================================================
  logic clk;
  logic rst_n;
  logic rx;
  logic tx;
  
  // Mảng đệm tự động co giãn theo TOTAL_PIXELS
  reg [7:0] image_correct [0 : TOTAL_PIXELS-1]; 
  reg [7:0] image_fault   [0 : TOTAL_PIXELS-1]; 
  
  integer out_file_id;
  integer p, k, fd;
  integer rcv_count = 0;
  integer err_count = 0;
  logic [7:0] tx_data;
  logic [7:0] expected_val;

  // =========================================================================
  // 3. GẮN LÕI VI XỬ LÝ (DUT - DESIGN UNDER TEST)
  // =========================================================================
  pipelined_fwd u_soc (
      .i_clk(clk),
      .i_reset(rst_n),   
      .i_uart_rx(rx),    
      .o_uart_tx(tx),    
      .i_io_sw(32'b0),
      .o_pc_debug(),
      .o_insn_vld(),
      .o_io_ledr(), .o_io_ledg(), .o_io_lcd(),
      .o_io_hex0(), .o_io_hex1(), .o_io_hex2(), .o_io_hex3(),
      .o_io_hex4(), .o_io_hex5(), .o_io_hex6(), .o_io_hex7(),
      .o_ctrl(),    .o_mispred()
  );

  // ===================================================================
  // 4. KHỞI TẠO XUNG NHỊP CLOCK VÀ XUẤT SÓNG
  // ===================================================================
  initial begin
    clk = 0;
    forever #10 clk = ~clk; 
  end
  /*
  initial begin
    // Đã chuyển về định dạng chuẩn của VCS (fsdb) thay vì shm (Cadence)
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, aoi_tb);
    $fsdbDumpMDA(); // Dump mảng nhớ để debug Verdi
  end
  */
initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, u_soc.lsu.memory); 
    $dumpvars(0, u_soc.vector_alu); 
  end
  // =========================================================================
  // 5. TASK: MÁY PHÁT UART RX 
  // =========================================================================
  task send_uart_byte(input logic [7:0] data_byte);
    integer i;
    begin
      rx = 1'b0; #(BIT_PERIOD); 
      for (i = 0; i < 8; i = i + 1) begin
        rx = data_byte[i]; #(BIT_PERIOD); 
      end
      rx = 1'b1; #(BIT_PERIOD); 
      #(BIT_PERIOD * 2);        
    end
  endtask

  // ===================================================================
  // 6. KHỐI THEO DÕI UART TX TRẢ VỀ (AUTOMATED SCOREBOARD - NHỊ PHÂN HÓA)
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
      
      // Tự động kiểm tra dữ liệu theo cơ chế Nhị phân hóa lỗi (0x00 hoặc 0xFF)
      if (rcv_count < TOTAL_PIXELS) begin
        // --- CẬP NHẬT LOGIC KỲ VỌNG NHỊ PHÂN HÓA ---
        if (image_correct[rcv_count] == image_fault[rcv_count])
          expected_val = 8'h00; // Giống nhau hoàn toàn -> Kỳ vọng 0x00 (Pass)
        else
          expected_val = 8'hFF; // Có sai lệch -> Kỳ vọng 0xFF (Fail)
          
        // Đối chiếu giá trị thực tế nhận từ TX với giá trị kỳ vọng mới
        if (tx_data !== expected_val) begin
          $display("[%0t ns] [❌ ERROR] Pixel %0d | Kỳ vọng: %02h | Thực tế: %02h (Mạch tính sai bão hòa)", 
                    $time, rcv_count, expected_val, tx_data); 
          err_count++; // Tăng biến đếm lỗi phần cứng
        end else if (expected_val == 8'hFF) begin
          $display("[%0t ns] [🎯 DETECTED] Phát hiện điểm lỗi ảnh tại Pixel %0d! Kết quả bão hòa chuẩn: %02h", 
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
    rx = 1'b1;
    rst_n = 0;
    #100;
    rst_n = 1; 
    
    $readmemh("../01_tb/image_test/dog_correct.hex", image_correct);
    $display("📂 Đã nạp %0d byte file image_correct.hex!", TOTAL_PIXELS);
    $readmemh("../01_tb/image_test/dog_fault.hex", image_fault);
    $display("📂 Đã nạp %0d byte file image_fault.hex!", TOTAL_PIXELS);
    
    #5000; 
    
    $display("\n🚀 [TB] BẮT ĐẦU TRUYỀN %0d BYTE ẢNH A...", TOTAL_PIXELS);
    for (p = 0; p < TOTAL_PIXELS; p = p + 1) begin
      send_uart_byte(image_correct[p]); 
    end
    
    $display("\n🚀 [TB] BẮT ĐẦU TRUYỀN %0d BYTE ẢNH B...", TOTAL_PIXELS);
    for (p = 0; p < TOTAL_PIXELS; p = p + 1) begin
      send_uart_byte(image_fault[p]);
    end
    
    $display("\n✅ [TB] ĐÃ BẮN XONG %0d BYTE ẢNH! Đang đợi CPU xử lý...", TOTAL_PIXELS * 2);

    fork
      wait(rcv_count == TOTAL_PIXELS); 
      #(SAFE_TIMEOUT);  // Tự động scale thời gian chờ theo kích thước ảnh
    join_any 
    disable fork; 
    $fclose(out_file_id);

    // --- ĐỒNG THỜI XUẤT DIRECT DUMP TỪ DRAM ĐỂ ĐỐI CHIẾU ---
    begin : DIRECT_DRAM_DUMP
      fd = $fopen("../01_tb/image_test/result_aoi.hex", "w"); 
      if (fd) begin
        // Vòng lặp tự động dựa vào RESULT_BASE_ADDR và kích thước ảnh
        for (k = MEM_START_IDX; k <= MEM_END_IDX; k = k + 1) begin
          $fdisplay(fd, "%016x", u_soc.lsu.memory.mem[k]); 
        end
        $fclose(fd);
        $display("💾 [DRAM DUMP] Đã kết xuất từ mem[%0d] đến mem[%0d] ra result_aoi.hex", MEM_START_IDX, MEM_END_IDX);
      end
    end

    // --- IN BÁO CÁO --- 
    $display("\n=================================================="); 
    $display(" Tổng số byte kết quả thu về  : %0d / %0d", rcv_count, TOTAL_PIXELS); 
    $display(" Tổng số pixel bị sai lệch    : %0d", err_count); 
    if (rcv_count == TOTAL_PIXELS && err_count == 0)
      $display("*** [ PASS ] ***"); 
    else
      $display("*** [ FAIL ] ***"); 
    $display("==================================================\n");
    
    $finish; 
  end

endmodule
