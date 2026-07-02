module mux32_1_tb;

  // 1. Định nghĩa tham số WIDTH trùng với cấu hình thiết kế (Có thể sửa tùy ý: 8, 16, 32, 64...)
  parameter WIDTH = 32;

  // 2. Khai báo các đường dây kết nối trực tiếp với PORT-LIST của DUT
  wire [WIDTH-1:0] d0,  d1,  d2,  d3,  d4,  d5,  d6,  d7;
  wire [WIDTH-1:0] d8,  d9,  d10, d11, d12, d13, d14, d15;
  wire [WIDTH-1:0] d16, d17, d18, d19, d20, d21, d22, d23;
  wire [WIDTH-1:0] d24, d25, d26, d27, d28, d29, d30, d31;
  reg  [4:0]       s;
  wire [WIDTH-1:0] y_o;

  // Mảng 2 chiều nội bộ trong Testbench để chạy vòng lặp phát dữ liệu tự động
  reg [WIDTH-1:0] tb_data_matrix [0:31];
  int error_count = 0;

  // 3. Sử dụng cấu trúc generate để tự động nối 32 hàng của mảng 2 chiều vào 32 chân rời rạc
  assign d0  = tb_data_matrix[0];  assign d1  = tb_data_matrix[1];
  assign d2  = tb_data_matrix[2];  assign d3  = tb_data_matrix[3];
  assign d4  = tb_data_matrix[4];  assign d5  = tb_data_matrix[5];
  assign d6  = tb_data_matrix[6];  assign d7  = tb_data_matrix[7];
  assign d8  = tb_data_matrix[8];  assign d9  = tb_data_matrix[9];
  assign d10 = tb_data_matrix[10]; assign d11 = tb_data_matrix[11];
  assign d12 = tb_data_matrix[12]; assign d13 = tb_data_matrix[13];
  assign d14 = tb_data_matrix[14]; assign d15 = tb_data_matrix[15];
  assign d16 = tb_data_matrix[16]; assign d17 = tb_data_matrix[17];
  assign d18 = tb_data_matrix[18]; assign d19 = tb_data_matrix[19];
  assign d20 = tb_data_matrix[20]; assign d21 = tb_data_matrix[21];
  assign d22 = tb_data_matrix[22]; assign d23 = tb_data_matrix[23];
  assign d24 = tb_data_matrix[24]; assign d25 = tb_data_matrix[25];
  assign d26 = tb_data_matrix[26]; assign d27 = tb_data_matrix[27];
  assign d28 = tb_data_matrix[28]; assign d29 = tb_data_matrix[29];
  assign d30 = tb_data_matrix[30]; assign d31 = tb_data_matrix[31];

  // 4. Gọi thực thể thiết kế (DUT Instantiation) kèm theo truyền tham số Parameter
  mux_2to1 #(
    .WIDTH(32)
  ) uut (
    .d0(d0),   .d1(d1),   .d2(d2),   .d3(d3),   .d4(d4),   .d5(d5),   .d6(d6),   .d7(d7),
    .d8(d8),   .d9(d9),   .d10(d10), .d11(d11), .d12(d12), .d13(d13), .d14(d14), .d15(d15),
    .d16(d16), .d17(d17), .d18(d18), .d19(d19), .d20(d20), .d21(d21), .d22(d22), .d23(d23),
    .d24(d24), .d25(d25), .d26(d26), .d27(d27), .d28(d28), .d29(d29), .d30(d30), .d31(d31),
    .s(s),
    .y_o(y_o)
  );

  // 5. Khối khởi tạo ghi nhận file sóng mô phỏng
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, mux32_1_tb);
  end

  // 6. Quy trình cấp kích thích (Stimulus) kiểm tra tự động
  initial begin
    $display("[TIME: %0t] --- BẮT ĐẦU TEST MUX 32-1 (BUS WIDTH = %0d) ---", $time, WIDTH);
    
    // Khởi tạo toàn bộ ma trận dữ liệu bằng 0
    for (int i = 0; i < 32; i++) begin
      tb_data_matrix[i] = {WIDTH{1'b0}};
    end
    s = 5'b0;
    #10;

    // =========================================================================
    // KỊCH BẢN 1: Nạp dữ liệu đặc trưng cho từng kênh (Kênh i nhận giá trị = i)
    // =========================================================================
    $display("\n[TIME: %0t] Kịch bản 1: Kiểm tra ánh xạ giá trị định danh từng kênh", $time);
    for (int i = 0; i < 32; i++) begin
      tb_data_matrix[i] = i[WIDTH-1:0]; // Kênh 0 mang giá trị 0, kênh 1 mang giá trị 1...
    end
    #5;

    for (int i = 0; i < 32; i++) begin
      s = i[4:0]; // Chuyển mạch select
      #5;
      
      if (y_o !== i[WIDTH-1:0]) begin
        $display("-> ERROR tại s = %0d: Ngõ ra y_o = %h (Kỳ vọng: %h)", i, y_o, i[WIDTH-1:0]);
        error_count++;
      end
    end

    // =========================================================================
    // KỊCH BẢN 2: Quét nhiễu (Chỉ 1 kênh có dữ liệu cực đại, các kênh khác bằng 0)
    // =========================================================================
    $display("\n[TIME: %0t] Kịch bản 2: Quét nhiễu kênh với dữ liệu cực đại (All 1s)", $time);
    
    for (int i = 0; i < 32; i++) begin
      // Xóa ma trận về 0
      for (int j = 0; j < 32; j++) tb_data_matrix[j] = {WIDTH{1'b0}};
      
      // Chỉ nạp giá trị cực đại (F...F) vào duy nhất kênh i
      tb_data_matrix[i] = {WIDTH{1'b1}}; 
      s = i[4:0];
      #5;

      if (y_o !== {WIDTH{1'b1}}) begin
        $display("-> ERROR tại s = %0d: Dữ liệu cực đại bị suy hao! y_o = %h", i, y_o);
        error_count++;
      end

      // Kiểm tra độ cô lập: Chuyển select đi chỗ khác, ngõ ra phải sụt về 0 ngay
      if (i < 31) begin
        s = (i + 1);
        #5;
        if (y_o !== {WIDTH{1'b0}}) begin
          $display("-> ERROR rò rỉ: Kênh %0d phát nhưng s = %0d lại nhận nhiễu! y_o = %h", i, i+1, y_o);
          error_count++;
        end
      end
    end

    // =========================================================================
    // KỊCH BẢN 3: Kiểm tra dữ liệu ngẫu nhiên đa bit (Random Bus Testing)
    // =========================================================================
    $display("\n[TIME: %0t] Kịch bản 3: Mô phỏng truyền dữ liệu ngẫu nhiên toàn mạch", $time);
    
    repeat(40) begin
      // Bơm dữ liệu ngẫu nhiên hoàn toàn vào cả 32 bus đầu vào
      for (int j = 0; j < 32; j++) begin
        tb_data_matrix[j] = $urandom(); 
      end
      
      s = $urandom_range(0, 31); // Chọn ngẫu nhiên kênh xuất ra
      #5;

      // Check tự động dựa trên tọa độ mảng 2 chiều
      if (y_o !== tb_data_matrix[s]) begin
        $display("-> ERROR Random: Chọn kênh s = %0d | y_o = %h (Kỳ vọng: %h)", 
                 s, y_o, tb_data_matrix[s]);
        error_count++;
      end
    end

    // =========================================================================
    // TỔNG HỢP KẾT QUẢ BÁO CÁO (FINAL REPORT)
    // =========================================================================
    $display("\n==================================================================");
    if (error_count == 0) begin
      $display("  STATUS: SUCCESS - MUX 32-1 VỚI WIDTH = %0d HOẠT ĐỘNG HOÀN HẢO!", WIDTH);
      $display("  Tổng số lỗi logic phát hiện: 0");
    end else begin
      $display("  STATUS: FAILED - PHÁT HIỆN %0d LỖI LOGIC TRONG THIẾT KẾ!", error_count);
    end
    $display("==================================================================");

    $finish;
  end

endmodule