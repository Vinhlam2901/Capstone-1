module tb();

  // 1. Khai báo tín hiệu
  reg         clk;
  reg         rst;
  reg         uart_rx; // <--- Đổi thành 'reg' để testbench có thể điều khiển được
  wire [31:0] pc_debug;
  wire        insn_vld;

  // 2. Kéo CPU ra bàn mổ
  pipelined_fwd dut (
    .i_clk      (clk),
    .i_reset    (rst),
    .i_uart_rx  (uart_rx), // <--- Nối dây uart_rx vào đây
    .i_io_sw    (32'b0),
    
    .o_pc_debug (pc_debug),
    .o_insn_vld (insn_vld),
    
    .o_io_ledr  (), .o_io_ledg  (), .o_io_lcd   (), .o_uart_tx  (),
    .o_io_hex0  (), .o_io_hex1  (), .o_io_hex2  (), .o_io_hex3  (),
    .o_io_hex4  (), .o_io_hex5  (), .o_io_hex6  (), .o_io_hex7  (),
    .o_ctrl     (), .o_mispred  ()
  );

  // 3. Tạo Clock 50MHz (1 chu kỳ = 20ns)
  always #10 clk = ~clk;

  // =========================================================================
  // 4. TASK: MÁY PHÁT UART (BAUDRATE = 115200)
  // Tính toán: 1 bit mất (1 / 115200) giây = 8680 ns
  // Giao thức: 1 Start bit (0) -> 8 Data bits (LSB first) -> 1 Stop bit (1)
  // =========================================================================
  task uart_send_byte(input [7:0] data);
    integer i;
    begin
      // Gửi Start bit
      uart_rx = 0; 
      #8680;
      
      // Gửi 8 bit dữ liệu (Ưu tiên bit thấp LSB gửi trước)
      for (i = 0; i < 8; i = i + 1) begin
        uart_rx = data[i]; 
        #8680;
      end
      
      // Gửi Stop bit
      uart_rx = 1; 
      #8680;
      
      $display("📡 [%0t ns] [UART TX] Da ban xong 1 Byte: %h", $time, data);
    end
  endtask

 reg [7:0] image_buffer [0:63]; 
  integer p;

  initial begin
    $display("===============================================================================");
    $display("          BAT DAU MO PHONG UART - DOC FILE IMAGE.HEX TRUYEN XUONG CPU          ");
    $display("===============================================================================");
    
    $shm_open("wave.shm");
    $shm_probe(tb, "ASM");
    
    clk = 0;
    rst = 0; 
    uart_rx = 1; 
    
    // NẠP FILE HÌNH ẢNH VÀO MẢNG TESTBENCH
    $readmemh("../01_tb/image_test/dog1.hex", image_buffer);
    $display("📂 Da nap thanh cong file image.hex vao Testbench!");

    #25 rst = 1; 
    #2000; // Chờ CPU khởi động và chạy các lệnh setup

    $display("\n🚀 BAT DAU BAN 64 BYTE ANH QUA UART...\n");

    // VÒNG LẶP BẮN TOÀN BỘ 64 BYTE VÀO CPU
    for (p = 0; p < 256; p = p + 1) begin
        uart_send_byte(image_buffer[p]);
        
        // Thêm một khoảng nghỉ siêu nhỏ giữa các byte để UART bên nhận kịp xả hơi
        #1000; 
    end

    $display("\n✅ DA BAN XONG TOAN BO KHOI ANH! Cho CPU xu ly not...\n");

    // Chờ CPU gom các byte cuối cùng và ghi mẻ cuối xuống DRAM
    #100000;
    $display("===============================================================================");
    $display("  🎉 MO PHONG HOAN TAT! HAY MO WAVEFORM DE KIEM TRA DRAM.");
    $display("===============================================================================\n");
    $finish;
  end
endmodule