//===========================================================================================================
// Project         : UART & RVV
// Module          : Vector Control Unit
// File            : vector_control.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 04/03/2025
// Updated date    : 24/03/2026
//============================================================================================================
import package_param::*;
module vector_control (
  input  wire [31:0] inst,
	input  wire        vector_enb,
	input  wire [4:0]  id_vrs1_addr,
	input  wire [4:0]  id_vrs2_addr,
	input  wire [4:0]  ex_vrs1_addr,
	input  wire [4:0]  ex_vrs2_addr,
	input  wire [4:0]  ex_vrd_addr,
	input  wire [4:0]  ex_mem_vrden,
	input  wire [4:0]  mem_vrd_addr,
	input  wire [4:0]  mem_vrd_wren,
	input  wire [4:0]  wb_vrd_addr,
	input  wire [4:0]  wb_vrd_wren,
	input  wire [4:0]  valu_opcode,
	output reg  [1:0]  vrs1_forwarding_sel,
	output reg  [1:0]  vrs2_forwarding_sel,
	output reg         vector_stall
);
//========================DECLEARATION===============================================================================
  wire is_vx, vx_add, vx_sub, vx_rsub, vx_min, vx_max, vx_minu, vx_maxu, vx_and, vx_or, vx_xor, vx_sadd, vx_ssub, vx_ssubu, vx_saddu, vx_sll, vx_srl, vx_sra;
  wire is_vv, vv_add, vv_sub, vv_min, vv_max, vv_minu, vv_maxu, vv_and, vv_or, vv_xor, vv_sadd, vv_ssub, vv_ssubu, vv_saddu, vv_sll, vv_srl, vv_sra;
  wire is_vi, vi_add, vi_and, vi_or, vi_xor, vi_sadd, vi_saddu, vi_sll, vi_srl, vi_sra;
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
//========================VECTOR OPCODE===============================================================================
  always_comb begin : inst_vector_decode
    valu_opcode = 4'b0000; 
    if (vector_enb) begin 
      if (is_vx) begin
        case (vxtype)
          17'b10000000000000000 : valu_opcode = 4'd1;  // vx_add   -> OP_ADD
          17'b01000000000000000 : valu_opcode = 4'd0;  // vx_sub   -> OP_SUB
          17'b00100000000000000 : valu_opcode = 4'd0;  // vx_rsub  -> OP_SUB (*)
          17'b00010000000000000 : valu_opcode = 4'd10; // vx_minu  -> OP_MINU
          17'b00001000000000000 : valu_opcode = 4'd8;  // vx_min   -> OP_MIN
          17'b00000100000000000 : valu_opcode = 4'd11; // vx_maxu  -> OP_MAXU
          17'b00000010000000000 : valu_opcode = 4'd9;  // vx_max   -> OP_MAX
          17'b00000001000000000 : valu_opcode = 4'd4;  // vx_and   -> OP_AND
          17'b00000000100000000 : valu_opcode = 4'd3;  // vx_or    -> OP_OR
          17'b00000000010000000 : valu_opcode = 4'd2;  // vx_xor   -> OP_XOR
          17'b00000000001000000 : valu_opcode = 4'd14; // vx_saddu -> OP_VSADD
          17'b00000000000100000 : valu_opcode = 4'd14; // vx_sadd  -> OP_VSADD
          17'b00000000000010000 : valu_opcode = 4'd13; // vx_ssubu -> OP_VSSUB
          17'b00000000000001000 : valu_opcode = 4'd13; // vx_ssub  -> OP_VSSUB
          17'b00000000000000100 : valu_opcode = 4'd5;  // vx_sll   -> OP_SLL
          17'b00000000000000010 : valu_opcode = 4'd6;  // vx_srl   -> OP_SRL
          17'b00000000000000001 : valu_opcode = 4'd7;  // vx_sra   -> OP_SRA
          default               : valu_opcode = 4'd0;
        endcase
      end
      else if (is_vv) begin
        case (vvtype)
          16'b1000000000000000  : valu_opcode = 4'd1;  // vv_add   -> OP_ADD
          16'b0100000000000000  : valu_opcode = 4'd0;  // vv_sub   -> OP_SUB
          16'b0010000000000000  : valu_opcode = 4'd10; // vv_minu  -> OP_MINU
          16'b0001000000000000  : valu_opcode = 4'd8;  // vv_min   -> OP_MIN
          16'b0000100000000000  : valu_opcode = 4'd11; // vv_maxu  -> OP_MAXU
          16'b0000010000000000  : valu_opcode = 4'd9;  // vv_max   -> OP_MAX
          16'b0000001000000000  : valu_opcode = 4'd4;  // vv_and   -> OP_AND
          16'b0000000100000000  : valu_opcode = 4'd3;  // vv_or    -> OP_OR
          16'b0000000010000000  : valu_opcode = 4'd2;  // vv_xor   -> OP_XOR
          16'b0000000001000000  : valu_opcode = 4'd14; // vv_saddu -> OP_VSADD
          16'b0000000000100000  : valu_opcode = 4'd14; // vv_sadd  -> OP_VSADD
          16'b0000000000010000  : valu_opcode = 4'd13; // vv_ssubu -> OP_VSSUB
          16'b0000000000001000  : valu_opcode = 4'd13; // vv_ssub  -> OP_VSSUB
          16'b0000000000000100  : valu_opcode = 4'd5;  // vv_sll   -> OP_SLL
          16'b0000000000000010  : valu_opcode = 4'd6;  // vv_srl   -> OP_SRL
          16'b0000000000000001  : valu_opcode = 4'd7;  // vv_sra   -> OP_SRA
          default               : valu_opcode = 4'd0;
        endcase
      end
      else if (is_vi) begin
        case (vitype)
          10'b1000000000        : valu_opcode = 4'd1;  // vi_add   -> OP_ADD
          10'b0100000000        : valu_opcode = 4'd0;  // vi_rsub  -> OP_SUB (*)
          10'b0010000000        : valu_opcode = 4'd4;  // vi_and   -> OP_AND
          10'b0001000000        : valu_opcode = 4'd3;  // vi_or    -> OP_OR
          10'b0000100000        : valu_opcode = 4'd2;  // vi_xor   -> OP_XOR
          10'b0000010000        : valu_opcode = 4'd14; // vi_saddu -> OP_VSADD
          10'b0000001000        : valu_opcode = 4'd14; // vi_sadd  -> OP_VSADD
          10'b0000000100        : valu_opcode = 4'd5;  // vi_sll   -> OP_SLL
          10'b0000000010        : valu_opcode = 4'd6;  // vi_srl   -> OP_SRL
          10'b0000000001        : valu_opcode = 4'd7;  // vi_sra   -> OP_SRA
          default               : valu_opcode = 4'd0;
        endcase
      end
    end
  end
