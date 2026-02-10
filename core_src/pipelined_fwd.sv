//===========================================================================================================
// Project         : PIPELINED Model Forwarding of RISV - V
// Module          : PIPELINED Model Forwarding
// File            : pipelined_fwd.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 10/11/2025
// Updated date    : 11/12/2025 - Finished
//=============================================================================================================
import package_param::*;
module pipelined_fwd (
  input  wire        i_clk,
  input  wire        i_reset,

  input  wire [31:0] i_io_sw,

  output reg  [31:0] o_io_ledr,
  output reg  [31:0] o_io_ledg,

  output reg  [31:0] o_io_lcd,

  output reg  [6:0]  o_io_hex0,
  output reg  [6:0]  o_io_hex1,
  output reg  [6:0]  o_io_hex2,
  output reg  [6:0]  o_io_hex3,
  output reg  [6:0]  o_io_hex4,
  output reg  [6:0]  o_io_hex5,
  output reg  [6:0]  o_io_hex6,
  output reg  [6:0]  o_io_hex7,

  output reg         o_ctrl,    // neu la lenh branch or jmp thi = 1
  output reg         o_mispred,
  output reg  [31:0] o_pc_debug,
  output reg         o_insn_vld
);
//==================Declaration=======================================================================================================
  reg   [31:0]  inst_if;
  reg   [31:0]  next_pc;
  reg   [31:0]  pc_if;
  reg   [31:0]  pc4_wb;
  reg   [31:0]  pc_wb;
  reg   [31:0]  jmp_pc;
  reg   [31:0]  pc_imm;
  reg   [31:0]  mem_forward_data;
  wire  [31:0]  pc_plus4;
  wire  [3:0]   alu_op;
  reg           pc_src;
  reg           jmp_check;
  reg           op1_sel;
  wire          op2_sel;
  wire          branch_signal;
  wire          jmp_signal;
  wire          rd_wren;
  wire          mem_wren;
  wire          mem_rden;
  wire          mem_to_reg;
  wire          br_unsign;
  wire          br_less;
  wire          br_equal;
  wire  [31:0]  rs2_data;
  wire  [31:0]  op2;
  wire  [31:0]  imm_ex;
  wire  [31:0]  rs1_data;
  reg   [31:0]  op1;
  reg   [31:0]  rs1;
  reg   [31:0]  op1_forward;
  reg   [31:0]  op2_forward;
  reg   [31:0]  wb_data_o;
  reg   [31:0]  rd_data_o;
  reg   [31:0]  wr_data;
  reg   [31:0]  read_data;
  reg   [31:0]  mem           [0:8095];   //8kB
//=================PIPELINE_REGISTER========================================================================================================================
  if_id_reg_t  if_id_reg, if_id_next;     // next: incoming data; reg: present data
  id_ex_reg_t  id_ex_reg, id_ex_next;
  ex_mem_reg_t ex_mem_reg, ex_mem_next;
  mem_wb_reg_t mem_wb_reg, mem_wb_next;

  reg [31:0] inst_id_debug;
  reg [31:0] pc_id_debug;

  reg [31:0] inst_ex_debug;
  reg [31:0] pc_ex_debug;
  reg [31:0] rs2_ex_debug;
  reg [31:0] rs1_ex_debug;
  reg [31:0] imm_ex_debug;

  reg [31:0] inst_mem_debug;
  reg [31:0] pc_mem_debug;
  reg [31:0] rs2_mem_debug;
  reg [31:0] alu_mem_debug;
  reg [31:0] inst_wb_debug;

  reg [31:0] pc4_wb_debug;
  reg [31:0] alu_wb_debug;
  reg [31:0] memdata_wb_debug;

  reg        if_reg_enb;
  reg        id_reg_enb;
  reg        ex_reg_enb;
  reg        mem_reg_enb;
  reg        wb_reg_enb;
  reg        flush_en;
  reg        stall_en;
  reg        if_valid;
  reg        if_id_valid;
  reg        id_ex_valid;
  reg        ex_mem_valid;
  reg        mem_wb_valid;
  reg [1:0]  rs1_forwarding_sel;
  reg [1:0]  rs2_forwarding_sel;
