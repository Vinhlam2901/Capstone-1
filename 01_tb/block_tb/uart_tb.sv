module uart_tb;

  // --- 1. THAM SỐ CẤU HÌNH ---
  parameter IMG_W = 128; 
  parameter IMG_H = 128;

  // --- 2. TÍN HIỆU ---
  wire      tx, rx;
  reg       clk = 0;
  reg       rst_n = 0;
  reg [2:0] addr;
  reg [7:0] wdata;
  reg [7:0] rdata; 
  reg       cs1, i_ior, ni_ior, i_iow, ni_iow;
  // MẢNG BỘ NHỚ
  reg [7:0] memory [0 : (IMG_W * IMG_H) - 1];
  // Các biến hỗ trợ
  reg [7:0] lsr_status;   
  reg [7:0] rx_val;
  integer   file_out;
  integer   i;
  integer   timeout_count;  
  // Khai báo biến đo thời gian (thêm ở phần khai báo đầu module nếu cần)
  time start_write, end_write, end_tx;
  // --- 3. KẾT NỐI DUT ---
  uart_ip u_dut (
    .i_clk (clk),  .ni_rst(rst_n),
    .i_data(wdata),.i_addr(addr),
    .i_cs1 (cs1),  .i_cs2(1'b1),   .ni_cs3(1'b0),
    .i_ior (i_ior),.ni_ior(ni_ior),
    .i_iow (i_iow),.ni_iow(ni_iow),
    .o_data(rdata), 
    .i_rxd (rx),   .o_txd(tx),
    .ni_cts(1'b0)
  );

  // Loopback
  assign rx = (rst_n === 0 || tx === 1'bx) ? 1'b1 : tx;

  // Clock 50MHz
  always #12 clk = ~clk; 

  // --- 4. TASKS ---
  task cpu_write(input [2:0] a, input [7:0] d);
    begin
      @(posedge clk); 
      addr   <= a; 
      wdata  <= d; 
      cs1    <= 1'b1; 
      #5; 
      i_iow  <= 1'b1; 
      ni_iow <= 1'b0; 
      @(posedge clk); 
      i_iow  <= 1'b0; 
      ni_iow <= 1'b1; 
      cs1    <= 1'b0; 
      #1;
    end
  endtask

  task cpu_read(input [2:0] a, output [7:0] d);
    begin
      @(posedge clk); 
      addr   <= a; 
      cs1    <= 1'b1; 
      i_ior  <= 1'b1; 
      ni_ior <= 1'b0; 
      #5; 
      d = rdata; 
      @(posedge clk); 
      i_ior  <= 1'b0; 
      ni_ior <= 1'b1; 
      cs1    <= 1'b0; 
    end
  endtask

  // --- 5. MAIN PROGRAM ---
  initial begin
    // BẬT DUMP SÓNG CHO CADENCE SIMVISION
    $dumpfile("waves.vcd");
    $dumpvars(0, uart_tb); // Dump toàn bộ tín hiệu (All) của module uart_tb và các module con
    // (Nếu bạn mang sang máy khác dùng GTKWave, thì thay bằng 2 lệnh: 
    // $dumpfile("waves.vcd"); $dumpvars(0, uart_tb); )

    // 1. Load ảnh 
    $readmemh("/home/gin/Desktop/capstone_1/01_tb/image_test/dog1.hex", memory);
    
    // 2. Mở file output
    file_out = $fopen("image_out1.hex", "w");
    if (!file_out) begin
        $display("❌ Lỗi: Không tạo được file output!");
        $finish;
    end

    // 3. Reset
    rst_n = 0; #100; rst_n = 1; #100;

    $display("--- [SETUP] CẤU HÌNH UART ---");
    cpu_write(3'b011, 8'h80);   // 3'b011: LCR : bit[7]: DLAB = 1
    cpu_write(3'b000, 8'h1B);   // 3'b000 + DLAB = 1: DLL 
    cpu_write(3'b001, 8'h00);   // 3'b001 + DLAB = 1: DLM
    cpu_write(3'b011, 8'h03);   // 3'b011: LCR: word_len = 11: 8b, 1 stop bit, no parity, dlab = 0
    cpu_write(3'b010, 8'h07);   // 3'b010: FCR: tx_reset, rx_reset, fifo_en
    // cpu_write(3'b100, 8'h03);   // 3'b100: MCR: ready to send, data terminal ready
    #100;

    $display("🚀 Bắt đầu truyền ảnh %0dx%0d...", IMG_W, IMG_H);

    for (i = 0; i < (IMG_W * IMG_H); i = i + 1) begin
        // A. GỬI
        cpu_write(3'b000, memory[i]);                                                        // 3'b000 + DLAB = 0: THR: core write data to THR
        // B. POLLING
        timeout_count = 0;
        do begin
            cpu_read(3'b101, lsr_status);                                                    // 3'b101: read LSR 
            #200; 
            timeout_count = timeout_count + 1;
        // Chờ đến khi Bit 0 (DR) bật lên mức 1
        end while (lsr_status[0] == 1'b0 && timeout_count < 20000);                          // LSR[0]: data_ready
        if (timeout_count >= 20000) begin
            $display("❌ [LỖI] Pixel %0d: Timeout! LSR=%b", i, lsr_status);
            $finish; 
        end
        // --- C. ĐÓNG VAI RISC-V: ĐỌC DỮ LIỆU RA ---
        // Lấy pixel ra khỏi RBR (Offset 0 khi DLAB=0)
        cpu_read(3'b000, rx_val);                                                             // core read data from RBR (aka THR) then put to o_data
        // Log ra màn hình 10 pixel đầu tiên để kiểm tra độ chính xác
        if (i < 10) begin
             $display("DEBUG Pixel %0d: Gốc = %02h  --->  Nhận = %02h", i, memory[i], rx_val);
        end
        // --- D. LƯU KẾT QUẢ VÀO FILE ---
        $fwrite(file_out, "%02h\n", rx_val);
        if (i > 0 && i % 1024 == 0) begin
            $display("   -> %0d / %0d pixels done", i,  (IMG_W * IMG_H));
        end
    end


    // =========================================================================
    // VÒNG LẶP GIAO TIẾP VỚI UART (BURST MODE - CHỨNG MINH FIFO)
    // =========================================================================
    // $display("🚀 Bắt đầu truyền ảnh chế độ BURST (Xả lũ 8 byte/lần)...");

    // for (i = 0; i < (IMG_W * IMG_H); i = i + 8) begin
        
    //     // --- A. CPU XẢ LŨ 8 BYTE VÀO FIFO ---
    //     start_write = $time;
        
    //     for (int k = 0; k < 8; k = k + 1) begin
    //         cpu_write(3'b000, memory[i + k]);
    //     end
        
    //     end_write = $time;

    //     // --- CHỈ IN LOG CHI TIẾT CHO CỤM 8 BYTE ĐẦU TIÊN ---
    //     if (i == 0) begin
    //         $display("\n---------------------------------------------------------");
    //         $display("📊 [PHÂN TÍCH HIỆU SUẤT FIFO - DỰA TRÊN THỜI GIAN MÔ PHỎNG]");
    //         $display("⏱️ [T=%0t ns] CPU bắt đầu ghi 8 byte...", start_write);
    //         $display("⏱️ [T=%0t ns] CPU GHI XONG! Mất đúng %0t ns.", end_write, end_write - start_write);
    //         $display("   -> Lúc này TX FIFO đang 'ngậm' 8 byte. CPU lập tức rảnh tay đi làm việc khác!");
    //     end

    //     // --- B. UART TỪ TỪ TRUYỀN ĐI (CPU CHỜ TRONG TESTBENCH) ---
    //     timeout_count = 0;
    //     do begin
    //         cpu_read(3'b101, lsr_status);
    //         #200; 
    //         timeout_count = timeout_count + 1;
    //     end while (lsr_status[6] == 1'b0 && timeout_count < 200000); // Chờ TEMT = 1

    //     end_tx = $time;

    //     if (i == 0) begin
    //         $display("⏱️ [T=%0t ns] UART truyền xong 8 byte lên cáp! Mất %0t ns.", end_tx, end_tx - end_write);
    //         $display("🔥 KẾT LUẬN: FIFO đã giúp CPU tiết kiệm %0t ns thời gian chờ đợi (Busy-wait)!", end_tx - end_write);
    //         $display("---------------------------------------------------------\n");
    //     end

    //     // --- C. ĐỌC DỮ LIỆU TỪ RX FIFO LƯU VÀO FILE (KHÔNG IN LOG) ---
    //     for (int k = 0; k < 8; k = k + 1) begin
    //         cpu_read(3'b000, rx_val);
    //         $fwrite(file_out, "%02h\n", rx_val);
    //     end
        
    //     // Chỉ in mốc tiến độ cho bớt rác console
    //     if (i > 0 && i % 2048 == 0) begin
    //         $display("   -> %0d / %0d pixels done...", i, (IMG_W * IMG_H));
    //     end
    // end
    $display("✅ THÀNH CÔNG! Đã truyền xong toàn bộ %0d byte ảnh.",  (IMG_W * IMG_H));
    $fclose(file_out);
    $finish;
  end

endmodule