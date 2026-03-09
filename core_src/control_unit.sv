//===========================================================================================================
// Project         : UART & RVV
// Module          : Control Unit
// File            : control_unit.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 12/12/2025
// Updated date    : 04/03/2026
//============================================================================================================
import package_param::*;
module control_unit (
  input  wire  [31:0] inst,
  output reg          o_ctrl,
  output reg          br_unsign,
  output reg          op1_sel,
  output reg          op2_sel,
  output reg          branch_signal,
  output reg          jmp_signal,
  output reg          mem_to_reg,
  output reg  [3:0]   alu_opcode,
  output reg          mem_rden,
  output reg          rd_wren,
  output reg          mem_wren
);
//===================================DECLARATION==================================================
  wire is_add, is_sub, is_and, is_or, is_xor, is_slt, is_sltu, is_sra, is_srl, is_sll, is_mul, is_mulh;
  wire is_addi, is_xori, is_ori, is_andi, is_slli, is_srli, is_srai, is_slti, is_sltiu;
  wire is_beq, is_bne, is_blt, is_bge, is_bltu, is_bgeu;
  wire [11:0] rtype;
  wire [8:0]  itype;
  wire [5:0]  btype;
//==========================RTYPE=========================================================================
  always_comb begin : inst_valid
    o_ctrl     = 1'b0;
    case(inst[`OPCODE])
      RTYPE,
      ITYPE,
      ILTYPE,
      U1TYPE,
      U2TYPE,
      STYPE: o_ctrl = 1'b0;
      BTYPE,
      IJTYPE,
      IITYPE: begin 
        o_ctrl     = 1'b1;
      end      
      default: begin
        o_ctrl = 1'b0;
      end
    endcase
  end
//==========================RTYPE=========================================================================
  //is_mul
  assign is_mul   = ~inst[12] & ~inst[13] & ~inst[14] & inst[25];
  //is_mulh
  assign is_mulh  =  inst[12] & ~inst[13] & ~inst[14] & inst[25];
  //is_add
  assign is_add   = ~inst[12] & ~inst[13] & ~inst[14] & ~inst[30];
  //is_sub
  assign is_sub   = ~inst[12] & ~inst[13] & ~inst[14] &  inst[30];
  //is_sll
  assign is_sll   =  inst[12] & ~inst[13] & ~inst[14];
  //is_slt
  assign is_slt   = ~inst[12] & inst[13]  & ~inst[14];
  //is_sltu
  assign is_sltu  =  inst[12] & inst[13]  & ~inst[14];
  //is_xor
  assign is_xor   = ~inst[12] & ~inst[13] &  inst[14];
  //is_sra
  assign is_sra   =  inst[12] & ~inst[13] &  inst[14]  &  inst[30];
  //is_srl
  assign is_srl   =  inst[12] & ~inst[13] &  inst[14]  & ~inst[30];
  //is_or
  assign is_or    = ~inst[12] & inst[13]  &  inst[14];
  //is_and
  assign is_and   =  inst[12] & inst[13]  &  inst[14];
  // concatenat
  assign rtype = {is_add, is_sub, is_sll, is_slt, is_sltu, is_xor, is_srl, is_sra, is_or, is_and, is_mul, is_mulh};
//==========================ITYPE=========================================================================
  //is_addi
  assign is_addi  = ~inst[12] & ~inst[13] & ~inst[14];
  //is_sll
  assign is_slli  =  inst[12] & ~inst[13] & ~inst[14];
  //is_slt
  assign is_slti  = ~inst[12] & inst[13]  & ~inst[14];
  //is_sltiu
  assign is_sltiu =  inst[12] & inst[13]  & ~inst[14];
  //is_xori
  assign is_xori  = ~inst[12] & ~inst[13] &  inst[14];
  //is_srai
  assign is_srai  =  inst[12] & ~inst[13] &  inst[14]  & inst[30];
  //is_srli
  assign is_srli  =  inst[12] & ~inst[13] &  inst[14]  & ~inst[30];
  //is_ori
  assign is_ori   = ~inst[12] & inst[13]  &  inst[14];
  //is_andi
  assign is_andi  =  inst[12] & inst[13]  &  inst[14];
  // concat
  assign itype = {is_addi, is_slli, is_slti, is_sltiu, is_xori, is_srli, is_srai, is_ori, is_andi};
//==========================BTYPE=========================================================================
  //is_beq
  assign is_beq  = ~inst[12] & ~inst[13] & ~inst[14];
  //is_bne
  assign is_bne  =  inst[12] & ~inst[13] & ~inst[14];
   //is_blt
  assign is_blt  = ~inst[12] & ~inst[13] &  inst[14];
  //is_bge
  assign is_bge  =  inst[12] & ~inst[13] &  inst[14];
  //is_bltu
  assign is_bltu = ~inst[12] & inst[13]  &  inst[14];
  //is_bgeu
  assign is_bgeu =  inst[12] & inst[13]  &  inst[14];
  // concat
  assign btype = {is_beq, is_bne, is_blt, is_bge, is_bltu, is_bgeu};
//==========================alu_opcode=========================================================================
  always_comb begin : signal_sel
    br_unsign   = 1'b1;
    mem_to_reg  = 1'b0;
    case (inst[`OPCODE])
      RTYPE: case (rtype)
              12'b100000000000 : alu_opcode = 4'b0000;  // add
              12'b010000000000 : alu_opcode = 4'b0001;  // sub
              12'b001000000000 : alu_opcode = 4'b0010;  // sll
              12'b000100000000 : alu_opcode = 4'b0011;  // slt
              12'b000010000000 : alu_opcode = 4'b0100;  // sltu
              12'b000001000000 : alu_opcode = 4'b0101;  // xor
              12'b000000100000 : alu_opcode = 4'b0110;  // srl
              12'b000000010000 : alu_opcode = 4'b0111;  // sra
              12'b000000001000 : alu_opcode = 4'b1000;  // or
              12'b000000000100 : alu_opcode = 4'b1001;  // and
              12'b000000000010 : alu_opcode = 4'b1010;  // mul
              12'b000000000001 : alu_opcode = 4'b1011;  // mulh
              default          : alu_opcode = 4'b0000;
            endcase
      ITYPE: case (itype)
              9'b100000000   : begin
                               alu_opcode = 4'b0000;   // addi
                               br_unsign  = 1'b0;
              end
              9'b010000000   : alu_opcode = 4'b0010;  // slli
              9'b001000000   : alu_opcode = 4'b0011;  // slti
              9'b000100000   : alu_opcode = 4'b0100;  // sltiu
              9'b000010000   : alu_opcode = 4'b0101;  // xori
              9'b000001000   : alu_opcode = 4'b0110;  // srli
              9'b000000100   : begin
                               alu_opcode = 4'b0111;                 // is_srai
                               br_unsign  = 1'b0;
              end
              9'b000000010   : alu_opcode = 4'b1000;   // ori
              9'b000000001   : alu_opcode = 4'b1001;   // andi
              default        : alu_opcode = 4'b0000;
            endcase
      ILTYPE,
      STYPE:                   alu_opcode = 4'b0000;    // alu using add
      BTYPE: case (btype)
              6'b100000  : begin                       // beq
                               alu_opcode = 4'b0000;
                               br_unsign = 1'b0;
                end
              6'b010000 : begin                        // bne
                               alu_opcode = 4'b0000;
                               br_unsign = 1'b0;
                end
              6'b001000 : begin                        // blt
                               alu_opcode = 4'b0000;
                               br_unsign = 1'b0;
                end
              6'b000100: begin                         // bge
                               alu_opcode = 4'b0000;
                               br_unsign = 1'b0;
                end
              6'b000010: begin
                               alu_opcode = 4'b0000;         // bltu
                               br_unsign  = 1'b1;
                end
              6'b000001: begin
                               alu_opcode = 4'b0000;
                               br_unsign  = 1'b1;
                end
              default  :       alu_opcode = 4'b0000;
            endcase
      IJTYPE:                  alu_opcode = 4'b0000;
      IITYPE:                  alu_opcode = 4'b0000;
      U1TYPE:                  alu_opcode = 4'b0000;         // lui using imm + 0
      U2TYPE:                  alu_opcode = 4'b0000;         // auipc using pc + imm
      default:                 alu_opcode = 4'b0000;
    endcase
