//===========================================================================================
// Project         : UART & RVV
// Module          : Testbench for Datapath (VRF + VALU)
// File            : tb_vrf_valu.sv
// Author          : Chau Tran Vinh Lam (Gin) - lam.chautran@hcmut.edu.vn
//===========================================================================================
module valu_vrf_tb();
  parameter VLEN = 64;
  parameter SEW  = 8;

  // Tín hiệu Clock và Reset
  logic clk;
  logic rst_n;

  // Tín hiệu điều khiển VRF
  logic [4:0]      i_rs1_addr, i_rs2_addr, i_rd_addr;
  logic            i_we;
  logic [VLEN-1:0] i_rd_data;
  wire  [VLEN-1:0] o_rs1_data, o_rs2_data;

  // Tín hiệu điều khiển VALU
  logic [4:0]      i_valu_opcode;
  wire  [VLEN-1:0] o_alu_result;

  localparam OP_ADD = 5'b00000;

  // 1. Instantiate Khối Vector Register File (VRF)
  vector_regfile #(
    .VLEN(VLEN),
    .SEW(8)
  ) vrf_inst (
    .i_clk        (clk),
    .ni_rst      (rst_n),
    .i_vrd_wren       (i_we),
    .i_vrd_addr  (i_rd_addr),
    .i_vrd_data  (i_rd_data),      // Data ghi vào thanh ghi
    .i_vrs1_addr (i_rs1_addr),
    .i_vrs2_addr (i_rs2_addr),
    .o_vrs1_data (o_rs1_data),     // Data đọc ra từ thanh ghi
    .o_vrs2_data (o_rs2_data)
  );

  // 2. Instantiate Khối Vector ALU (VALU)
  vector_alu #(
    .VLEN(VLEN),
    .SEW(SEW)
  ) valu_inst (
    .i_valu_opcode (i_valu_opcode),
    .i_vrs1_data   (o_rs1_data),   // Đấu nối ngõ ra VRF vào ngõ vào VALU
    .i_vrs2_data   (o_rs2_data),   
    .o_alu_result  (o_alu_result)  // Ngõ ra của VALU
  );

  // Ghi kết quả ALU ngược lại vào VRF (Đường Write-Back)
  assign i_rd_data = o_alu_result;

  // Tạo Clock (Chu kỳ 10ns)
  always #5 clk = ~clk;

  // Kịch bản Test
  initial begin
    // Khởi tạo
    clk = 0;
    rst_n = 0;
    i_we = 0;
    i_rs1_addr = 0; i_rs2_addr = 0; i_rd_addr = 0;
    i_valu_opcode = OP_ADD;

    // Giải nén Reset
    #15 rst_n = 1;

    // BƯỚC 1: Ghi dữ liệu giả lập vào thanh ghi v1
    @(negedge clk);
    i_we = 1;
    i_rd_addr = 5'd1;           // Chọn thanh ghi v1
    // Chèn data trực tiếp vào dây Write-back (Bỏ qua ALU tạm thời)
    force i_rd_data = 64'h1111_2222_3333_4444; 
    
    // BƯỚC 2: Ghi dữ liệu giả lập vào thanh ghi v2
    @(negedge clk);
    i_rd_addr = 5'd2;           // Chọn thanh ghi v2
    force i_rd_data = 64'h5555_6666_7777_8888;

    // BƯỚC 3: Thực hiện lệnh vadd.vv v3, v1, v2
    @(negedge clk);
    release i_rd_data;          // Thả dây i_rd_data ra để nó nhận kết quả từ o_alu_result
    i_we = 1;                   // Cho phép ghi kết quả
    i_rs1_addr = 5'd1;          // Đọc v1
    i_rs2_addr = 5'd2;          // Đọc v2
    i_rd_addr  = 5'd3;          // Ghi vào v3
    i_valu_opcode = OP_ADD;     // Báo ALU làm phép cộng

    // BƯỚC 4: Đọc thanh ghi v3 ra để kiểm tra
    @(negedge clk);
    i_we = 0;                   // Tắt ghi
    i_rs1_addr = 5'd3;          // Đọc v3 ra cổng o_rs1_data
    
    #10;
    $display("Datapath Test Complete. Check Waveform for v3 data = 6666_8888_aaaa_cccc");
    $finish;
  end
endmodule