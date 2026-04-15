module vrf_tb();

    // ==========================================
    // KHAI BÁO TÍN HIỆU
    // ==========================================
    parameter SEW = 8;
    parameter VLEN = 64;

    logic             clk;
    logic             rst_n;
    
    logic             vrd_wren;
    logic             vector_enb; // <-- THÊM DÂY NÀY
    logic  [31:0]     vlen_set;
    logic  [ 7:0]     vlen_enb;     // THÊM DÂY NÀY ĐỂ TRUYỀN MẶT NẠ VÀO DUT
    logic  [4:0]      vrs1_addr;
    logic  [4:0]      vrs2_addr;
    logic  [4:0]      vrd_addr;
    logic  [VLEN-1:0] vrd_data;

    logic  [VLEN-1:0] vrs1_data_out;
    logic  [VLEN-1:0] vrs2_data_out;

    // Biến đếm thống kê
    int pass_count = 0;
    int fail_count = 0;

    // ==========================================
    // BỘ GIẢI MÃ: vlen_set (Integer) -> vlen_enb (Mask)
    // ==========================================
    always_comb begin
        case (vlen_set)
            32'd0:   vlen_enb = 8'b0000_0000;
            32'd1:   vlen_enb = 8'b0000_0001;
            32'd2:   vlen_enb = 8'b0000_0011;
            32'd3:   vlen_enb = 8'b0000_0111;
            32'd4:   vlen_enb = 8'b0000_1111;
            32'd5:   vlen_enb = 8'b0001_1111;
            32'd6:   vlen_enb = 8'b0011_1111;
            32'd7:   vlen_enb = 8'b0111_1111;
            32'd8:   vlen_enb = 8'b1111_1111; // MAXVL
            default: vlen_enb = 8'b0000_0000;
        endcase
    end

    // ==========================================
    // KHỞI TẠO DUT (Device Under Test)
    // ==========================================
    vector_regfile #(
        .SEW(SEW),
        .VLEN(VLEN)
    ) dut (
        .i_clk       (clk),
        .ni_rst      (rst_n),
        .i_vrd_wren  (vrd_wren),
        .vlen_enb    (vlen_enb),     // Nối mặt nạ đã giải mã vào đây!
        .i_vrs1_addr (vrs1_addr),
        .i_vrs2_addr (vrs2_addr),
        .vector_enb  (vector_enb),   // <-- NỐI VÀO DUT
        .i_vrd_addr  (vrd_addr),
        .i_vrd_data  (vrd_data),
        .o_vrs1_data (vrs1_data_out),
        .o_vrs2_data (vrs2_data_out)
    );

    // ==========================================
    // TẠO XUNG CLOCK (Chu kỳ 10ns)
    // ==========================================
    initial clk = 0;
    always #5 clk = ~clk;

    // ==========================================
    // TASK: KIỂM TRA VÀ IN LOG CHI TIẾT
    // ==========================================
    task check_result(input string test_name, input [63:0] expected, input [63:0] actual);
        if (expected === actual) begin
            $display("[PASS] %s", test_name);
            $display("       -> Data matched: %h", actual);
            pass_count++; 
        end else begin
            $display("[FAIL] %s", test_name);
            $display("       -> EXPECTED: %h", expected);
            $display("       -> ACTUAL  : %h", actual);
            fail_count++; 
        end
    endtask

    // ==========================================
    // KỊCH BẢN TEST (STIMULUS)
    // ==========================================
    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, vrf_tb);
        $display("==================================================");
        $display("   BẮT ĐẦU MÔ PHỎNG VECTOR REGISTER FILE (VRF)    ");
        $display("==================================================");

        // 0. RESET HỆ THỐNG
        rst_n = 0;
        vrd_wren = 0;
        vlen_set = 32'd0;
        vrs1_addr = 0; vrs2_addr = 0; vrd_addr = 0; vrd_data = 0;
        vector_enb = 1; // <-- BẬT LÊN ĐỂ CHO PHÉP GHI TRONG LÚC TEST
        #15; 
        rst_n = 1;
        #10;

        // ---------------------------------------------------------
        // Testcase 1: Basic Write/Read (v1) với MAXVL (8 Lane)
        // ---------------------------------------------------------
        $display("\n--- Testcase 1: Basic Write/Read (v1, VL=8) ---");
        @(negedge clk);
        vrd_wren = 1;
        vrd_addr = 5'd1;
        vlen_set = 32'd8; 
        vrd_data = 64'h1111_2222_3333_4444;
        
        @(negedge clk); 
        vrd_wren = 0;
        vrs1_addr = 5'd1; 
        
        @(posedge clk); 
        #1;             
        check_result("TC1_Read_v1", 64'h1111_2222_3333_4444, vrs1_data_out);

        // ---------------------------------------------------------
        // Testcase 2: Ghi vào thanh ghi Mặt nạ v0 (v0 != 0)
        // ---------------------------------------------------------
        $display("\n--- Testcase 2: Write to v0 Mask Register ---");
        @(negedge clk);
        vrd_wren = 1;
        vrd_addr = 5'd0;
        vlen_set = 32'd8;
        vrd_data = 64'hAAAA_BBBB_CCCC_DDDD;
        
        @(negedge clk);
        vrd_wren = 0;
        vrs2_addr = 5'd0; 
        
        @(posedge clk); 
        #1;
        check_result("TC2_Read_v0", 64'hAAAA_BBBB_CCCC_DDDD, vrs2_data_out);

        // ---------------------------------------------------------
        // Testcase 3: Write Masking với VL = 3 (Giữ đuôi - Tail Undisturbed)
        // ---------------------------------------------------------
        $display("\n--- Testcase 3: Write Masking (v2, VL=3) ---");
        @(negedge clk);
        vrd_wren = 1;
        vrd_addr = 5'd2;
        vlen_set = 32'd8;
        vrd_data = 64'hFFFF_FFFF_FFFF_FFFF;
        
        @(negedge clk);
        vrd_wren = 1;
        vrd_addr = 5'd2;
        vlen_set = 32'd3; 
        vrd_data = 64'hEEEE_EEEE_EEEE_EEEE;
        
        @(negedge clk);
        vrd_wren = 0;
        vrs1_addr = 5'd2;

        @(posedge clk); 
        #1;
        check_result("TC3_Masked_v2", 64'hFFFF_FFFFFFEEEEEE, vrs1_data_out);

        // ---------------------------------------------------------
        // Testcase 4: Data Forwarding (RAW Hazard) kết hợp Masking
        // ---------------------------------------------------------
        $display("\n--- Testcase 4: RAW Forwarding (v3, VL=2) ---");
        @(negedge clk);
        vrd_wren = 1;
        vrd_addr = 5'd3;
        vlen_set = 32'd8;
        vrd_data = 64'h0000_0000_0000_0000;
        
        @(negedge clk);
        vrd_wren = 1;
        vrd_addr = 5'd3;         
        vlen_set = 32'd2;         
        vrd_data = 64'h9999_9999_9999_9999;
        
        vrs1_addr = 5'd3;        
        #1; 
        check_result("TC4_Forward_v3", 64'h0000_0000_0000_9999, vrs1_data_out);

        // ==========================================
        // TỔNG KẾT MÔ PHỎNG (SUMMARY REPORT)
        // ==========================================
        $display("\n==================================================");
        $display("                 SUMMARY REPORT                   ");
        $display("==================================================");
        $display("  Total Tests Run : %0d", pass_count + fail_count);
        $display("  Passed          : %0d", pass_count);
        $display("  Failed          : %0d", fail_count);
        $display("==================================================");
        
        if (fail_count == 0) begin
            $display("   TẤT CẢ TESTCASES PASS 100%%! VREG HOÀN HẢO!    ");
        end else begin
            $display("   PHÁT HIỆN LỖI! HÃY MỞ WAVEFORM ĐỂ DEBUG.       ");
        end
        $display("==================================================\n");

        #20 $finish;
    end

endmodule