//==================================WRITE_BACK===============================================
  case (inst[`OPCODE])
    RTYPE: begin                     // opcode rd, r1, r2
      mem_to_reg    = 1'b0;  // alu_result
      op1_sel       = 1'b0;  //rs1
      op2_sel       = 1'b0;  //rs2;
      mem_wren      = 1'b0;
      mem_rden      = 1'b0;
      rd_wren       = 1'b1;
      branch_signal = 1'b0;
      jmp_signal    = 1'b0;
    end
    ITYPE: begin
      mem_to_reg    = 1'b0;  // alu_result
      op1_sel       = 1'b0;  // rs1
      op2_sel       = 1'b1;  // imm
      mem_wren      = 1'b0;
      mem_rden      = 1'b0;
      rd_wren       = 1'b1;
      branch_signal = 1'b0;
      jmp_signal    = 1'b0;
    end
    ILTYPE: begin
      mem_to_reg    = 1'b1;  // read_data
      op1_sel       = 1'b0;  // rs1
      op2_sel       = 1'b1;  // imm_ex;
      mem_wren      = 1'b0;
      mem_rden      = 1'b1;
      rd_wren       = 1'b1;
      branch_signal = 1'b0;
      jmp_signal    = 1'b0;
    end
    BTYPE: begin
      mem_to_reg    = 1'b0;  // no access to wb
      op1_sel       = 1'b1;  // pc
      op2_sel       = 1'b1;  // imm
      mem_wren      = 1'b0;
      mem_rden      = 1'b0;
      rd_wren       = 1'b0;
      branch_signal = 1'b1;
      jmp_signal    = 1'b0;
    end
    STYPE: begin
      mem_to_reg    = 1'b0;  // no access to wb
      op1_sel       = 1'b0;  // rs1
      op2_sel       = 1'b1;  // imm
      mem_wren      = 1'b1;
      mem_rden      = 1'b0;
      rd_wren       = 1'b0;
      branch_signal = 1'b0;
      jmp_signal    = 1'b0;
    end
    IJTYPE: begin
      mem_to_reg    = 1'b0;  // alu_result
      op1_sel       = 1'b1;  // pc
      op2_sel       = 1'b1;  // imm
      mem_wren      = 1'b0;
      mem_rden      = 1'b0;
      rd_wren       = 1'b1;
      branch_signal = 1'b0;
      jmp_signal    = 1'b1;
    end
    IITYPE: begin
      mem_to_reg    = 1'b0;  // alu_result
      op1_sel       = 1'b0;  // rs1
      op2_sel       = 1'b1;  // imm
      mem_wren      = 1'b0;
      mem_rden      = 1'b0;
      rd_wren       = 1'b1;
      branch_signal = 1'b0;
      jmp_signal    = 1'b1;
    end
    U1TYPE: begin
      mem_to_reg    = 1'b0;  // alu_result
      op1_sel       = 1'b0;  // rs1
      op2_sel       = 1'b1;  // imm
      mem_wren      = 1'b0;
      mem_rden      = 1'b0;
      rd_wren       = 1'b1;
      branch_signal = 1'b0;
      jmp_signal    = 1'b0;
    end
    U2TYPE: begin
      mem_to_reg    = 1'b0;  // alu_result
      op1_sel       = 1'b1;  // pc
      op2_sel       = 1'b1;  // imm
      mem_wren      = 1'b0;
      mem_rden      = 1'b0;
      rd_wren       = 1'b1;
      branch_signal = 1'b0;
      jmp_signal    = 1'b0;
    end
    default: begin
      mem_to_reg    = 1'b0;
      op1_sel       = 1'b0;
      op2_sel       = 1'b0;
      mem_wren      = 1'b0;
      mem_rden      = 1'b0;
      rd_wren       = 1'b0;
      branch_signal = 1'b0;
      jmp_signal    = 1'b0;
    end
  endcase
end
endmodule
