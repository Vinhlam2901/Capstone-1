//===========================================================================================
// Project         : UART & RVV
// Module          : Exhaustive Testbench for Vector ALU
// File            : tb_vector_alu.sv
// Author          : Chau Tran Vinh Lam (Gin) - lam.chautran@hcmut.edu.vn
//===========================================================================================
module valu_tb();
  parameter VLEN = 64;
  parameter SEW  = 8;

  logic [3:0]      i_valu_opcode;
  logic [VLEN-1:0] i_vrs1_data;
  logic [VLEN-1:0] i_vrs2_data;
  logic            i_valu_unsign;
  wire  [VLEN-1:0] o_alu_result;

  // -----------------------------------------------------------------------
  // BẢNG MÃ LỆNH (OPCODE MAP) - PHẢI KHỚP VỚI MUX TRONG vector_alu.sv
  // -----------------------------------------------------------------------
  localparam OP_SUB    = 4'd0;  // 0000 (sub_flag = 0)
  localparam OP_ADD    = 4'd1;  // 0001 (sub_flag = 1)
  localparam OP_XOR    = 4'd2;  // 0010
  localparam OP_OR     = 4'd3;  // 0011
  localparam OP_AND    = 4'd4;  // 0100
  localparam OP_SLL    = 4'd5;  // 0101
  localparam OP_SRL    = 4'd6;  // 0110
  localparam OP_SRA    = 4'd7;  // 0111
  localparam OP_MIN    = 4'd8;  // 1000
  localparam OP_MAX    = 4'd9;  // 1001
  localparam OP_MINU   = 4'd10; // 1010
  localparam OP_MAXU   = 4'd11; // 1011
  localparam OP_EQ     = 4'd12; // 1100
  localparam OP_VSSUB  = 4'd13;
  localparam OP_VSADD  = 4'd14;

  // Instantiate VALU
  vector_alu #(.VLEN(VLEN), .SEW(SEW)) dut (
    .i_valu_opcode (i_valu_opcode),
    .i_vrs1_data   (i_vrs1_data),
    .i_vrs2_data   (i_vrs2_data),
    .i_valu_unsign (i_valu_unsign),
    .o_alu_result  (o_alu_result)
  );

  // Kịch bản Test
  initial begin
    $display("\n=======================================================");
    $display("       BAT DAU TEST TOAN DIEN VECTOR ALU (14 LENH)     ");
    $display("=======================================================\n");

    i_valu_unsign = 1'b1; // Mặc định là số có dấu

    // 1. Phép CỘNG (ADD)
    // Lane 1: 50 + 20 = 70 (46), Lane 0: 10 + 15 = 25 (19)
    i_vrs1_data = {48'h0, 8'd50, 8'd10}; i_vrs2_data = {48'h0, 8'd20, 8'd15};
    i_valu_opcode = OP_ADD; #10;
    $display("[0] ADD   : %h (Expect: ...00_46_19)", o_alu_result);

    // 2. Phép TRỪ (SUB)
    // Lane 1: 50 - 20 = 30 (1E), Lane 0: 10 - 15 = -5 (FB)
    i_valu_opcode = OP_SUB; #10;
    $display("[1] SUB   : %h (Expect: ...00_1e_fb)", o_alu_result);

    // 3. Phép LOGIC (AND, OR, XOR)
    i_vrs1_data = {48'h0, 8'hFF, 8'hF0}; i_vrs2_data = {48'h0, 8'hAA, 8'h55};
    i_valu_opcode = OP_XOR; #10; $display("[2] XOR   : %h (Expect: ...00_55_a5)", o_alu_result);
    i_valu_opcode = OP_OR;  #10; $display("[3] OR    : %h (Expect: ...00_ff_f5)", o_alu_result);
    i_valu_opcode = OP_AND; #10; $display("[4] AND   : %h (Expect: ...00_aa_50)", o_alu_result);

    // 4. Phép DỊCH (SLL, SRL, SRA)
    // Lane 1: 8'h80 (-128) dịch 1, Lane 0: 8'h01 dịch 2
    i_vrs1_data = {48'h0, 8'h80, 8'h01}; i_vrs2_data = {48'h0, 8'd1, 8'd2};
    i_valu_opcode = OP_SLL; #10; $display("[5] SLL   : %h (Expect: ...00_00_04)", o_alu_result);
    i_valu_opcode = OP_SRL; #10; $display("[6] SRL   : %h (Expect: ...00_40_00)", o_alu_result);
    i_valu_opcode = OP_SRA; #10; $display("[7] SRA   : %h (Expect: ...00_c0_00)", o_alu_result); // Giữ bit dấu!

    // 5. Phép SO SÁNH (MIN, MAX) - Có dấu
    // Lane 1: So sánh -10 (F6) và 20 (14), Lane 0: So sánh -50 (CE) và -100 (9C)
    i_vrs1_data = {48'h0, 8'hF6, 8'hCE}; i_vrs2_data = {48'h0, 8'h14, 8'h9C};
    i_valu_opcode = OP_MIN; #10; $display("[8] MIN   : %h (Expect: ...00_f6_9c)", o_alu_result);
    i_valu_opcode = OP_MAX; #10; $display("[9] MAX   : %h (Expect: ...00_14_ce)", o_alu_result);

    // 6. Phép SO SÁNH (MINU, MAXU) - Không dấu
    // Ép ALU hiểu F6 là 246 (Không dấu), CE là 206 (Không dấu)
    i_valu_unsign = 1'b0; 
    i_valu_opcode = OP_MINU; #10; $display("[A] MINU  : %h (Expect: ...00_14_9c)", o_alu_result);
    i_valu_opcode = OP_MAXU; #10; $display("[B] MAXU  : %h (Expect: ...00_f6_ce)", o_alu_result);
    i_valu_unsign = 1'b1; // Trả lại có dấu

    // 7. Phép BẰNG NHAU (EQ)
    i_vrs1_data = {48'h0, 8'hAA, 8'hBB}; i_vrs2_data = {48'h0, 8'hAA, 8'hCC};
    i_valu_opcode = OP_EQ; #10; $display("[C] EQ    : %h (Expect: ...00_01_00)", o_alu_result);

    // 8. Phép TOÁN BÃO HÒA (VSADD, VSSUB)
    // Lane 1: 100 + 50 = 150 -> Tràn nóc (7F)
    // Lane 0: -100 + (-50) = -150 -> Thủng đáy (80)
    i_vrs1_data = {48'h0, 8'd100, -8'd100}; i_vrs2_data = {48'h0, 8'd50, -8'd50};
    i_valu_opcode = OP_VSADD; #10; $display("[D] VSADD : %h (Expect: ...00_7f_80) %h", o_alu_result, dut.vrd_addsubs);

    // Lane 1: 100 - (-50) = 150 -> Tràn nóc (7F)
    // Lane 0: -100 - 50 = -150 -> Thủng đáy (80)
    i_vrs2_data = {48'h0, -8'd50, 8'd50}; // Đảo dấu vrs2 để thử phép trừ
    i_valu_opcode = OP_VSSUB; #10; $display("[E] VSSUB : %h (Expect: ...00_7f_80)%h", o_alu_result, dut.vrd_addsubs);

    $display("\n=================== TEST HOAN TAT =====================");
    #20 $finish;
  end
endmodule