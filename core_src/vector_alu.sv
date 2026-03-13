//===========================================================================================================
// Project         : UART & RVV
// Module          : Vector ALU 8 lanes 8 bit
// File            : vector_alu.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 04/03/2025
// Updated date    : 13/03/2026
//============================================================================================================
module vector_alu #(
  parameter VLEN = 64,
  parameter SEW = 8
)(
    input  wire [3:0]      i_valu_opcode,
    input  wire [VLEN-1:0] i_vrs1_data,
    input  wire [VLEN-1:0] i_vrs2_data,
    input  wire            i_valu_unsign,
    output wire [VLEN-1:0] o_alu_result
);
//======================DECLARATION=======================================================================
  genvar lanes;
  wire [VLEN-1:0] vrd_addsub, vrd_sra, vrd_sll, vrd_srl,
                  vrd_and, vrd_or, vrd_xor,
                  vrd_min, vrd_max, vrd_minu, vrd_maxu, vrd_eq,
                  vrd_addsubs;
 wire             add_flag, sub_flag, adds_flag, subs_flag;
//======================INSTANTIATE===========================================================================
  assign sub_flag  =  ~i_valu_opcode[3] && ~i_valu_opcode[2] && ~i_valu_opcode[1] && ~i_valu_opcode[0];  // 4'b0000
  assign subs_flag =   i_valu_opcode[3] &&  i_valu_opcode[2] && ~i_valu_opcode[1] &&  i_valu_opcode[0];  // 4'b1101
  generate
    for (lanes = 0;lanes < VLEN/SEW; lanes = lanes + 1) begin
      // voi moi lane se co tuong ung 8bit vrs1, vrs2 
      wire [SEW-1:0] vrs1_lanes = i_vrs1_data[lanes*8 + 7: lanes*8];
      wire [SEW-1:0] vrs2_lanes = i_vrs2_data[lanes*8 + 7: lanes*8];
      // cac vrs1, vrs2 nay se la cac data cua tung cell cua VRF
      // co 8 cells moi thanh ghi, nen se co 8 bo tinh toan 8 bit
      add_subtract #(.WIDTH(SEW)) sub_module (
                                              .a_i     (vrs1_lanes),
                                              .b_i     (vrs2_lanes),
                                              .cin_i   (sub_flag),
                                              .result_o(vrd_addsub[lanes*8 + 7: lanes*8]),
                                              .cout_o  ()
                                             );
      and_module #(.WIDTH(SEW)) and_module   (
                                              .rs1_i(vrs1_lanes),
                                              .rs2_i(vrs2_lanes),
                                              .rd_o (vrd_and[lanes*8 + 7: lanes*8])
                                             );
      or_module #(.WIDTH(SEW))  or_module   (
                                              .rs1_i(vrs1_lanes),
                                              .rs2_i(vrs2_lanes),
                                              .rd_o (vrd_or[lanes*8 + 7: lanes*8])
                                             );
      xor_module #(.WIDTH(SEW)) xor_module   (
                                              .rs1_i(vrs1_lanes),
                                              .rs2_i(vrs2_lanes),
                                              .rd_o (vrd_xor[lanes*8 + 7: lanes*8])
                                             );
      sra_8bit                  sra          (
                                              .vrs1_data(vrs1_lanes),
                                              .vrs2_data(vrs2_lanes),
                                              .vrd_data (vrd_sra[lanes*8 + 7 : lanes*8])  
                                             );
      sll_8bit                  sll          (
                                              .vrs1_data(vrs1_lanes),
                                              .vrs2_data(vrs2_lanes),
                                              .vrd_data (vrd_sll[lanes*8 + 7 : lanes*8])  
                                             );
      srl_8bit                  srl          (
                                              .vrs1_data(vrs1_lanes),
                                              .vrs2_data(vrs2_lanes),
                                              .vrd_data (vrd_srl[lanes*8 + 7 : lanes*8])  
                                             );
      min_max  #(.WIDTH(SEW))  min_max       ( 
                                              .i_vrs1_data(vrs1_lanes),
                                              .i_vrs2_data(vrs2_lanes),
                                              .i_cp_un    (i_valu_unsign),
                                              .o_max      (vrd_max[lanes*8 + 7 : lanes*8]),
                                              .o_maxu     (vrd_maxu[lanes*8 + 7 : lanes*8]),
                                              .o_min      (vrd_min[lanes*8 + 7 : lanes*8]),
                                              .o_minu     (vrd_minu[lanes*8 + 7 : lanes*8]),
                                              .o_eq       (vrd_eq[lanes*8])   // 1bit per lanes
                                             );       
    assign vrd_eq[lanes*8 + 7 : lanes*8 + 1] = 7'b0;                                                                        
    addsub_sat #(.WIDTH(SEW)) add_sat        (
                                              .vrs1_i (vrs1_lanes),
                                              .vrs2_i (vrs2_lanes),
                                              .i_sign (i_valu_unsign),
                                              .vcin_i (subs_flag),
                                              .vsat_o (vrd_addsubs[lanes*8 + 7 : lanes*8]),
                                              .vcout_o()
                                             );                                        
    end
  endgenerate
  mux_16to1 #(.WIDTH(VLEN)) mux1 (
                                  .d0   (vrd_addsub),  // OP_SUB  (0)
                                  .d1   (vrd_addsub),  // OP_ADD  (1)
                                  .d2   (vrd_xor),     // OP_XOR  (2)
                                  .d3   (vrd_or),      // OP_OR   (3)
                                  .d4   (vrd_and),     // OP_AND  (4)
                                  .d5   (vrd_sll),     // OP_SLL  (5)
                                  .d6   (vrd_srl),     // OP_SRL  (6)
                                  .d7   (vrd_sra),     // OP_SRA  (7)
                                  .d8   (vrd_min),     // OP_MIN  (8)
                                  .d9   (vrd_max),     // OP_MAX  (9)
                                  .d10  (vrd_minu),    // OP_MINU (10)
                                  .d11  (vrd_maxu),    // OP_MAXU (11)
                                  .d12  (vrd_eq),      // OP_EQ   (12)
                                  .d13  (vrd_addsubs), // OP_VSSUB(13)
                                  .d14  (vrd_addsubs), // OP_VSADD(14)
                                  .d15  ({VLEN{1'b0}}),
                                  .s    (i_valu_opcode),
                                  .y_o  (o_alu_result)
                              );
endmodule