//===========================================================================================================
// Project         : UART & RVV
// Module          : Register File 
// File            : regfile.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 12/12/2025
// Updated date    : 04/03/2026
//============================================================================================================
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
  wire [31:0] q_o [0:31];
  wire [31:0] rs1_reg_data; 
  wire [31:0] rs2_reg_data;

  wire rs1_bypass_sel;
  wire rs2_bypass_sel;

  reg [31:1] enb;

  genvar i, j;

//==================================INSTANTIATION==================================
  decoder_5to32 d1 (.a_i(i_rd_addr), .out_o(out_o));
  generate
      for (i = 1; i < 32; i = i + 1) begin : gen_enb_signals
          assign enb[i] = i_rd_wren && out_o[i];
      end
  endgenerate

  register_nbit #(.WIDTH(32)) r0  (.i_clk(i_clk), .nrst_i(1'b0), .en_i(1'b1), .d_i(32'b0), .q_o(q_o[0]));
  generate
    for (j = 1; j < 32; j = j + 1) begin: register_loop
      register_nbit #(.WIDTH(32)) register_loop (.i_clk(i_clk), .nrst_i(i_reset), .en_i(enb[j]), .d_i(i_rd_data),  .q_o(q_o[j]));
    end
  endgenerate

  mux_32to1_mbit #(.WIDTH(32)) mux_rs1 (
                          .d0 (q_o[0]),  .d1(q_o[1]),  .d2(q_o[2]),  .d3(q_o[3]),
                          .d4 (q_o[4]),  .d5(q_o[5]),  .d6(q_o[6]),  .d7(q_o[7]),
                          .d8 (q_o[8]),  .d9(q_o[9]),  .d10(q_o[10]),.d11(q_o[11]),
                          .d12(q_o[12]),.d13(q_o[13]),.d14(q_o[14]),.d15(q_o[15]),
                          .d16(q_o[16]),.d17(q_o[17]),.d18(q_o[18]),.d19(q_o[19]),
                          .d20(q_o[20]),.d21(q_o[21]),.d22(q_o[22]),.d23(q_o[23]),
                          .d24(q_o[24]),.d25(q_o[25]),.d26(q_o[26]),.d27(q_o[27]),
                          .d28(q_o[28]),.d29(q_o[29]),.d30(q_o[30]),.d31(q_o[31]),
                          .s(i_rs1_addr), .y_o(rs1_reg_data)
                        );

  mux_32to1_mbit #(.WIDTH(32)) mux_rs2 (
                          .d0(q_o[0]),  .d1(q_o[1]),  .d2(q_o[2]),  .d3(q_o[3]),
                          .d4(q_o[4]),  .d5(q_o[5]),  .d6(q_o[6]),  .d7(q_o[7]),
                          .d8(q_o[8]),  .d9(q_o[9]),  .d10(q_o[10]),.d11(q_o[11]),
                          .d12(q_o[12]),.d13(q_o[13]),.d14(q_o[14]),.d15(q_o[15]),
                          .d16(q_o[16]),.d17(q_o[17]),.d18(q_o[18]),.d19(q_o[19]),
                          .d20(q_o[20]),.d21(q_o[21]),.d22(q_o[22]),.d23(q_o[23]),
                          .d24(q_o[24]),.d25(q_o[25]),.d26(q_o[26]),.d27(q_o[27]),
                          .d28(q_o[28]),.d29(q_o[29]),.d30(q_o[30]),.d31(q_o[31]),
                          .s(i_rs2_addr), .y_o(rs2_reg_data)
                        );

  //==================================READ_AFTER_WRITE====================
  assign rs1_bypass_sel = (i_rs1_addr == i_rd_addr) && i_rd_wren && (i_rd_addr != 5'b0);
  assign rs2_bypass_sel = (i_rs2_addr == i_rd_addr) && i_rd_wren && (i_rd_addr != 5'b0);
  // nếu đọc trùng với ghi thì lấy luôn data ghi vào
  mux_2to1 #(.WIDTH(32)) bypass_mux_rs1 (
                          .d0_i(rs1_reg_data),
                          .d1_i(i_rd_data),
                          .s_i(rs1_bypass_sel),
                          .y_o(o_rs1_data)
                        );

  mux_2to1 #(.WIDTH(32)) bypass_mux_rs2 (
                        .d0_i(rs2_reg_data),
                        .d1_i(i_rd_data),
                        .s_i(rs2_bypass_sel),
                        .y_o(o_rs2_data)
                      );

endmodule