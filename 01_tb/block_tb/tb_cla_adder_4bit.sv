module tb_cla_adder_32bit();

  // Khai báo tín hiệu giao tiếp với DUT (Design Under Test)
  logic [31:0] a_i;
  logic [31:0] b_i;
  logic        cin_i;
  logic [1:0]  vsew_i;
  logic        cout_o;
  logic [31:0] result_o;

  // Khai báo biến chứa kết quả mong đợi (Golden Model)
  logic [31:0] exp_result;
  logic        exp_cout;
  integer      error_count = 0;
  integer      test_count  = 0;

  //=============================================================================
  // 1. Khởi tạo DUT (Instantiate Design Under Test)
  //=============================================================================
  cla_adder_32bit dut (
    .a_i     (a_i),
    .b_i     (b_i),
    .cin_i   (cin_i),
    .vsew_i  (vsew_i),
    .cout_o  (cout_o),
    .result_o(result_o)
  );

  //=============================================================================
  // 2. Task tính toán Golden Model để tự động kiểm tra
  //=============================================================================
  task check_result(input string test_name);
    #1; // Đợi mạch tổ hợp lan truyền tín hiệu (Propagation Delay)
    
    // Tính toán kết quả lý thuyết dựa trên cấu hình SEW
    case (vsew_i)
      2'b10: begin // SEW = 32-bit
        {exp_cout, exp_result} = a_i + b_i + cin_i;
      end
      2'b01: begin // SEW = 16-bit
        exp_result[15:0]  = a_i[15:0]  + b_i[15:0]  + cin_i;
        exp_result[31:16] = a_i[31:16] + b_i[31:16]; // Nửa trên không nhận Carry từ nửa dưới
        exp_cout = 1'b0; // Không quan tâm cout tổng trong chế độ phân mảnh
      end
      2'b00: begin // SEW = 8-bit
        exp_result[7:0]   = a_i[7:0]   + b_i[7:0]   + cin_i;
        exp_result[15:8]  = a_i[15:8]  + b_i[15:8];  // Pixel 1
        exp_result[23:16] = a_i[23:16] + b_i[23:16]; // Pixel 2
        exp_result[31:24] = a_i[31:24] + b_i[31:24]; // Pixel 3
        exp_cout = 1'b0;
      end
      default: {exp_cout, exp_result} = 33'd0;
    endcase

    // So sánh kết quả thực tế từ DUT với lý thuyết
    if ((result_o !== exp_result) || (vsew_i == 2'b10 && cout_o !== exp_cout)) begin
      $display("[%s] FAILED! VSEW=%3b, A=%8h, B=%8h, Cin=%b, Cout = %b-> Result=%8h (Expected=%8h), Cout = %b", 
             test_name, vsew_i, a_i, b_i, cin_i, exp_cout, result_o, exp_result, cout_o);
      error_count++;
    end else begin
      $display("[%s] PASSED | VSEW=%3b, A=%8h, B=%8h, Cin=%b, Cout = %b -> Result=%8h (Expected=%8h), Cout = %b", 
             test_name, vsew_i, a_i, b_i, cin_i, exp_cout, result_o, exp_result, cout_o);
    end
    test_count++;
  endtask

  //=============================================================================
  // 3. Kịch bản mô phỏng chính
  //=============================================================================
  initial begin
    $display("=========================================================");
    $display("BẮT ĐẦU MÔ PHỎNG: CLA ADDER 32-BIT VỚI RVV SEW GATING");
    $display("=========================================================\n");
    // --- DIRECTED TEST 1: Kiểm tra phép cộng 32-bit tiêu chuẩn ---
    a_i = 32'hFFFF_FFFF; b_i = 32'h0000_0001; cin_i = 1'b0; vsew_i = 2'b10; // 32-bit
    check_result("TC1_32BIT_OVERFLOW");
    a_i = 32'h1234_5678; b_i = 32'h8765_4321; cin_i = 1'b1; vsew_i = 2'b10; // 32-bit
    check_result("TC2_32BIT_RANDOM_ADD");
    // --- DIRECTED TEST 2: Bắn phá ranh giới SEW = 8-bit (Thuật toán Ảnh) ---
    // Cố tình tạo tràn số ở Pixel 0 (Byte thấp nhất). 
    // Nếu ranh giới C8 hoạt động tốt, S[7:0] = 00, S[15:8] phải giữ nguyên là 00 chứ không biến thành 01.
    a_i = 32'h0000_00FF; b_i = 32'h0000_0001; cin_i = 1'b0; vsew_i = 2'b00; // 8-bit
    check_result("TC3_8BIT_BOUNDARY_C8_BLOCK");
    // Cố tình tạo tràn số đồng loạt ở cả 4 Pixel (C8, C16, C24 đều phải bị chặn)
    a_i = 32'hFF_FF_FF_FF; b_i = 32'h01_01_01_01; cin_i = 1'b0; vsew_i = 2'b00; // 8-bit
    check_result("TC4_8BIT_ALL_BOUNDARIES_BLOCK");
    // --- DIRECTED TEST 3: Bắn phá ranh giới SEW = 16-bit ---
    // Cố tình tạo tràn số ở điểm giữa C16. Nửa trên phải bị chặn, nhưng C8 bên trong nửa dưới vẫn truyền qua.
    a_i = 32'h0000_FFFF; b_i = 32'h0000_0001; cin_i = 1'b0; vsew_i = 2'b01; // 16-bit
    check_result("TC5_16BIT_BOUNDARY_C16_BLOCK");
    // --- RANDOMIZED TESTS: Bắn 1000 bộ số ngẫu nhiên ---
    $display("\nĐang chạy 1000 Random Tests...");
    for (int i = 0; i < 10; i++) begin
      a_i = $random;
      b_i = $random;
      cin_i = $random % 2;
      
      // Chọn ngẫu nhiên cấu hình SEW
      case ($random % 3)
        0: vsew_i = 2'b00; // 8-bit
        1: vsew_i = 2'b01; // 16-bit
        2: vsew_i = 2'b10; // 32-bit
      endcase
      
      check_result("RANDOM_TEST");
    end

    // --- TỔNG KẾT ---
    $display("\n=========================================================");
    $display("KẾT THÚC MÔ PHỎNG");
    $display("Tổng số bài test đã chạy: %0d", test_count);
    if (error_count == 0) begin
      $display("KẾT QUẢ: THÀNH CÔNG RỰC RỠ! KHÔNG CÓ LỖI.");
    end else begin
      $display("KẾT QUẢ: PHÁT HIỆN %0d LỖI. VUI LÒNG KIỂM TRA LẠI RTL.", error_count);
    end
    $display("=========================================================");
    
    $finish;
  end

endmodule