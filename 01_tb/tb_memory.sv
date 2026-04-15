module tb_memory();

  // 1. Khai báo tín hiệu kết nối với DUT (Device Under Test)
  reg         clk;
  reg         reset;
  reg  [2:0]  func3;
  reg  [15:0] addr;
  reg  [31:0] scalar_wdata;
  reg  [63:0] vector_wdata;
  reg  [7:0]  vlen_en;
  reg  [7:0]  bmask_align;
  reg  [7:0]  bmask_misalign;
  reg         scalar_wren;
  reg         scalar_rden;
  reg         vector_wren;
  reg         vector_rden;
  
  wire [31:0] scalar_rdata;
  wire [63:0] vector_rdata;

  // 2. Gọi (Instantiate) Module Memory
  memory dut (
    .i_clk(clk),
    .i_reset(reset),
    .i_func3(func3),
    .i_addr(addr),
    .i_scalar_wdata(scalar_wdata),
    .i_vector_wdata(vector_wdata),
    .i_vlen_en(vlen_en),
    .i_bmask_align(bmask_align),
    .i_bmask_misalign(bmask_misalign),
    .i_scalar_wren(scalar_wren),
    .i_scalar_rden(scalar_rden),
    .i_vector_wren(vector_wren),
    .i_vector_rden(vector_rden),
    .o_scalar_rdata(scalar_rdata),
    .o_vector_rdata(vector_rdata)
  );

  // 3. Tạo Xung nhịp (Clock Generator) - Chu kỳ 10ns
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // =========================================================================
  // XUẤT FILE SÓNG (WAVEFORM DUMP)
  // =========================================================================
  initial begin
    $dumpfile("tb_memory_wave.vcd");
    $dumpvars(0, tb_memory); // Dump toàn bộ các biến trong testbench này
  end

  // 4. Các Task hỗ trợ (Giúp code TB gọn gàng và log chi tiết hơn)
  task reset_mem();
    begin
      $display("[%0t] [SYS] Bắt đầu quá trình Reset...", $time);
      reset = 0; scalar_wren = 0; scalar_rden = 0; vector_wren = 0; vector_rden = 0;
      #15; 
      reset = 1;
      $display("[%0t] [SYS] >>> RESET HOÀN TẤT <<<", $time);
    end
  endtask

  task write_scalar(input [15:0] a, input [31:0] d, input [2:0] f3, input [7:0] m_align, input [7:0] m_misalign);
    begin
      @(negedge clk);
      $display("[%0t] [SCALAR WRITE] Yêu cầu ghi -> Addr: 0x%0h | Data: 0x%0h | Func3: 3'b%0b | Mask_A: 8'b%0b | Mask_M: 8'b%0b", 
                $time, a, d, f3, m_align, m_misalign);
      scalar_wren = 1; addr = a; scalar_wdata = d; func3 = f3; 
      bmask_align = m_align; bmask_misalign = m_misalign;
      
      @(negedge clk);
      scalar_wren = 0;
      $display("[%0t] [SCALAR WRITE] Hoàn tất ghi", $time);
    end
  endtask

  task read_scalar(input [15:0] a, input [2:0] f3);
    begin
      @(negedge clk);
      $display("[%0t] [SCALAR READ]  Yêu cầu đọc -> Addr: 0x%0h | Func3: 3'b%0b", $time, a, f3);
      scalar_rden = 1; addr = a; func3 = f3;
      
      @(negedge clk);
      scalar_rden = 0;
      // Dữ liệu đọc ra sau khi clock cạnh lên đã chốt vào thanh ghi o_scalar_rdata
      $display("[%0t] [SCALAR READ]  Kết quả nhận được: 0x%0h", $time, scalar_rdata);
    end
  endtask

  // 5. Kịch bản Mô phỏng (Stimulus)
  initial begin
    // Khởi tạo
    reset_mem();

    $display("\n=======================================================");
    $display(" TEST 1: GHI & ĐỌC MẢNG VECTOR (ALIGNED 64-BIT)");
    $display("=======================================================");
    @(negedge clk);
    $display("[%0t] [VECTOR WRITE] Yêu cầu ghi -> Addr: 0x1000 | Data: 0x11223344_55667788 | Vlen: 8'hFF", $time);
    vector_wren = 1; addr = 16'h1000; vector_wdata = 64'h11223344_55667788; vlen_en = 8'hFF;
    
    @(negedge clk);
    vector_wren = 0; vector_rden = 1; addr = 16'h1000;
    $display("[%0t] [VECTOR READ]  Yêu cầu đọc -> Addr: 0x1000", $time);
    
    @(negedge clk);
    vector_rden = 0;
    $display("[%0t] [VECTOR READ]  Kết quả nhận được: 0x%0h", $time, vector_rdata);


    $display("\n=======================================================");
    $display(" TEST 2: GHI & ĐỌC VÔ HƯỚNG NỬA THẤP VÀ NỬA CAO");
    $display("=======================================================");
    // Ghi 0xAAAAAAAA vào địa chỉ 0x0000 (Nửa thấp - Mask: 0000_1111)
    write_scalar(16'h0000, 32'hAAAAAAAA, 3'b010, 8'b0000_1111, 8'b0000_0000);
    
    // Ghi 0xBBBBBBBB vào địa chỉ 0x0004 (Nửa cao - Mask: 1111_0000)
    write_scalar(16'h0004, 32'hBBBBBBBB, 3'b010, 8'b1111_0000, 8'b0000_0000);

    // Đọc lại để kiểm tra
    read_scalar(16'h0000, 3'b010);
    read_scalar(16'h0004, 3'b010);
    
    // Xuyên thấu RAM vật lý
    $display("[%0t] [CHECK RAM] Physical RAM mem[0] : 0x%0h (Nửa cao | Nửa thấp)", $time, dut.mem[0]);


    $display("\n=======================================================");
    $display(" TEST 3: GHI & ĐỌC MISALIGNED (TRÀN 64-BIT)");
    $display("=======================================================");
    // Lệnh này chiếm Byte 6, 7 (của mem[0]) và tràn qua Byte 0, 1 (của mem[1])
    write_scalar(16'h0006, 32'hDEADBEEF, 3'b010, 8'b1100_0000, 8'b0000_0011);

    // Đọc lại lệnh Misaligned tại địa chỉ 0x0006
    read_scalar(16'h0006, 3'b010);

    // Xuyên thấu RAM vật lý
    $display("[%0t] [CHECK RAM] Physical RAM mem[0] : 0x%0h (Chứa BE_EF ở trên cùng)", $time, dut.mem[0]);
    $display("[%0t] [CHECK RAM] Physical RAM mem[1] : 0x%0h (Chứa DE_AD ở dưới cùng)", $time, dut.mem[1]);

    $display("\n[%0t] ================= KẾT THÚC MÔ PHỎNG ===================", $time);
    $finish;
  end

endmodule