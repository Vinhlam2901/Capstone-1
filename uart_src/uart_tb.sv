module uart_tb;

  // --- 1. THAM SỐ CẤU HÌNH ---
  parameter IMG_W = 128; // Kích thước mới 128x128
  parameter IMG_H = 128;

  // --- 2. TÍN HIỆU ---
  reg clk = 0;
  reg rst_n = 0;
  reg [2:0] addr;
  reg [7:0] wdata;
  reg [7:0] rdata; // Sửa lại thành wire nếu output từ DUT, nhưng reg cho biến đọc trong TB vẫn ok
  reg cs1, i_ior, ni_ior, i_iow, ni_iow;
  wire tx, rx;
  
  // TỰ ĐỘNG TÍNH TOÁN KÍCH THƯỚC MẢNG
  reg [7:0] memory [0 : (IMG_W * IMG_H) - 1];
  
  // Các biến hỗ trợ mô phỏng
  integer file_out;
  reg [7:0] rx_val;
  integer i;
  reg [7:0] lsr_status;   // Khai báo ở đây
  integer timeout_count;  // Khai báo ở đây

  // --- 3. KẾT NỐI DUT ---
  uart_ip u_dut (
    .i_clk(clk), .ni_rst(rst_n),
    .i_data(wdata), .i_addr(addr),
    .i_cs1(cs1), .i_cs2(1'b1), .ni_cs3(1'b0),
    .i_ior(i_ior), .ni_ior(ni_ior),
    .i_iow(i_iow), .ni_iow(ni_iow),
    .o_data(rdata), // Lưu ý: o_data nên nối vào wire nếu DUT là inout, hoặc reg nếu logic đơn giản
    .i_rxd(rx), .o_rxd(tx),
    .i_dma_rxend(0), .i_dma_txend(0),
    .ni_cts(1'b0), .ni_dsr(1'b0), .ni_ri(1'b1), .ni_dcd(1'b1) // Active Low: 0 là Enable
  );

  // Loopback dây cứng: TX nối thẳng vào RX
  assign rx = (rst_n === 0 || tx === 1'bx) ? 1'b1 : tx;

  // Tạo Clock 50MHz
  always #12 clk = ~clk; 

  // --- 4. TASKS (Timing Robust) ---
  task cpu_write(input [2:0] a, input [7:0] d);
    begin
      @(posedge clk); 
      addr <= a; 
      wdata <= d; 
      cs1 <= 1; 
      #1; 
      i_iow <= 1; ni_iow <= 0; // Enable Write
      @(posedge clk); 
      // Hold
      @(posedge clk); 
      i_iow <= 0; ni_iow <= 1; cs1 <= 0; // Disable
      #1;
    end
  endtask

  task cpu_read(input [2:0] a, output [7:0] d);
    begin
      @(posedge clk); 
      addr <= a; 
      cs1 <= 1; 
      i_ior <= 1; ni_ior <= 0; // Enable Read
      #5; 
      d = rdata; // Lấy mẫu
      @(posedge clk); 
      i_ior <= 0; ni_ior <= 1; cs1 <= 0; // Disable
    end
  endtask

  // --- 5. MAIN PROGRAM ---
  initial begin
    // 1. Load ảnh từ file Hex
    // LƯU Ý: Hãy thay đường dẫn tuyệt đối chính xác của bạn vào đây!
    $readmemh("/home/gin/Desktop/capstone_1/01_tb/image_test/dog.hex", memory);
    $display("--- DEBUG MEMORY LOAD ---");
    $display("Mem[0] (Pixel đầu) = %h", memory[0]);
    $display("Mem[16383] (Pixel cuối) = %h", memory[16383]); // Kiểm tra phần tử cuối cùng của 128x128
    $display("-------------------------");
    // 2. Mở file output
    file_out = $fopen("image_out.hex", "w");
    if (!file_out) begin
        $display("❌ Lỗi: Không tạo được file output!");
        $finish;
    end

    // 3. Reset hệ thống
    rst_n = 0; 
    #100; 
    rst_n = 1; 
    #100;

    $display("--- [SETUP] CẤU HÌNH UART ---");
    // Config UART chuẩn 16550
    cpu_write(3'b011, 8'h80); // LCR: DLAB=1
    cpu_write(3'b000, 8'h01); // DLL: Max Speed
    cpu_write(3'b001, 8'h00); // DLM
    cpu_write(3'b011, 8'h03); // LCR: 8-bit mode
    cpu_write(3'b010, 8'h07); // FCR: Enable & Reset FIFO (QUAN TRỌNG)
    cpu_write(3'b100, 8'h03); // MCR: RTS/DTR Enable
    #100;

    $display("🚀 Bắt đầu truyền ảnh %0dx%0d (%0d bytes)...", IMG_W, IMG_H, IMG_W*IMG_H);

    // --- VÒNG LẶP TRUYỀN NHẬN ---
    for (i = 0; i < (IMG_W * IMG_H); i = i + 1) begin
        
        // A. GỬI (Ghi vào THR)
        cpu_write(3'b000, memory[i]);
        
        // B. POLLING (Chờ cho đến khi có dữ liệu về)
        timeout_count = 0;
        do begin
            // Đọc thanh ghi LSR
            cpu_read(3'b101, lsr_status);
            
            #200; 
            timeout_count = timeout_count + 1;
            
        end while (lsr_status[0] == 1'b0 && timeout_count < 20000); // Tăng timeout lên chút

        // C. KIỂM TRA TIMEOUT
        if (timeout_count >= 20000) begin
            $display("❌ [LỖI] Pixel %0d: Timeout! LSR=%b", i, lsr_status);
            $finish; 
        end

        // D. NHẬN (Chỉ đọc khi chắc chắn LSR[0] == 1)
        cpu_read(3'b000, rx_val);
        if (i < 10) begin
             $display("DEBUG Pixel %0d: Memory Gốc = %h  --->  Nhận về = %h", i, memory[i], rx_val);
        end
        // E. Ghi vào file
        $fwrite(file_out, "%02h\n", rx_val);
        
        // Hiển thị tiến độ (update mỗi 1024 pixel để đỡ lag log)
        if (i % 1024 == 0) $display("   -> %0d / %0d pixels done", i, IMG_W*IMG_H);
    end

    $display("✅ THÀNH CÔNG! Đã truyền xong toàn bộ ảnh.");
    $fclose(file_out);
    $finish;
  end

endmodule