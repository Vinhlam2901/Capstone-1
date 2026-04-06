//===========================================================================================================
// Project         : UART & RVV
// Module          : Vector Control Unit
// File            : vector_control.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 04/03/2025
// Updated date    : 01/04/2026
//============================================================================================================
import package_param::*;
module vector_control (
	input  wire        i_clk,
	input  wire        ni_rst,
  input  wire [31:0] inst,
	input  wire        vector_enb,
  input  wire [31:0] rs1_data,
	output reg         valu_unsign,
	output reg         vector_wb,
  output reg  [1:0]  vop1_sel,    // no need vs2 cuz it hardwire at [24:20]
  output reg  [31:0] vlen_set,
  output reg  [31:0] vlen_enb,
  output reg  [3:0]  valu_opcode
);
//========================DECLEARATION===============================================================================
  wire is_vx, vx_add, vx_sub, vx_rsub, vx_min, vx_max, vx_minu, vx_maxu, vx_and, vx_or, vx_xor, vx_sadd, vx_ssub, vx_ssubu, vx_saddu, vx_sll, vx_srl, vx_sra;
  wire is_vv, vv_add, vv_sub, vv_min, vv_max, vv_minu, vv_maxu, vv_and, vv_or, vv_xor, vv_sadd, vv_ssub, vv_ssubu, vv_saddu, vv_sll, vv_srl, vv_sra;
  wire is_vi, vi_add, vi_and, vi_or, vi_xor, vi_sadd, vi_saddu, vi_sll, vi_srl, vi_sra, is_vsetvli;
  reg  [31:0] vl_reg;
  reg  [31:0] vl_next;
  reg  [17:0] vxtype;
  reg  [16:0] vvtype;
  reg  [9:0]  vitype;

//==========================VECTOR-SCALAR=========================================================================
  // func3 = 0x04 = 100
  assign is_vx    = inst[14] & ~inst[13] & ~inst[12];
  // func6 = 0x00
  assign vx_add   = is_vx & ~inst[26] & ~inst[27] & ~inst[28] & ~inst[29] & ~inst[31]; 
  // func6 = 0x02
  assign vx_sub   = is_vx & ~inst[26] &  inst[27] & ~inst[28] & ~inst[29] & ~inst[31]; 
  // func6 = 0x03
  assign vx_rsub  = is_vx &  inst[26] &  inst[27] & ~inst[28] & ~inst[29] & ~inst[31]; 
  // func6 = 0x04
  assign vx_minu  = is_vx & ~inst[26] & ~inst[27] &  inst[28] & ~inst[29] & ~inst[31]; 
  // func6 = 0x05
  assign vx_min   = is_vx &  inst[26] & ~inst[27] &  inst[28] & ~inst[29] & ~inst[31]; 
  // func6 = 0x06
  assign vx_maxu  = is_vx & ~inst[26] &  inst[27] &  inst[28] & ~inst[29] & ~inst[31]; 
  // func6 = 0x07
  assign vx_max   = is_vx &  inst[26] &  inst[27] &  inst[28] & ~inst[29] & ~inst[31]; 
  // func6 = 0x09
  assign vx_and   = is_vx &  inst[26] & ~inst[27] & ~inst[28] &  inst[29] & ~inst[31]; 
  // func6 = 0x0a
  assign vx_or    = is_vx & ~inst[26] &  inst[27] & ~inst[28] &  inst[29] & ~inst[31]; 
  // func6 = 0x0b
  assign vx_xor   = is_vx &  inst[26] &  inst[27] & ~inst[28] &  inst[29] & ~inst[31]; 
  // func6 = 0x20
  assign vx_saddu = is_vx & ~inst[26] & ~inst[27] & ~inst[28] & ~inst[29] &  inst[31]; 
  // func6 = 0x21
  assign vx_sadd  = is_vx &  inst[26] & ~inst[27] & ~inst[28] & ~inst[29] &  inst[31]; 
  // func6 = 0x22
  assign vx_ssubu = is_vx & ~inst[26] &  inst[27] & ~inst[28] & ~inst[29] &  inst[31]; 
  // func6 = 0x23
  assign vx_ssub  = is_vx &  inst[26] &  inst[27] & ~inst[28] & ~inst[29] &  inst[31]; 
  // func6 = 0x25
  assign vx_sll   = is_vx &  inst[26] & ~inst[27] &  inst[28] & ~inst[29] &  inst[31]; 
  // func6 = 0x28
  assign vx_srl   = is_vx & ~inst[26] & ~inst[27] & ~inst[28] &  inst[29] &  inst[31]; 
  // func6 = 0x29
  assign vx_sra   = is_vx &  inst[26] & ~inst[27] & ~inst[28] &  inst[29] &  inst[31]; 
  // concatenation
  assign vxtype   = {vx_add, vx_sub, vx_rsub, vx_minu, vx_min, vx_maxu, vx_max, vx_and, vx_or, vx_xor, vx_saddu, vx_sadd, vx_ssubu, vx_ssub, vx_sll, vx_srl, vx_sra};
