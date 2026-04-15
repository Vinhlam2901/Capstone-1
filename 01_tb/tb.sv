module tb();

  // 1. Khai báo tín hiệu
  reg         clk;
  reg         rst;
  wire [31:0] pc_debug;
  wire        insn_vld;

  // 2. Kéo CPU ra bàn mổ
  pipelined_fwd dut (
    .i_clk      (clk),
    .i_reset    (rst),
    .i_uart_rx  (1'b1),
    .i_io_sw    (32'b0),
    
    .o_pc_debug (pc_debug),
    .o_insn_vld (insn_vld),
    
    .o_io_ledr  (), .o_io_ledg  (), .o_io_lcd   (), .o_uart_tx  (),
    .o_io_hex0  (), .o_io_hex1  (), .o_io_hex2  (), .o_io_hex3  (),
    .o_io_hex4  (), .o_io_hex5  (), .o_io_hex6  (), .o_io_hex7  (),
    .o_ctrl     (), .o_mispred  ()
  );

  // 3. Tạo Clock 50MHz
  always #10 clk = ~clk;

  // 4. Kịch bản chạy
  initial begin
    $display("===============================================================================");
    $display("                BAT DAU MO PHONG CPU - TINH DAY FIBONACCI                      ");
    $display("===============================================================================");
    
    $shm_open("wave.shm");
    $shm_probe(tb, "ASM");
    
    clk = 0;
    rst = 0; 
    #25 rst = 1; 
    
    // Đặt thời gian tối đa là 15000ns (Tránh bị treo máy nếu code bạn bị lặp vô hạn)
    #15000;
    $display("TIMEOUT: Mô phỏng chạy quá thời gian 15000ns!");
    $finish;
  end

// Khai báo cờ lưu kết quả (đặt ở đầu file tb.sv cùng với các biến reg/wire khác)
  logic test_pass = 0; 

  // 5. MÁY THEO DÕI THÔNG MINH CÓ PASS/FAIL CHEKER
  always @(posedge clk) begin
    
    // --- 1. THEO DÕI TÍNH TOÁN VECTOR ALU ---
    if (dut.ex_mem_reg.vector_wren && !dut.ex_mem_reg.memv_rden) begin
       $display("✨ [%0t ns] [VECTOR ALU] Tinh toan xong! Dich: v%0d | Ket qua: %h", 
                $time, dut.ex_mem_reg.inst[11:7], dut.ex_mem_reg.valu_result);
    end

    // --- 2. THEO DÕI LỆNH GHI RAM (VECTOR STORE) ---
    if (dut.ex_mem_reg.memv_wren) begin
       $display("\n💾 [%0t ns] [VECTOR STORE] GHI DU LIEU XUONG RAM", $time);
       $display("    -> Dia chi RAM: %h", dut.ex_mem_reg.alu_result); // Con trỏ địa chỉ
       $display("    -> Trang thai : Dang day du lieu 64-bit xuong Memory...");
    end

    // --- 3. THEO DÕI LỆNH ĐỌC RAM & KIỂM TRA TỰ ĐỘNG ---
    if (dut.mem_wb_reg.vector_wren && dut.mem_wb_reg.vector_wb) begin
       $display("\n📥 [%0t ns] [VECTOR LOAD] DOC DU LIEU TU RAM", $time);
       $display("    -> Dich: v%0d", dut.mem_wb_reg.inst[11:7]);
       $display("    -> Du lieu RAM tra ve (64-bit): %h", dut.wb_vdata_o); 

       // === BỘ CHECKER TỰ ĐỘNG ===
       // Kiểm tra xem lệnh load này có phải đang ghi vào v2 không
       if (dut.mem_wb_reg.inst[11:7] == 5'd2) begin
          // So sánh với dữ liệu gốc đã ghi (15 = 0x0F)
          if (dut.wb_vdata_o == 64'h0F0F0F0F0F0F0F0F) begin
              test_pass = 1;
              $display("    -> [CHECKER] TRUNG KHOP DU LIEU! ✅\n");
          end else begin
              test_pass = 0;
              $display("    -> [CHECKER] SAI DU LIEU! Ky vong: 0f0f0f0f0f0f0f0f ❌\n");
          end
       end
    end

    // --- 4. TỔNG KẾT PASS/FAIL VÀ DỪNG MÔ PHỎNG ---
    if (insn_vld) begin
       if (dut.mem_wb_reg.inst == 32'h0000006F) begin
          $display("\n===============================================================================");
          if (test_pass) begin
              $display("  🎉 [PASSED] TEST LOAD/STORE VECTOR HOAN HAO!");
              $display("              CPU cua ban da ghi va doc thanh cong 64-bit tu RAM.");
          end else begin
              $display("  💀 [FAILED] DATA MISMATCH!");
              $display("              Du lieu doc tu RAM khong khop voi du lieu da ghi.");
          end
          $display("===============================================================================\n");
          $finish; 
       end
    end
    
  end

endmodule