//==================PC=================================================================================================================================
  always_ff @(posedge i_clk) begin: if_pc_reg
    if (~i_reset) begin
        pc_if <= 32'b0;
    end else if (if_reg_enb) begin
        pc_if <= next_pc;
    end
  end

  pc_reg PCplus4 (
    .pc_reg(pc_if),
    .op(32'd4),
    .pc_o(pc_plus4)
  );

  assign next_pc = (pc_src) ? jmp_pc : pc_plus4; // jmp_pc = id_ex_reg.alu_result
//==================IMEM=============================================================================================================================
  initial begin : instruction
    $readmemh("../01_tb/isa_4b.hex", mem);
  end

  assign inst_if = mem[pc_if[31:2]];
  assign if_valid = 1'b1;

//==================STALL_CONTROL===============================================================================================================================================================================================================
  always_comb begin : stall_detect
    stall_en = 1'b0;
    flush_en = pc_src;
    if(~flush_en) begin
    // Load-Use Hazard
      if(id_ex_reg.mem_rden && (id_ex_reg.inst[`RD_ADDR] != 5'b0) && 
        ((id_ex_reg.inst[`RD_ADDR] == if_id_reg.inst[`RS1_ADDR]) || (id_ex_reg.inst[`RD_ADDR] == if_id_reg.inst[`RS2_ADDR]))) begin
          stall_en = 1'b1;
      end
    end
  end
  //==================REGISTER_ENB=================================================================================================================================
    always_comb begin : reg_enb
      if_reg_enb  = 1'b1;
      id_reg_enb  = 1'b1;
      ex_reg_enb  = 1'b1;
      mem_reg_enb = 1'b1;
      wb_reg_enb  = 1'b1;
      if(stall_en) begin
        if_reg_enb  = 1'b0;
        id_reg_enb  = 1'b0;
      end
    end
//==================FORWARDING_CONTROL===========================================================================================================================
always_comb begin : forwarding_detect
    rs1_forwarding_sel = 2'b00;
    rs2_forwarding_sel = 2'b00;

    if (ex_mem_reg.rd_wren && (ex_mem_reg.rd_addr != 5'b0) && (ex_mem_reg.rd_addr == id_ex_reg.rs1_addr)) begin
      rs1_forwarding_sel = 2'b10;
    end else if (mem_wb_reg.rd_wren && (mem_wb_reg.rd_addr != 5'b0) && (mem_wb_reg.rd_addr == id_ex_reg.rs1_addr)) begin
      rs1_forwarding_sel = 2'b01;
    end

    if (ex_mem_reg.rd_wren && (ex_mem_reg.rd_addr != 5'b0) && (ex_mem_reg.rd_addr == id_ex_reg.rs2_addr)) begin
      rs2_forwarding_sel = 2'b10;
    end else if (mem_wb_reg.rd_wren && (mem_wb_reg.rd_addr != 5'b0) && (mem_wb_reg.rd_addr == id_ex_reg.rs2_addr)) begin
      rs2_forwarding_sel = 2'b01;
    end
  end

//==================ID_STAGE========================================================================================================================
//==================PC_ID_REGISTER========================================================================================================================
  always_comb begin: if_id_input
    if_id_next.inst = inst_if;
    if_id_next.pc   = pc_if;
  end

  always_ff @( posedge i_clk ) begin : if_id_register
    if(~i_reset || flush_en) begin
      if_id_reg.inst <= 32'b0;
      if_id_reg.pc   <= 32'b0;
      if_id_valid    <= 1'b0;
    end else if (id_reg_enb) begin
      if_id_reg.inst <= if_id_next.inst;
      if_id_reg.pc   <= if_id_next.pc;
      if_id_valid    <= if_valid;
    end
  end

  always_comb begin: if_id_debug
    inst_id_debug = if_id_reg.inst;
    pc_id_debug   = if_id_reg.pc;
  end
//==================REGFILE============================================================================================================================
  regfile regfile_id (
    .i_clk      (i_clk                    ),
    .i_reset    (i_reset                  ),
    .i_rs1_addr (if_id_reg.inst[`RS1_ADDR]),
    .i_rs2_addr (if_id_reg.inst[`RS2_ADDR]),
    .i_rd_addr  (mem_wb_reg.inst[`RD_ADDR]),
    .i_rd_data  (wb_data_o                ),
    .i_rd_wren  (mem_wb_reg.rd_wren       ),
    .o_rs1_data (rs1_data                 ),
    .o_rs2_data (rs2_data                 )
  );
//==================CONTROL_UNIT=========================================================================================================================
  control_unit  control_unit (
    .inst         (if_id_reg.inst),
    .o_ctrl       (o_ctrl        ),
    .br_unsign    (br_unsign     ),
    .op1_sel      (op1_sel       ),
    .op2_sel      (op2_sel       ),
    .branch_signal(branch_signal ),
    .jmp_signal   (jmp_signal    ),
    .mem_to_reg   (mem_to_reg    ),
    .alu_opcode   (alu_op        ),
    .rd_wren      (rd_wren       ),
    .mem_wren     (mem_wren      ),
    .mem_rden     (mem_rden      )
  );
//==================IMMGEN==================================================================================================================================
  immgen immgen (
    .inst_i (if_id_reg.inst),
    .imm_o  (imm_ex        )
  );

//==================EX_STAGE========================================================================================================================
  always_comb begin: input_ex_stage_reg
    // data
    id_ex_next.inst          = if_id_reg.inst;
    id_ex_next.pc            = if_id_reg.pc;
    id_ex_next.rs1_data      = rs1_data;
    id_ex_next.rs2_data      = rs2_data;
    id_ex_next.imm_ext       = imm_ex;
    // addr
    id_ex_next.rs1_addr      = if_id_reg.inst[`RS1_ADDR];
    id_ex_next.rs2_addr      = if_id_reg.inst[`RS2_ADDR];
    id_ex_next.rd_addr       = if_id_reg.inst[`RD_ADDR];
    // signal control
    id_ex_next.alu_opcode    = alu_op;
    id_ex_next.op1_sel       = op1_sel;
    id_ex_next.op2_sel       = op2_sel;
    id_ex_next.br_unsign     = br_unsign;
    id_ex_next.mem_wren      = mem_wren;
    id_ex_next.mem_rden      = mem_rden;
    id_ex_next.branch_signal = branch_signal;
    id_ex_next.jmp_signal    = jmp_signal;
    id_ex_next.rd_wren       = rd_wren;
    id_ex_next.mem_to_reg    = mem_to_reg;
  end

  always_ff @( posedge i_clk ) begin : id_ex_register
    if(~i_reset || flush_en || stall_en) begin
      id_ex_reg <= '0;
      id_ex_valid <= 1'b0;
    end else if (ex_reg_enb) begin
      id_ex_reg <= id_ex_next;
      id_ex_valid <= if_id_valid;
    end
  end

  always_comb begin: id_ex_debug
    inst_ex_debug = id_ex_reg.inst;
    pc_ex_debug   = id_ex_reg.pc;
    rs1_ex_debug  = id_ex_reg.rs1_data;
    rs2_ex_debug  = id_ex_reg.rs2_data;
    imm_ex_debug  = id_ex_reg.imm_ext;
  end
//==================FORWARDING_MUX===========================================================================================================================
  always_comb begin : forwarding_mux
    if(id_ex_reg.inst[`OPCODE] == U1TYPE) begin
      rs1 = 32'b0;
    end else begin
      rs1 = id_ex_reg.rs1_data;
    end

    case (rs1_forwarding_sel)
      2'b00:   op1_forward = rs1;
      2'b01:   op1_forward = wb_data_o; 
      2'b10:   op1_forward = ex_mem_reg.alu_result;
      default: op1_forward = 32'b0;
    endcase

    case (rs2_forwarding_sel)
      2'b00:   op2_forward = id_ex_reg.rs2_data;
      2'b01:   op2_forward = wb_data_o; 
      2'b10:   op2_forward = ex_mem_reg.alu_result;
      default: op2_forward = 32'b0;
    endcase
  end
