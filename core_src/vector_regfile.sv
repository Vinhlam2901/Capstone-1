//===========================================================================================================
// Project         : UART & RVV
// Module          : Vector Register File 32x8bit
// File            : vector_regfile.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 04/03/2025
// Updated date    : 09/03/2026
//============================================================================================================
// remind to set parameter VWIDTH aka VLEN,max = 64, WIDTH (SEW) = 8 
module vector_regfile #(
    parameter SEW = 8,   // number of bit per cell of reg
    parameter VLEN = 64
)(
    input  wire             i_clk,
    input  wire             ni_rst,

    input  wire             i_vrd_wren,
    input  wire  [31:0]     vlen_set,       // 32bit with data equivalent to sew = 8
    input  wire  [4:0]      i_vrs1_addr,
    input  wire  [4:0]      i_vrs2_addr,
    input  wire  [4:0]      i_vrd_addr,
    input  wire  [VLEN-1:0] i_vrd_data,

    output wire  [VLEN-1:0] o_vrs1_data,
    output wire  [VLEN-1:0] o_vrs2_data
);
//==================================Declaration==================================
  wire [31:0]    out_o;
  wire [SEW-1:0] lane_in  [0:SEW-1];
  wire [VLEN-1:0] vreg_out [0:31];
  wire [VLEN-1:0] vrs1_data; 
  wire [VLEN-1:0] vrs2_data;

  wire vrs1_bypass_sel;
  wire vrs2_bypass_sel;

  wire [31:0]   enb_rows;
  reg           enb_cells;
  reg [SEW-1:0] vlen_enb;

  genvar rows, cells, j, lanes;

//==================================INSTANTIATION==================================
  decoder_5to32 decode (.a_i(i_vrd_addr), .out_o(out_o));
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

  generate 
    for (rows = 0; rows < 32; rows = rows + 1) begin: register_loop
      assign enb_rows[rows] = i_vrd_wren && out_o[rows];            // define number of wire depends on number of loops
        for (lanes = 0; lanes < 8; lanes = lanes + 1) begin
          wire enb_cells = enb_rows[rows] && vlen_enb[lanes];
          register_nbit #(.WIDTH(8)) reg_cells (
                                                .i_clk (i_clk),
                                                .nrst_i(ni_rst),
                                                .en_i  (enb_cells),
                                                .d_i   (i_vrd_data[lanes*8 + 7 : lanes*8]),   // tao ra cac cap ngo va va ngo ra tuong ung voi tung lane
                                                .q_o   (vreg_out[rows][lanes*8 + 7 : lanes*8])
                                               );
        end
    end
  endgenerate
//========================================READ_PORT==============================================================================================================
  mux_32to1_mbit #(.WIDTH(64)) mux_vrs1 (
                      .d0 (vreg_out[0]),  .d1(vreg_out[1]),  .d2(vreg_out[2]),  .d3(vreg_out[3]),
                      .d4 (vreg_out[4]),  .d5(vreg_out[5]),  .d6(vreg_out[6]),  .d7(vreg_out[7]),
                      .d8 (vreg_out[8]),  .d9(vreg_out[9]), .d10(vreg_out[10]),.d11(vreg_out[11]),
                      .d12(vreg_out[12]),.d13(vreg_out[13]),.d14(vreg_out[14]),.d15(vreg_out[15]),
                      .d16(vreg_out[16]),.d17(vreg_out[17]),.d18(vreg_out[18]),.d19(vreg_out[19]),
                      .d20(vreg_out[20]),.d21(vreg_out[21]),.d22(vreg_out[22]),.d23(vreg_out[23]),
                      .d24(vreg_out[24]),.d25(vreg_out[25]),.d26(vreg_out[26]),.d27(vreg_out[27]),
                      .d28(vreg_out[28]),.d29(vreg_out[29]),.d30(vreg_out[30]),.d31(vreg_out[31]),
                      .s(i_vrs1_addr),   .y_o(vrs1_data)
                    );

  mux_32to1_mbit #(.WIDTH(64)) mux_vrs2 (
                      .d0 (vreg_out[0]),  .d1(vreg_out[1]),  .d2(vreg_out[2]),  .d3(vreg_out[3]),
                      .d4 (vreg_out[4]),  .d5(vreg_out[5]),  .d6(vreg_out[6]),  .d7(vreg_out[7]),
                      .d8 (vreg_out[8]),  .d9(vreg_out[9]), .d10(vreg_out[10]),.d11(vreg_out[11]),
                      .d12(vreg_out[12]),.d13(vreg_out[13]),.d14(vreg_out[14]),.d15(vreg_out[15]),
                      .d16(vreg_out[16]),.d17(vreg_out[17]),.d18(vreg_out[18]),.d19(vreg_out[19]),
                      .d20(vreg_out[20]),.d21(vreg_out[21]),.d22(vreg_out[22]),.d23(vreg_out[23]),
                      .d24(vreg_out[24]),.d25(vreg_out[25]),.d26(vreg_out[26]),.d27(vreg_out[27]),
                      .d28(vreg_out[28]),.d29(vreg_out[29]),.d30(vreg_out[30]),.d31(vreg_out[31]),
                      .s(i_vrs2_addr),   .y_o(vrs2_data)
                    );
//==================================READ_AFTER_WRITE====================
  assign vrs1_bypass_sel = (i_vrs1_addr == i_vrd_addr) && i_vrd_wren;
  assign vrs2_bypass_sel = (i_vrs2_addr == i_vrd_addr) && i_vrd_wren;
  // nếu đọc trùng với ghi thì lấy luôn data ghi vào của từng lane
  generate
    for (lanes = 0;lanes < 8;lanes = lanes + 1) begin
      mux_2to1 #(.WIDTH(8)) bypass_mux_vrs1 (
        .d0_i(vrs1_data[lanes*8 + 7: lanes*8]),
        .d1_i(i_vrd_data[lanes*8 + 7: lanes*8]),
        .s_i(vrs1_bypass_sel && vlen_enb[lanes]),
        .y_o(o_vrs1_data[lanes*8 + 7: lanes*8])
      );

    mux_2to1 #(.WIDTH(8)) bypass_mux_vrs2 (
        .d0_i(vrs2_data[lanes*8 + 7: lanes*8]),
        .d1_i(i_vrd_data[lanes*8 + 7: lanes*8]),
        .s_i(vrs2_bypass_sel && vlen_enb[lanes]),
        .y_o(o_vrs2_data[lanes*8 + 7: lanes*8])
    );
    end
  endgenerate
endmodule