//========================HAZARD=====================================================================================
	always_comb begin : vector_stall_detect
    vector_stall = 1'b0;
    // Load-Use Hazard
      if(ex_mem_vrden && (ex_vrd_addr != 5'b0) && 
        ((ex_vrd_addr == id_vrs1_addr) || 
				 (ex_vrd_addr == id_vrs2_addr))) begin
          vector_stall = 1'b1;
  		end
end
//==================FORWARDING_CONTROL===========================================================================================================================
	always_comb begin : vector_forwarding_detect
    vrs1_forwarding_sel = 2'b00;
    vrs2_forwarding_sel = 2'b00;

    if (mem_vrd_wren && (mem_vrd_addr != 5'b0) && (mem_vrd_addr == ex_vrs1_addr)) begin
      vrs1_forwarding_sel = 2'b10;
    end else if (wb_vrd_wren && (wb_vrd_addr != 5'b0) && (wb_vrd_addr == ex_vrs1_addr)) begin
      vrs1_forwarding_sel = 2'b01;
    end

    if (mem_vrd_wren && (mem_vrd_addr != 5'b0) && (mem_vrd_addr == ex_vrs2_addr)) begin
      vrs2_forwarding_sel = 2'b10;
    end else if (wb_vrd_wren && (wb_vrd_addr != 5'b0) && (wb_vrd_addr == ex_vrs2_addr)) begin
      vrs2_forwarding_sel = 2'b01;
    end
  end
endmodule