//==================OPERATION_1_MUX===========================================================================================================================
  assign op1 = (id_ex_reg.op1_sel) ? id_ex_reg.pc : op1_forward;
//==================OPERATION_2_MUX===========================================================================================================================
  assign op2 = (id_ex_reg.op2_sel) ? id_ex_reg.imm_ext : op2_forward;
//==================ALU=====================================================================================================================================
  alu alu (
    .i_op_a      (op1                 ),
    .i_op_b      (op2                 ),
    .br_unsign_i (id_ex_reg.br_unsign ),
    .i_alu_op    (id_ex_reg.alu_opcode),
    .o_alu_data  (rd_data_o           )
  );

//==================BRCOMP=============================================================================================================================
  brcomp branch_compare (
    .i_rs1_data (op1_forward        ),
    .i_rs2_data (op2_forward        ),
    .i_br_un    (id_ex_reg.br_unsign),
    .o_br_less  (br_less            ),
    .o_br_equal (br_equal           )
  );
//==================PC_SRC=============================================================================================================================
  always_comb begin : pc_src_check
    case (id_ex_reg.inst[`FUNC3])
      3'b000: jmp_check =  br_equal;                         // beq
      3'b001: jmp_check = ~br_equal;                         // bne
      3'b100: jmp_check =  br_less;                          // blt
      3'b101: jmp_check = ~br_less || br_equal;              // bge > or =
      3'b110: jmp_check =  br_less && br_unsign;             // bltu
      3'b111: jmp_check = (~br_less || br_equal) && br_unsign; // bgeu
      default:jmp_check = 1'b0;
    endcase
    pc_src    = (jmp_check && id_ex_reg.branch_signal) || id_ex_reg.jmp_signal; // branch is condition jmp, jmp is unconditon so invert the condition
    o_mispred = flush_en; 
  end
//==================PC_ADDER=====================================================================================================================================
  pc_reg pc_adder_imm (
    .pc_reg(id_ex_reg.pc),
    .op    (id_ex_reg.imm_ext),
    .pc_o  (pc_imm)

  );
  always_comb begin : jalr_case
    if(id_ex_reg.inst[`OPCODE] == IITYPE) begin
      jmp_pc = rd_data_o;    // pc = rs1 + imm
    end else begin
      jmp_pc = pc_imm;
    end
  end
