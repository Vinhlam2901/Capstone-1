module vrf_tb;

  // 1. Tín hiệu kết nối với VRF
  logic        clk;
  logic        rst_n;
  logic        vrd_wren;
  logic [4:0]  vrd_addr;
  logic [63:0] vrd_data;
  logic [7:0]  vlen_enb;
  
  logic [4:0]  vrs1_addr;
  logic [63:0] vrs1_data_out;

  // Giả lập con trỏ lệnh (PC) và Bộ nhớ lệnh (Instruction Memory)
  logic [31:0] instruction;
  logic [63:0] mem_data_bus; // Bus dữ liệu từ bộ nhớ chính
  logic [7:0]  v0_register;  // Giả lập thanh ghi v0 chứa mặt nạ (Mask)
// Khai báo Instruction Memory (Chứa tối đa 64 lệnh 32-bit)
  logic [31:0] imem [0:63]; 
  
  // Program Counter (Bộ đếm chương trình)
  logic [31:0] pc;
  // 2. KHỞI TẠO VRF (Thay tên module bằng module thật của ông)
  vector_regfile dut (
      .i_clk(clk),
      .ni_rst(rst_n),
      .i_vrd_wren(vrd_wren),
      .i_vrd_addr(vrd_addr),
      .i_vrd_data(vrd_data),
      .vlen_enb(vlen_enb),
      .i_vrs1_addr(vrs1_addr),
      .o_vrs1_data(vrs1_data_out)
      // Thêm vrs2 nếu cần
  );
    
	initial begin
    // Nạp file HEX vào mảng imem
    $readmemh("../01_tb/code.hex", imem);
    
    // Khởi tạo PC
    pc = 0;
  end
	// Mô phỏng Fetch (Lấy lệnh) mỗi chu kỳ Clock
  always_ff @(posedge clk) begin
    if (rst_n) begin
      // instruction sẽ tự động thay đổi mỗi sườn lên của clock
      // pc >> 2 là vì 1 lệnh dài 4 byte, trong khi mảng imem lùi từng index 1
      instruction <= imem[pc >> 2]; 
      
      // Tăng PC lên 4 byte
      pc <= pc + 4;
    end
  end
  // -------------------------------------------------------------------
  // 3. MOCK INSTRUCTION DECODER (Bộ giải mã lệnh phần cứng)
  // Biến phần mềm (HEX) thành tín hiệu điều khiển phần cứng
  // -------------------------------------------------------------------
  always_comb begin
    // Mặc định không ghi
    vrd_wren = 1'b0;
    vrd_addr = 5'd0;
    vlen_enb = 8'h00;
    
    // Kiểm tra Opcode: 7'h07 (0000111) là lệnh Vector Load
    if (instruction[6:0] == 7'h07) begin
      vrd_wren = 1'b1;                  // Bật cờ ghi
      vrd_addr = instruction[11:7];     // Trích xuất 5-bit vd (Đích đến)
      
      // Trích xuất bit [25] vm (Vector Mask)
      if (instruction[25] == 1'b1) begin
        vlen_enb = 8'hFF;               // vm=1 -> Unmasked (Ghi toàn bộ)
      end else begin
        vlen_enb = v0_register;         // vm=0 -> Masked (Lấy mask từ v0)
      end
    end
  end

  // Dữ liệu từ Memory luôn nối thẳng vào VRF ngõ vào
  assign vrd_data = mem_data_bus;

  // -------------------------------------------------------------------
  // 4. MÔ PHỎNG XUNG CLOCK & DUMP FILE
  // -------------------------------------------------------------------
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, vrf_tb);
  end

  // -------------------------------------------------------------------
  // 5. KỊCH BẢN CHẠY BẰNG MÃ MÁY (INSTRUCTION EXECUTION)
  // -------------------------------------------------------------------
  initial begin
    // Khởi tạo hệ thống
    instruction  = 32'h00000000; // NOP
    mem_data_bus = 64'h0;
    v0_register  = 8'h00;
    vrs1_addr    = 5'd0;
    #15;
    $display("---------------------------------------------------------");

    // [KỊCH BẢN 1]: vle8.v v1, (a1)
    $display("[%0t] Thuc thi: vle8.v v1, data_v1", $time);
    mem_data_bus = 64'h11112222_33334444; // CPU đọc data từ RAM lên Bus
    instruction  = 32'h02058087;          // Bơm lệnh HEX vào Decoder
    #10; // Đợi 1 nhịp Clock để Decoder giải mã và VRF ghi vào
    
    // [KỊCH BẢN 2]: vle8.v v2, (a1) - Ghi lớp nền
    $display("[%0t] Thuc thi: vle8.v v2, data_v2_base", $time);
    mem_data_bus = 64'hFFFFFFFF_FFFFFFFF;
    instruction  = 32'h02058107;          // Lệnh Unmasked cho v2
    #10;

    // [KỊCH BẢN 3]: vle8.v v2, (a1), v0.t - Ghi đè có Mask
    $display("[%0t] Thuc thi: vle8.v v2, data_v2_mask, v0.t", $time);
    // 3.1: CPU nạp giá trị mask vào thanh ghi v0
    v0_register  = 8'h07;                 
    // 3.2: Thực thi lệnh Load Masked
    mem_data_bus = 64'hEEEEEEEE_EEEEEEEE;
    instruction  = 32'h00058107;          // Lệnh Masked cho v2 (bit 25 = 0)
    #10;

    // [NGHIỆM THU]: Dừng cấp lệnh và đọc thử v2 xem có bị Mask đúng không
    instruction  = 32'h00000000; // Ngừng ghi (NOP)
    vrs1_addr    = 5'd2;         // Trỏ cổng đọc số 1 vào VR2
    #10;
    
    $display("---------------------------------------------------------");
    $display("[%0t] Kiem tra VR2 hien tai: %h", $time, vrs1_data_out);
    if (vrs1_data_out == 64'hFFFFFFFF_FFEEEEEE) begin
      $display(">>> TEST PASSED: Masking hoat dong hoan hao qua Assembly!");
    end else begin
      $display(">>> TEST FAILED!");
    end
    $display("---------------------------------------------------------");
    
    $finish;
  end

endmodule