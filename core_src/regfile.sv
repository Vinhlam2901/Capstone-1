module regfile (
    input  wire         i_clk,
    input  wire         i_reset,

    input  wire  [4:0]  i_rs1_addr,
    input  wire  [4:0]  i_rs2_addr,
    input  wire  [4:0]  i_rd_addr,
    input  wire  [31:0] i_rd_data,
    input  wire         i_rd_wren,

    output wire  [31:0]  o_rs1_data,
    output wire  [31:0]  o_rs2_data
);

  //==================================Declaration==================================
  wire [31:0] out_o;
  wire [31:0] q_o0, q_o1, q_o2, q_o3, q_o4, q_o5, q_o6, q_o7,
              q_o8, q_o9, q_o10, q_o11, q_o12, q_o13, q_o14, q_o15,
              q_o16, q_o17, q_o18, q_o19, q_o20, q_o21, q_o22, q_o23,
              q_o24, q_o25, q_o26, q_o27, q_o28, q_o29, q_o30, q_o31;
  wire [31:0] rs1_reg_data; 
  wire [31:0] rs2_reg_data;

  wire rs1_bypass_sel;
  wire rs2_bypass_sel;

  wire [31:1] enb;

  decoder_5to32 d1 (.a_i(i_rd_addr), .out_o(out_o));

  assign enb[1]   = i_rd_wren & out_o[1];
  assign enb[2]   = i_rd_wren & out_o[2];
  assign enb[3]   = i_rd_wren & out_o[3];
  assign enb[4]   = i_rd_wren & out_o[4];
  assign enb[5]   = i_rd_wren & out_o[5];
  assign enb[6]   = i_rd_wren & out_o[6];
  assign enb[7]   = i_rd_wren & out_o[7];
  assign enb[8]   = i_rd_wren & out_o[8];
  assign enb[9]   = i_rd_wren & out_o[9];
  assign enb[10]  = i_rd_wren & out_o[10];
  assign enb[11]  = i_rd_wren & out_o[11];
  assign enb[12]  = i_rd_wren & out_o[12];
  assign enb[13]  = i_rd_wren & out_o[13];
  assign enb[14]  = i_rd_wren & out_o[14];
  assign enb[15]  = i_rd_wren & out_o[15];
  assign enb[16]  = i_rd_wren & out_o[16];
  assign enb[17]  = i_rd_wren & out_o[17];
  assign enb[18]  = i_rd_wren & out_o[18];
  assign enb[19]  = i_rd_wren & out_o[19];
  assign enb[20]  = i_rd_wren & out_o[20];
  assign enb[21]  = i_rd_wren & out_o[21];
  assign enb[22]  = i_rd_wren & out_o[22];
  assign enb[23]  = i_rd_wren & out_o[23];
  assign enb[24]  = i_rd_wren & out_o[24];
  assign enb[25]  = i_rd_wren & out_o[25];
  assign enb[26]  = i_rd_wren & out_o[26];
  assign enb[27]  = i_rd_wren & out_o[27];
  assign enb[28]  = i_rd_wren & out_o[28];
  assign enb[29]  = i_rd_wren & out_o[29];
  assign enb[30]  = i_rd_wren & out_o[30];
  assign enb[31]  = i_rd_wren & out_o[31];

  register_32bit r0  (.i_clk(i_clk), .nrst_i(1'b0),    .en_i(1'b1),    .d_i(32'b0),     .q_o(q_o0) );
  register_32bit r1  (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[1]),  .d_i(i_rd_data), .q_o(q_o1) );
  register_32bit r2  (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[2]),  .d_i(i_rd_data), .q_o(q_o2) );
  register_32bit r3  (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[3]),  .d_i(i_rd_data), .q_o(q_o3) );
  register_32bit r4  (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[4]),  .d_i(i_rd_data), .q_o(q_o4) );
  register_32bit r5  (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[5]),  .d_i(i_rd_data), .q_o(q_o5) );
  register_32bit r6  (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[6]),  .d_i(i_rd_data), .q_o(q_o6) );
  register_32bit r7  (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[7]),  .d_i(i_rd_data), .q_o(q_o7) );
  register_32bit r8  (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[8]),  .d_i(i_rd_data), .q_o(q_o8) );
  register_32bit r9  (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[9]),  .d_i(i_rd_data), .q_o(q_o9) );
  register_32bit r10 (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[10]), .d_i(i_rd_data), .q_o(q_o10));
  register_32bit r11 (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[11]), .d_i(i_rd_data), .q_o(q_o11));
  register_32bit r12 (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[12]), .d_i(i_rd_data), .q_o(q_o12));
  register_32bit r13 (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[13]), .d_i(i_rd_data), .q_o(q_o13));
  register_32bit r14 (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[14]), .d_i(i_rd_data), .q_o(q_o14));
  register_32bit r15 (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[15]), .d_i(i_rd_data), .q_o(q_o15));
  register_32bit r16 (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[16]), .d_i(i_rd_data), .q_o(q_o16));
  register_32bit r17 (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[17]), .d_i(i_rd_data), .q_o(q_o17));
  register_32bit r18 (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[18]), .d_i(i_rd_data), .q_o(q_o18));
  register_32bit r19 (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[19]), .d_i(i_rd_data), .q_o(q_o19));
  register_32bit r20 (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[20]), .d_i(i_rd_data), .q_o(q_o20));
  register_32bit r21 (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[21]), .d_i(i_rd_data), .q_o(q_o21));
  register_32bit r22 (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[22]), .d_i(i_rd_data), .q_o(q_o22));
  register_32bit r23 (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[23]), .d_i(i_rd_data), .q_o(q_o23));
  register_32bit r24 (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[24]), .d_i(i_rd_data), .q_o(q_o24));
  register_32bit r25 (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[25]), .d_i(i_rd_data), .q_o(q_o25));
  register_32bit r26 (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[26]), .d_i(i_rd_data), .q_o(q_o26));
  register_32bit r27 (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[27]), .d_i(i_rd_data), .q_o(q_o27));
  register_32bit r28 (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[28]), .d_i(i_rd_data), .q_o(q_o28));
  register_32bit r29 (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[29]), .d_i(i_rd_data), .q_o(q_o29));
  register_32bit r30 (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[30]), .d_i(i_rd_data), .q_o(q_o30));
  register_32bit r31 (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[31]), .d_i(i_rd_data), .q_o(q_o31));

  mux_32to1 mux_rs1 (
                      .d0(q_o0),  .d1(q_o1),  .d2(q_o2),  .d3(q_o3),
                      .d4(q_o4),  .d5(q_o5),  .d6(q_o6),  .d7(q_o7),
                      .d8(q_o8),  .d9(q_o9),  .d10(q_o10),.d11(q_o11),
                      .d12(q_o12),.d13(q_o13),.d14(q_o14),.d15(q_o15),
                      .d16(q_o16),.d17(q_o17),.d18(q_o18),.d19(q_o19),
                      .d20(q_o20),.d21(q_o21),.d22(q_o22),.d23(q_o23),
                      .d24(q_o24),.d25(q_o25),.d26(q_o26),.d27(q_o27),
                      .d28(q_o28),.d29(q_o29),.d30(q_o30),.d31(q_o31),
                      .s(i_rs1_addr), .y_o(rs1_reg_data)
                    );

  mux_32to1 mux_rs2 (
                      .d0(q_o0),  .d1(q_o1),  .d2(q_o2),  .d3(q_o3),
                      .d4(q_o4),  .d5(q_o5),  .d6(q_o6),  .d7(q_o7),
                      .d8(q_o8),  .d9(q_o9),  .d10(q_o10),.d11(q_o11),
                      .d12(q_o12),.d13(q_o13),.d14(q_o14),.d15(q_o15),
                      .d16(q_o16),.d17(q_o17),.d18(q_o18),.d19(q_o19),
                      .d20(q_o20),.d21(q_o21),.d22(q_o22),.d23(q_o23),
                      .d24(q_o24),.d25(q_o25),.d26(q_o26),.d27(q_o27),
                      .d28(q_o28),.d29(q_o29),.d30(q_o30),.d31(q_o31),
                      .s(i_rs2_addr), .y_o(rs2_reg_data)
                    );

  //==================================READ_AFTER_WRITE====================
  assign rs1_bypass_sel = (i_rs1_addr == i_rd_addr) && i_rd_wren && (i_rd_addr != 5'b0);
  assign rs2_bypass_sel = (i_rs2_addr == i_rd_addr) && i_rd_wren && (i_rd_addr != 5'b0);
  // nếu đọc trùng với ghi thì lấy luôn data ghi vào
  mux_2to1 bypass_mux_rs1 (
      .d0_i(rs1_reg_data),
      .d1_i(i_rd_data),
      .s_i(rs1_bypass_sel),
      .y_o(o_rs1_data)
  );

  mux_2to1 bypass_mux_rs2 (
      .d0_i(rs2_reg_data),
      .d1_i(i_rd_data),
      .s_i(rs2_bypass_sel),
      .y_o(o_rs2_data)
  );

endmodule