//==================MEM_STAGE========================================================================================================================
  always_comb begin: input_mem_stage_reg
    // data
    ex_mem_next.inst          = id_ex_reg.inst;
    ex_mem_next.pc            = id_ex_reg.pc;
    ex_mem_next.rs2_data      = op2_forward;
    ex_mem_next.alu_result    = rd_data_o;
    // addr
    ex_mem_next.rd_addr       = id_ex_reg.inst[`RD_ADDR];
    // signal control
    ex_mem_next.mem_wren      = id_ex_reg.mem_wren;
    ex_mem_next.mem_rden      = id_ex_reg.mem_rden;
    ex_mem_next.branch_signal = id_ex_reg.branch_signal;
    ex_mem_next.jmp_signal    = id_ex_reg.jmp_signal;
    ex_mem_next.rd_wren       = id_ex_reg.rd_wren;
    ex_mem_next.mem_to_reg    = id_ex_reg.mem_to_reg;
  end

  always_ff @( posedge i_clk ) begin : ex_mem_register
    if(~i_reset) begin
      ex_mem_reg   <= '0;
      ex_mem_valid <= 1'b0;
    end else if (mem_reg_enb) begin
      ex_mem_reg   <= ex_mem_next;
      ex_mem_valid <= id_ex_valid;
    end
  end

  always_comb begin: ex_mem_debug
    inst_mem_debug = ex_mem_reg.inst;
    pc_mem_debug   = ex_mem_reg.pc;
    rs2_mem_debug  = op2_forward;
    alu_mem_debug  = ex_mem_reg.alu_result;
  end
//==================LSU=====================================================================================================================================
  always_comb begin
  // has rs2's data if stype to store rs2's data to mem
    wr_data  = 32'b0;
    if(ex_mem_reg.inst[`OPCODE] == STYPE) begin
      wr_data = ex_mem_reg.rs2_data;
      end
      case (ex_mem_reg.inst[`FUNC3])                            // check func3
        3'b000,
        3'b100:   wr_data = wr_data & 32'h000000FF;
        3'b001,
        3'b101:   wr_data = wr_data & 32'h0000FFFF;
        3'b010:   wr_data = wr_data & 32'hFFFFFFFF;
        3'b100:   wr_data = wr_data & 32'h000000FF;
        3'b101:   wr_data = wr_data & 32'h0000FFFF;
        default : wr_data = wr_data & 32'hFFFFFFFF;
      endcase
  end

  lsu lsu (
    .i_clk      (i_clk                  ),
    .i_reset    (i_reset                ),
    .i_lsu_addr (ex_mem_reg.alu_result  ),
    .i_st_data  (wr_data                ),
    .i_lsu_wren (ex_mem_reg.mem_wren    ),
    .i_lsu_rden (ex_mem_reg.mem_rden    ),
    .i_func3    (ex_mem_reg.inst[`FUNC3]),
    .i_io_sw    (i_io_sw                ),
    .o_io_hex0  (o_io_hex0              ),
    .o_io_hex1  (o_io_hex1              ),
    .o_io_hex2  (o_io_hex2              ),
    .o_io_hex3  (o_io_hex3              ),
    .o_io_hex4  (o_io_hex4              ),
    .o_io_hex5  (o_io_hex5              ),
    .o_io_hex6  (o_io_hex6              ),
    .o_io_hex7  (o_io_hex7              ),
    .o_ld_data  (read_data              ),
    .o_io_ledr  (o_io_ledr              ),
    .o_io_ledg  (o_io_ledg              ),
    .o_io_lcd   (o_io_lcd               )
  );