//==========================VECTOR-VECTOR=========================================================================
  // func3 = 0x04 = 000
  assign is_vv    = ~inst[14] & ~inst[13] & ~inst[12];
  // func6 = 0x00
  assign vv_add   = is_vv & ~inst[26] & ~inst[27] & ~inst[28] & ~inst[29] & ~inst[31]; 
  // func6 = 0x02
  assign vv_sub   = is_vv & ~inst[26] &  inst[27] & ~inst[28] & ~inst[29] & ~inst[31]; 
  // func6 = 0x04
  assign vv_minu  = is_vv & ~inst[26] & ~inst[27] &  inst[28] & ~inst[29] & ~inst[31]; 
  // func6 = 0x05
  assign vv_min   = is_vv &  inst[26] & ~inst[27] &  inst[28] & ~inst[29] & ~inst[31]; 
  // func6 = 0x06
  assign vv_maxu  = is_vv & ~inst[26] &  inst[27] &  inst[28] & ~inst[29] & ~inst[31]; 
  // func6 = 0x07
  assign vv_max   = is_vv &  inst[26] &  inst[27] &  inst[28] & ~inst[29] & ~inst[31]; 
  // func6 = 0x09
  assign vv_and   = is_vv &  inst[26] & ~inst[27] & ~inst[28] &  inst[29] & ~inst[31]; 
  // func6 = 0x0a
  assign vv_or    = is_vv & ~inst[26] &  inst[27] & ~inst[28] &  inst[29] & ~inst[31]; 
  // func6 = 0x0b
  assign vv_xor   = is_vv &  inst[26] &  inst[27] & ~inst[28] &  inst[29] & ~inst[31]; 
  // func6 = 0x20
  assign vv_saddu = is_vv & ~inst[26] & ~inst[27] & ~inst[28] & ~inst[29] &  inst[31]; 
  // func6 = 0x21
  assign vv_sadd  = is_vv &  inst[26] & ~inst[27] & ~inst[28] & ~inst[29] &  inst[31]; 
  // func6 = 0x22
  assign vv_ssubu = is_vv & ~inst[26] &  inst[27] & ~inst[28] & ~inst[29] &  inst[31]; 
  // func6 = 0x23
  assign vv_ssub  = is_vv &  inst[26] &  inst[27] & ~inst[28] & ~inst[29] &  inst[31]; 
  // func6 = 0x25
  assign vv_sll   = is_vv &  inst[26] & ~inst[27] &  inst[28] & ~inst[29] &  inst[31]; 
  // func6 = 0x28
  assign vv_srl   = is_vv & ~inst[26] & ~inst[27] & ~inst[28] &  inst[29] &  inst[31]; 
  // func6 = 0x29
  assign vv_sra   = is_vv &  inst[26] & ~inst[27] & ~inst[28] &  inst[29] &  inst[31]; 
  // concatenation
  assign vvtype   = {vv_add, vv_sub, vv_minu, vv_min, vv_maxu, vv_max, vv_and, vv_or, vv_xor, vv_saddu, vv_sadd, vv_ssubu, vv_ssub, vv_sll, vv_srl, vv_sra};
