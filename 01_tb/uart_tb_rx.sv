module uart_tb_rx;

  reg clk = 0;
  reg rst_n = 0;
  reg [2:0] addr;
  reg [7:0] wdata;
  wire [7:0] rdata;
  reg cs1, i_ior, ni_ior, i_iow, ni_iow;
  wire tx;
  reg rx_inject; // Dây rx do Testbench tự điều khiển

  // Các biến hỗ trợ
  reg [7:0] rx_val;
  reg [7:0] lsr_status;

  // --- KẾT NỐI DUT ---
  uart_ip u_dut (
    .i_clk(clk), .ni_rst(rst_n),
    .i_data(wdata), .i_addr(addr),
    .i_cs1(cs1), .i_cs2(1'b1), .ni_cs3(1'b0),
    .i_ior(i_ior), .ni_ior(ni_ior),
    .i_iow(i_iow), .ni_iow(ni_iow),
    .o_data(rdata), 
    .i_rxd(rx_inject), .o_txd(tx), // Chú ý: rx nối vào rx_inject
    .ni_cts(1'b0)
  );

  always #10 clk = ~clk; // T_clk = 24ns

  // --- TASK ĐỌC/GHI --- (Giữ nguyên như cũ)
  task cpu_write(input [2:0] a, input [7:0] d); begin
      @(posedge clk); addr <= a; wdata <= d; cs1 <= 1; #1; i_iow <= 1; ni_iow <= 0; 
      @(posedge clk); @(posedge clk); i_iow <= 0; ni_iow <= 1; cs1 <= 0; #1;
  end endtask

  task cpu_read(input [2:0] a, output [7:0] d); begin
      @(posedge clk); addr <= a; cs1 <= 1; i_ior <= 1; ni_ior <= 0; #5; d = rdata; 
      @(posedge clk); i_ior <= 0; ni_ior <= 1; cs1 <= 0; 
  end endtask

  // ==========================================================
  // 😈 TASK BƠM BIT NỐI TIẾP (Giả lập Máy tính gửi dữ liệu)
  // Thời gian 1 bit = Chu_kỳ * 16 * 1 (DLL) = 384ns
  // ==========================================================
  task send_serial_byte(input [7:0] data_to_send);
    integer bit_idx;
    // Thời gian 1 bit = Chu_kỳ * 16 * DLL = 24ns * 16 * 1
    begin
      $display("[%0t] PC: Bắt đầu gửi byte 0x%0h...", $time, data_to_send);
      
      // 1. Gửi START BIT (0)
      rx_inject = 1'b0;
      #320; 

      // 2. Gửi 8 DATA BITS (Từ LSB đến MSB)
      for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
        rx_inject = data_to_send[bit_idx];
        #320; 
      end

      // 3. Gửi STOP BIT (1)
      rx_inject = 1'b1;
      #320; 
      
      // Chờ thêm một chút để DUT kịp cập nhật thanh ghi
      #1000; 
    end
  endtask

  // --- CHƯƠNG TRÌNH CHÍNH ---
  initial begin
    rx_inject = 1'b1; // Trạng thái nghỉ của UART là 1
    rst_n = 0; #100; rst_n = 1; #100;

    // Cấu hình UART DUT
    cpu_write(3'b011, 8'h80); // DLAB=1
    cpu_write(3'b000, 8'h01); // DLL=1
    cpu_write(3'b001, 8'h00); // DLM=0
    cpu_write(3'b011, 8'h03); // 8-bit mode
    cpu_write(3'b010, 8'h07); // Enable FIFO
    #100;

    // --- THỰC HIỆN BÀI TEST TỐI THƯỢNG ---
    // Testbench giả lập dòng điện trên dây rx, KHÔNG đi qua tx của DUT
    send_serial_byte(8'hA5); // Gửi thử 1010_0101

    // Kiểm tra xem DUT có gom các bit nối tiếp đó thành 1 byte hoàn chỉnh không
    cpu_read(3'b101, lsr_status);
    if (lsr_status[0] == 1'b1) begin
        cpu_read(3'b000, rx_val);
        if (rx_val == 8'hA5)
            $display("✅ TEST PASSED: UART RX ĐÃ HOẠT ĐỘNG HOÀN HẢO! Dữ liệu nhận: 0x%0h", rx_val);
        else
            $display("❌ TEST FAILED: Nhận sai dữ liệu. Nhận: 0x%0h", rx_val);
    end else begin
        $display("❌ TEST FAILED: UART RX không phát hiện có dữ liệu đến (LSR[0] = 0).");
    end

    $finish;
  end

endmodule