//==================WB_STAGE========================================================================================================================
  pc_reg PC_wb_plus4 (
    .pc_reg(ex_mem_reg.pc),
    .op    (32'd4),
    .pc_o  (pc4_wb)
  );
  always_comb begin: input_wb_stage_reg
    // data
    mem_wb_next.inst          = ex_mem_reg.inst;
    mem_wb_next.pc4           = pc4_wb;
    mem_wb_next.rs2_data      = ex_mem_reg.rs2_data;
    mem_wb_next.alu_result    = ex_mem_reg.alu_result;
    // addr
    mem_wb_next.rd_addr       = ex_mem_reg.inst[`RD_ADDR];
    // signal control
    mem_wb_next.rd_wren       = ex_mem_reg.rd_wren;
    mem_wb_next.mem_to_reg    = ex_mem_reg.mem_to_reg;
  end

  always_ff @( posedge i_clk) begin : mem_wb_register
    if(~i_reset) begin
      mem_wb_reg   <= '0;
      mem_wb_valid <= 1'b0;
    end else if (wb_reg_enb) begin
      mem_wb_reg   <= mem_wb_next;
      mem_wb_valid <= ex_mem_valid;
    end
  end

  always_comb begin: mem_wb_debugger
    inst_wb_debug    = mem_wb_reg.inst;
    pc4_wb_debug     = mem_wb_reg.pc4;
    alu_wb_debug     = mem_wb_reg.alu_result;
  end
//==================WRITEBACK=============================================================================================================================
  always_comb begin : write_back
    if(mem_wb_reg.inst[`RD_ADDR] == 5'b00000) begin
      wb_data_o = 32'b0;
    end else if (mem_wb_reg.inst[`OPCODE] == IITYPE || mem_wb_reg.inst[`OPCODE] == IJTYPE) begin
      wb_data_o = mem_wb_reg.pc4;
    end else if (mem_wb_reg.mem_to_reg) begin
      wb_data_o = read_data;
    end else if (~mem_wb_reg.mem_to_reg) begin
      wb_data_o = mem_wb_reg.alu_result;
    end
  end

  pc_minus PC_wb_minus4 (
    .pc_reg(mem_wb_reg.pc4),
    .op    (32'd4),
    .pc_o  (pc_wb)
  );

  assign o_insn_vld = mem_wb_valid;
  assign o_pc_debug = (o_insn_vld) ? pc_wb : 32'b0;
endmodule