//==========================VECTOR-IMMEDIATE=========================================================================
  // func3 = 0x04 = 011
  assign is_vi    = ~inst[14] & inst[13] & inst[12];
  // func6 = 0x00
  assign vi_add   = is_vi & ~inst[26] & ~inst[27] & ~inst[28] & ~inst[29] & ~inst[31]; 
  // func6 = 0x03
  assign vi_rsub  = is_vi &  inst[26] &  inst[27] & ~inst[28] & ~inst[29] & ~inst[31]; 
  // func6 = 0x09
  assign vi_and   = is_vi &  inst[26] & ~inst[27] & ~inst[28] &  inst[29] & ~inst[31]; 
  // func6 = 0x0a
  assign vi_or    = is_vi & ~inst[26] &  inst[27] & ~inst[28] &  inst[29] & ~inst[31]; 
  // func6 = 0x0b
  assign vi_xor   = is_vi &  inst[26] &  inst[27] & ~inst[28] &  inst[29] & ~inst[31]; 
  // func6 = 0x20
  assign vi_saddu = is_vi & ~inst[26] & ~inst[27] & ~inst[28] & ~inst[29] &  inst[31]; 
  // func6 = 0x21
  assign vi_sadd  = is_vi &  inst[26] & ~inst[27] & ~inst[28] & ~inst[29] &  inst[31]; 
  // func6 = 0x25
  assign vi_sll   = is_vi &  inst[26] & ~inst[27] &  inst[28] & ~inst[29] &  inst[31]; 
  // func6 = 0x28
  assign vi_srl   = is_vi & ~inst[26] & ~inst[27] & ~inst[28] &  inst[29] &  inst[31]; 
  // func6 = 0x29
  assign vi_sra   = is_vi &  inst[26] & ~inst[27] & ~inst[28] &  inst[29] &  inst[31]; 
  // concatenation
  assign vitype   = {vi_add, vi_rsub, vi_and, vi_or, vi_xor, vi_saddu, vi_sadd, vi_sll, vi_srl, vi_sra};
  //========================VLEN_SET====================================================================================
  assign is_vsetvli = inst[14] & inst[13] & inst[12];

  min_max  #(.WIDTH(32))  min_max       ( 
                                          .i_vrs1_data(32'd8),
                                          .i_vrs2_data(rs1_data),
                                          .i_cp_un    (1),
                                          .o_max      (),
                                          .o_maxu     (),
                                          .o_min      (),
                                          .o_minu     (vl_next),
                                          .o_eq       ()
                                          );    
  always_ff @(posedge i_clk or negedge ni_rst) begin
      if (!ni_rst) begin
          vl_reg <= 32'd0;
      end else if (is_vsetvli) begin
          vl_reg <= vl_next; 
      end
  end                                
  assign vlen_set = vl_reg;
  always_comb begin
    case (vl_reg)
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
  //========================VECTOR OPCODE===============================================================================
  always_comb begin : inst_vector_decode
    valu_opcode = 4'b0000; 
    valu_unsign = 1'b1;
    vop1_sel    = 2'b01;   // vs1
    vector_wb   = 1'b0;    // valu
    if (vector_enb) begin 
      if (is_vx) begin
        unique case (vxtype)
          17'b10000000000000000 : begin
                                  valu_opcode = 4'd1;  // vx_add   -> OP_ADD
                                  valu_unsign = 1'b0;
          end                                  
          17'b01000000000000000 : begin
                                  valu_opcode = 4'd0;  // vx_sub   -> OP_SUB
                                  valu_unsign = 1'b0;
          end
          17'b00100000000000000 : begin
                                  valu_opcode = 4'd0;  // vx_rsub  -> OP_SUB (*)
                                  valu_unsign = 1'b0;
          end                                  
          17'b00010000000000000 : valu_opcode = 4'd10; // vx_minu  -> OP_MINU
          17'b00001000000000000 : begin
                                  valu_opcode = 4'd8;  // vx_min   -> OP_MIN
                                  valu_unsign = 1'b0;
          end
          17'b00000100000000000 : valu_opcode = 4'd11; // vx_maxu  -> OP_MAXU
          17'b00000010000000000 : begin
                                  valu_opcode = 4'd9;  // vx_max   -> OP_MAX
                                  valu_unsign = 1'b0;
          end
          17'b00000001000000000 : valu_opcode = 4'd4;  // vx_and   -> OP_AND
          17'b00000000100000000 : valu_opcode = 4'd3;  // vx_or    -> OP_OR
          17'b00000000010000000 : valu_opcode = 4'd2;  // vx_xor   -> OP_XOR
          17'b00000000001000000 : valu_opcode = 4'd14; // vx_saddu -> OP_VSADD
          17'b00000000000100000 : begin
                                  valu_opcode = 4'd14; // vx_sadd  -> OP_VSADD
                                  valu_unsign = 1'b0;
          end                                  
          17'b00000000000010000 : valu_opcode = 4'd13; // vx_ssubu -> OP_VSSUB
          17'b00000000000001000 : begin
                                  valu_opcode = 4'd13; // vx_ssub  -> OP_VSSUB
                                  valu_unsign = 1'b0;
          end                                  
          17'b00000000000000100 : valu_opcode = 4'd5;  // vx_sll   -> OP_SLL
          17'b00000000000000010 : valu_opcode = 4'd6;  // vx_srl   -> OP_SRL
          17'b00000000000000001 : begin
                                  valu_opcode = 4'd7;  // vx_sra   -> OP_SRA
                                  valu_unsign = 1'b0;
          end                                  
          default               : valu_opcode = 4'd0;
        endcase
      end
      else if (is_vv) begin
        unique case (vvtype)
          16'b1000000000000000  : begin
                                  valu_opcode = 4'd1;  // vv_add   -> OP_ADD
                                  valu_unsign = 1'b0;
          end                                  
          16'b0100000000000000  : begin
                                  valu_opcode = 4'd0;  // vv_sub   -> OP_SUB
                                  valu_unsign = 1'b0;
          end                                  
          16'b0010000000000000  : valu_opcode = 4'd10; // vv_minu  -> OP_MINU
          16'b0001000000000000  : begin
                                  valu_opcode = 4'd8;  // vv_min   -> OP_MIN
                                  valu_unsign = 1'b0;
          end                                  
          16'b0000100000000000  : valu_opcode = 4'd11; // vv_maxu  -> OP_MAXU
          16'b0000010000000000  : begin 
                                  valu_opcode = 4'd9;  // vv_max   -> OP_MAX
                                  valu_unsign = 1'b0;
          end                                  
          16'b0000001000000000  : valu_opcode = 4'd4;  // vv_and   -> OP_AND
          16'b0000000100000000  : valu_opcode = 4'd3;  // vv_or    -> OP_OR
          16'b0000000010000000  : valu_opcode = 4'd2;  // vv_xor   -> OP_XOR
          16'b0000000001000000  : valu_opcode = 4'd14; // vv_saddu -> OP_VSADD
          16'b0000000000100000  : begin
                                  valu_opcode = 4'd14; // vv_sadd  -> OP_VSADD
                                  valu_unsign = 1'b0;
          end                                  
          16'b0000000000010000  : valu_opcode = 4'd13; // vv_ssubu -> OP_VSSUB
          16'b0000000000001000  : begin
                                  valu_opcode = 4'd13; // vv_ssub  -> OP_VSSUB
                                  valu_unsign = 1'b0;
          end                                  
          16'b0000000000000100  : valu_opcode = 4'd5;  // vv_sll   -> OP_SLL
          16'b0000000000000010  : valu_opcode = 4'd6;  // vv_srl   -> OP_SRL
          16'b0000000000000001  : begin
                                  valu_opcode = 4'd7;  // vv_sra   -> OP_SRA
                                  valu_unsign = 1'b0;
          end                                  
          default               : valu_opcode = 4'd0;
        endcase
      end
      else if (is_vi) begin
        unique case (vitype)
          10'b1000000000        : begin
                                  valu_opcode = 4'd1;  // vi_add   -> OP_ADD
                                  valu_unsign = 1'b0;
          end
          10'b0100000000        : begin
                                  valu_opcode = 4'd0;  // vi_rsub  -> OP_SUB (*)
                                  valu_unsign = 1'b0;
          end
          10'b0010000000        : valu_opcode = 4'd4;  // vi_and   -> OP_AND
          10'b0001000000        : valu_opcode = 4'd3;  // vi_or    -> OP_OR
          10'b0000100000        : valu_opcode = 4'd2;  // vi_xor   -> OP_XOR
          10'b0000010000        : valu_opcode = 4'd14; // vi_saddu -> OP_VSADD
          10'b0000001000        : begin
                                  valu_opcode = 4'd14; // vi_sadd  -> OP_VSADD
                                  valu_unsign = 1'b0;
          end                                  
          10'b0000000100        : valu_opcode = 4'd5;  // vi_sll   -> OP_SLL
          10'b0000000010        : valu_opcode = 4'd6;  // vi_srl   -> OP_SRL
          10'b0000000001        : begin
                                  valu_opcode = 4'd7;  // vi_sra   -> OP_SRA
                                  valu_unsign = 1'b0;
          end                                  
          default               : valu_opcode = 4'd0;
        endcase
      end
    end
    //==================================SIGNAL===============================================
    if(is_vsetvli) begin
      valu_opcode = 4'd10;   // vv_minu  -> OP_MINU
      vop1_sel    = 2'b00;   // rs1
      valu_unsign = 1'b1;
    end else if (vxtype) begin
      vop1_sel    = 2'b00;   // rs1
    end else if (vvtype) begin
      vop1_sel    = 2'b01;   // vs1
    end else if (vitype) begin
      vop1_sel    = 2'b10;   // imm
    end else if (inst[6:0] == VLOAD) begin
      vector_wb   = 1'b1;
      vop1_sel    = 2'b00;   // rs1
    end else if (inst[6:0] == VSTORE) begin
      vector_wb   = 1'b0;
      vop1_sel    = 2'b00;   // rs1
    end
  end

endmodule