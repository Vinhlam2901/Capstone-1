//===========================================================================================================
// Project         : PIPELINED Model Forwarding of RISV - V
// Module          : PIPELINED Model Forwarding
// File            : pipelined_fwd.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 12/12/2025
// Updated date    : 12/04/2026
//=============================================================================================================
import package_param::*;
module pipelined_fwd (
  input  wire        i_clk,
  input  wire        i_reset,

  input  wire        i_uart_rx,
  input  wire [31:0] i_io_sw,

  output reg  [31:0] o_io_ledr,
  output reg  [31:0] o_io_ledg,

  output reg  [31:0] o_io_lcd,

  output reg         o_uart_tx,
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
  reg  [31:0]  imem               [0:50];
  //------------SCALAR_SIGNAL------------------------------------
  reg          pc_src;
  reg  [3:0]   alu_op_io;
  reg  [31:0]  inst_if;
  reg  [31:0]  pc_if;
  reg  [31:0]  next_pc;
  reg  [31:0]  pc_plus4;
  reg  [31:0]  pc_wb;
  reg  [31:0]  pc4_wb;
  reg  [31:0]  pc4_ex;
  reg  [31:0]  pc_imm;
  reg  [31:0]  jmp_pc;
  wire         branch_signal;
  wire         jmp_signal;
  reg          jmp_check;
  wire         scalar_wren;
  wire         mems_wren;
  wire         mems_rden;
  wire         scalar_wb;
  wire         br_unsign;
  wire         br_less; 
  wire         br_equal;
  wire         op2_sel;
  wire         op1_sel;
  wire [31:0] raw_inst;
  reg  [1:0]   rs1_forwarding_sel;
  reg  [1:0]   rs2_forwarding_sel;
  reg  [31:0]  rs1_data;
  reg  [31:0]  rs1;
  reg  [31:0]  rs2_data;
  reg  [31:0]  imm_ex;
  reg  [31:0]  op1_forward;
  reg  [31:0]  op2_forward;
  reg  [31:0]  op1;
  reg  [31:0]  op2;
  reg  [31:0]  rd_data_o;
  reg  [31:0]  wb_data_o;
  reg  [31:0]  mem_forward_data;
  reg  [31:0]  wr_data_scalar;
  reg  [31:0]  read_data_scalar;
  //------------VECTOR_SIGNAL------------------------------------
  wire         valu_unsign;
  wire         vector_wb;
  reg  [7:0]   vlen_enb;
  reg  [3:0]   valu_opcode;
  reg  [4:0]   vr2_sel;
  reg  [4:0]   ex_vr2_sel;
  reg  [1:0]   vop1_sel;
  reg  [1:0]   vrs1_forwarding_sel;
  reg  [1:0]   vrs2_forwarding_sel;
  reg  [31:0]  vlen_set;
  reg  [63:0]  vs1_data;
  reg  [63:0]  vs2_data;
  reg  [63:0]  vs3_data;
  reg  [63:0]  vop1;
  reg  [63:0]  vop2;
  reg  [63:0]  vimm_ex;
  reg  [63:0]  vop1_forward;
  reg  [63:0]  vop2_forward;
  reg  [63:0]  vrd_data_o;
  reg  [63:0]  read_data_vector;
  reg  [63:0]  wr_data_vector;
  reg  [63:0]  wb_vdata_o;
  //=================PIPELINE_REGISTER========================================================================================================================
  // next: incoming data; reg: present data
  if_id_reg_t  if_id_reg,  if_id_next;     
  id_ex_reg_t  id_ex_reg,  id_ex_next;
  ex_mem_reg_t ex_mem_reg, ex_mem_next;
  mem_wb_reg_t mem_wb_reg, mem_wb_next;

  reg [31:0] inst_id_debug;
  reg [31:0] pc_id_debug;

  reg [31:0] inst_ex_debug;
  reg [31:0] pc_ex_debug;
  reg [31:0] rs2_ex_debug;
  reg [31:0] rs1_ex_debug;
  reg [31:0] imm_ex_debug;

  reg [63:0] vrs1_ex_debug;
  reg [63:0] vrs2_ex_debug;
  reg [63:0] vrs3_ex_debug;
  reg [63:0] vimm_ex_debug;
  reg [1:0] vop1sl_ex_debug;

  reg [31:0] inst_mem_debug;
  reg [31:0] pc_mem_debug;
  reg [31:0] rs2_mem_debug;
  reg [31:0] alu_mem_debug;
  
  reg [63:0] valu_mem_debug;
  reg [63:0] vrs2_mem_debug;
  reg [7:0]  vlen_mem_debug;
  reg [7:0]  vlen_ex_debug;
  reg [7:0]  vlen_wb_debug;
  reg        scalar_wren_wb_debug;
  reg        vector_wren_ex_debug;
  reg        vector_wren_mem_debug;
  
  reg [31:0] inst_wb_debug;
  reg [31:0] pc4_wb_debug;
  reg [31:0] alu_wb_debug;
  reg [63:0] memdata_wb_debug;
  reg [31:0] rs2_debug;

  reg [63:0] valu_wb_debug;
  //----------CONTROL_SIGNAL--------------------------------------
  wire       flush;
  reg        vector_stall;
  reg        scalar_stall;
  wire       vector_enb;
  reg        if_reg_enb;
  reg        id_reg_enb;
  reg        ex_reg_enb;
  reg        mem_reg_enb;
  reg        wb_reg_enb;
  reg        if_valid;
  reg        if_id_valid;
  reg        id_ex_valid;
  reg        ex_mem_valid;
  reg        mem_wb_valid;

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
    .op    (32'd4),
    .pc_o  (pc_plus4)
  );

  assign next_pc = (pc_src) ? jmp_pc : pc_plus4; // jmp_pc = id_ex_reg.alu_result
  assign flush   = pc_src;
//==================IMEM=============================================================================================================================
  initial begin : instruction
    $readmemh("../02_sim/init_imem.hex", imem);
  end
  assign raw_inst = imem[pc_if[31:2]];
  assign inst_if = {raw_inst[7:0], raw_inst[15:8], raw_inst[23:16], raw_inst[31:24]};
  assign if_valid = 1'b1;

//==================STALL_CONTROL===============================================================================================================================================================================================================
  hazard_detect hazard (
                      .id_rs1_addr         (if_id_reg.inst[`RS1_ADDR] ),
                      .id_rs2_addr         (if_id_reg.inst[`RS2_ADDR] ),
                      .ex_rs1_addr         (id_ex_reg.inst[`RS1_ADDR] ),
                      .ex_rs2_addr         (id_ex_reg.inst[`RS2_ADDR] ),
                      .ex_rd_addr          (id_ex_reg.inst[`RD_ADDR]  ), 
                      .ex_mems_rden        (id_ex_reg.mems_rden       ),
                      .mem_rd_addr         (ex_mem_reg.inst[`RD_ADDR] ), 
                      .mem_scalar_wren     (ex_mem_reg.scalar_wren    ),
                      .wb_rd_addr          (mem_wb_reg.inst[`RD_ADDR] ), 
                      .wb_scalar_wren      (mem_wb_reg.scalar_wren    ),
                      .id_vrs1_addr        (if_id_reg.inst[`VS1_ADDR] ),
                      .id_vrs2_addr        (vr2_sel                   ),
                      .ex_vrs1_addr        (id_ex_reg.inst[`VS1_ADDR] ),
                      .ex_vrs2_addr        (ex_vr2_sel                ),
                      .ex_vrd_addr         (id_ex_reg.inst[`VRD_ADDR] ),
                      .ex_mem_vrden        (id_ex_reg.memv_rden       ),
                      .mem_vrd_addr        (ex_mem_reg.inst[`VRD_ADDR]),
                      .mem_vector_wren     (ex_mem_reg.vector_wren    ),
                      .wb_vrd_addr         (mem_wb_reg.inst[`VRD_ADDR]),
                      .wb_vector_wren      (mem_wb_reg.vector_wren    ),
                      .vrs1_forwarding_sel (vrs1_forwarding_sel       ),
                      .vrs2_forwarding_sel (vrs2_forwarding_sel       ),
                      .rs1_forwarding_sel  (rs1_forwarding_sel        ),
                      .rs2_forwarding_sel  (rs2_forwarding_sel        ),
                      .vector_stall        (vector_stall              ),
                      .scalar_stall        (scalar_stall              )
                  );

//==================REGISTER_ENB=================================================================================================================================
  always_comb begin : reg_enb
    if_reg_enb  = 1'b1;
    id_reg_enb  = 1'b1;
    ex_reg_enb  = 1'b1;
    mem_reg_enb = 1'b1;
    wb_reg_enb  = 1'b1;
    if(scalar_stall || vector_stall) begin
      if_reg_enb  = 1'b0;
      id_reg_enb  = 1'b0;
    end
    end
//==================ID_STAGE========================================================================================================================
//==================PC_ID_REGISTER========================================================================================================================
  always_comb begin: if_id_input
    if_id_next.inst = inst_if;
    if_id_next.pc   = pc_if;
  end

  always_ff @( posedge i_clk ) begin : if_id_register
    if(~i_reset || flush) begin
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
  regfile regfile (
    .i_clk      (i_clk                    ),
    .i_reset    (i_reset                  ),
    .i_rs1_addr (if_id_reg.inst[`RS1_ADDR]),
    .i_rs2_addr (if_id_reg.inst[`RS2_ADDR]),
    .i_rd_addr  (mem_wb_reg.inst[`RD_ADDR]),
    .i_rd_data  (wb_data_o                ),
    .i_rd_wren  (mem_wb_reg.scalar_wren   ),
    .o_rs1_data (rs1_data                 ),
    .o_rs2_data (rs2_data                 )
  );

  //=================VR2_SELECT==================================================================================================================================
  assign vr2_sel    = (if_id_reg.inst[`OPCODE] == VSTORE) ? if_id_reg.inst[`RD_ADDR] : if_id_reg.inst[`VS2_ADDR];
  assign ex_vr2_sel = (id_ex_reg.inst[`OPCODE] == VSTORE) ? id_ex_reg.inst[`RD_ADDR] : id_ex_reg.inst[`VS2_ADDR];
  //==================REGFILE============================================================================================================================
    vector_regfile #(.SEW(8), .VLEN(64)) vector_regfile (
      .i_clk       (i_clk                     ),
      .ni_rst      (i_reset                   ),
      .i_vrs1_addr (if_id_reg.inst[`VS1_ADDR] ),
      .i_vrs2_addr (vr2_sel                   ),
      .i_vrd_addr  (mem_wb_reg.inst[`VRD_ADDR]),
      .i_vrd_data  (wb_vdata_o                ),
      .i_vrd_wren  (mem_wb_reg.vector_wren    ),
      .vector_enb  (mem_wb_reg.vector_enb     ),
      .vlen_enb    (mem_wb_reg.vlen_enb       ),
      .o_vrs1_data (vs1_data                  ),
      .o_vrs2_data (vs2_data                  )
    );
  always_comb begin
    vs3_data = (if_id_reg.inst[`OPCODE] == VSTORE) ? vs2_data : 64'b0;
  end

//==================CONTROL_UNIT=========================================================================================================================
  control_unit  control_unit (
    .i_clk        (i_clk         ),
    .ni_rst       (i_reset       ),
    .inst         (if_id_reg.inst),
    .br_unsign    (br_unsign     ),
    .vector_enb   (vector_enb    ),
    .op1_sel      (op1_sel       ),
    .op2_sel      (op2_sel       ),
    .branch_signal(branch_signal ),
    .rs1_data     (op1_forward    ),
    .jmp_signal   (jmp_signal    ),
    .scalar_wb    (scalar_wb     ),
    .alu_opcode   (alu_op_io     ),
    .scalar_wren  (scalar_wren   ),
    .mems_wren    (mems_wren     ),
    .mems_rden    (mems_rden     ),
    .is_vsetvli   (is_vsetvli    ),
    .vlen_set     (vlen_set      ),
    .vlen_enb     (vlen_enb      )    
  );

  //==================VECTOR_CONTROL_UNIT=========================================================================================================================
    vector_control  vector_control (
      .inst       (if_id_reg.inst),
      .vector_enb (vector_enb    ),
      .vector_wb  (vector_wb     ),
      .is_vsetvli (is_vsetvli     ),
      .valu_unsign(valu_unsign   ),
      .vop1_sel   (vop1_sel      ),
      .valu_opcode(valu_opcode   ),
      .memv_wren  (memv_wren     ),
      .vector_wren(vector_wren   ),
      .memv_rden  (memv_rden     )
    );
//==================BRCOMP=============================================================================================================================
  brcomp branch_compare (
    .i_rs1_data (op1_forward ),
    .i_rs2_data (op2_forward ),
    .i_br_un    (br_unsign),
    .o_br_less  (br_less  ),
    .o_br_equal (br_equal )
  );
//==================PC_ADDER=====================================================================================================================================
  pc_reg pc_adder_imm (
    .pc_reg(if_id_reg.pc),
    .op    (imm_ex      ),
    .pc_o  (pc_imm      )

  );
  always_comb begin : jalr_case
    // Dành riêng cho JALR (vì nó cộng rs1 với imm)
    // Lưu ý: Đảm bảo rs1_data ở đây phải là dữ liệu đã FORWARD nhé (op1_forward)!
    if(id_ex_reg.inst[`OPCODE] == 7'b1100111) begin // Opcode của JALR
      jmp_pc = (op1_forward + imm_ex) & 32'hFFFFFFFE; 
    end 
    // Dành cho B-Type (Branch) và J-Type (JAL)
    else begin
      // Lấy đích đến đã được ALU tính toán sẵn cực kỳ chuẩn xác!
      jmp_pc = rd_data_o; 
    end
  end
// ==================SCALAR_IMMGEN==================================================================================================================================
  immgen immgen (
    .inst_i (if_id_reg.inst),
    .imm_o  (imm_ex        )
  );
  // ==================VECOR_IMMGEN==================================================================================================================================
  vector_immgen #(.SEW(8)) vector_immgen (
    .inst_i (if_id_reg.inst),
    .vimm_o (vimm_ex        )
  );
//==================EX_STAGE========================================================================================================================
  always_comb begin: input_ex_stage_reg
    id_ex_next.inst          = if_id_reg.inst;
    id_ex_next.pc            = if_id_reg.pc;
    // data scalar 
    id_ex_next.rs1_data      = rs1_data;
    id_ex_next.rs2_data      = rs2_data;
    id_ex_next.imm_ex        = imm_ex;
    // data vector 
    id_ex_next.vrs1_data     = vs1_data;
    id_ex_next.vrs2_data     = vs2_data;
    id_ex_next.vrs3_data     = vs3_data;
    id_ex_next.vimm_ex       = vimm_ex;
    id_ex_next.vlen_set      = vlen_set;
    // addr scalar same with vector
    id_ex_next.rs1_addr      = if_id_reg.inst[`RS1_ADDR];   
    id_ex_next.rs2_addr      = if_id_reg.inst[`RS2_ADDR];
    id_ex_next.rd_addr       = if_id_reg.inst[`RD_ADDR];
    id_ex_next.func3         = if_id_reg.inst[`FUNC3];
    // signal control scaalr
    id_ex_next.alu_opcode    = alu_op_io;
    id_ex_next.op1_sel       = op1_sel;
    id_ex_next.op2_sel       = op2_sel;
    id_ex_next.br_unsign     = br_unsign;
    id_ex_next.branch_signal = branch_signal;
    id_ex_next.jmp_signal    = jmp_signal;
    id_ex_next.mems_wren     = mems_wren;
    id_ex_next.mems_rden     = mems_rden;
    id_ex_next.scalar_wren   = scalar_wren;
    id_ex_next.scalar_wb     = scalar_wb;
    // signal control vector
    id_ex_next.valu_opcode   = valu_opcode;
    id_ex_next.vlen_enb      = vlen_enb;
    id_ex_next.vlen_set      = vlen_set;
    id_ex_next.vector_enb    = vector_enb;
    id_ex_next.vop1_sel      = vop1_sel; // bug here
    id_ex_next.valu_unsign   = valu_unsign;
    id_ex_next.memv_wren     = memv_wren;
    id_ex_next.memv_rden     = memv_rden;
    id_ex_next.vector_wren   = vector_wren;
    id_ex_next.vector_wb     = vector_wb;
  end

  always_ff @( posedge i_clk ) begin : id_ex_register
    if(~i_reset || scalar_stall || flush || vector_stall) begin
      id_ex_reg   <= '0;
      id_ex_valid <= 1'b0;
    end else if (ex_reg_enb) begin
      id_ex_reg   <= id_ex_next;
      id_ex_valid <= if_id_valid;
    end
  end

  always_comb begin: id_ex_debug
    inst_ex_debug = id_ex_reg.inst;
    pc_ex_debug   = id_ex_reg.branch_signal;
    rs1_ex_debug  = id_ex_reg.rs1_data;
    rs2_ex_debug  = id_ex_reg.rs2_data;
    imm_ex_debug  = id_ex_reg.imm_ex ;
    vrs1_ex_debug = id_ex_reg.vrs1_data;
    vrs2_ex_debug = id_ex_reg.vrs2_data;
    vrs3_ex_debug = id_ex_reg.vrs3_data;
    vimm_ex_debug = id_ex_reg.vimm_ex;
    vop1sl_ex_debug = id_ex_reg.vop1_sel;
    vlen_ex_debug = id_ex_reg.vlen_set;
    vector_wren_ex_debug = id_ex_reg.vector_wb;
  end
 //==================PC_SRC=============================================================================================================================
  always_comb begin : pc_src_check
    case (id_ex_reg.inst[`FUNC3])
      3'b000: jmp_check =  br_equal;                           // beq
      3'b001: jmp_check = ~br_equal;                           // bne
      3'b100: jmp_check =  br_less;                            // blt
      3'b101: jmp_check = ~br_less || br_equal;                // bge > or =
      3'b110: jmp_check =  br_less && br_unsign;               // bltu
      3'b111: jmp_check = (~br_less || br_equal) && br_unsign; // bgeu
      default:jmp_check = 1'b0;
    endcase
    pc_src    = (jmp_check && id_ex_reg.branch_signal) | id_ex_reg.jmp_signal; // branch is condition jmp, jmp is unconditon so invert the condition
    o_mispred = pc_src; 
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
      2'b10:   op1_forward = mem_forward_data;
      default: op1_forward = 32'bx;
    endcase

    case (rs2_forwarding_sel)
      2'b00:   op2_forward = id_ex_reg.rs2_data;
      2'b01:   op2_forward = wb_data_o; 
      2'b10:   op2_forward = mem_forward_data;
      default: op2_forward = 32'bx;
    endcase
  end 
  pc_reg PC_ex_plus4 (
    .pc_reg(id_ex_reg.pc),
    .op    (32'd4),
    .pc_o  (pc4_ex)
  );
//==================OPERATION_1_MUX===========================================================================================================================
  assign op1 = (id_ex_reg.op1_sel) ? id_ex_reg.pc : op1_forward;
//==================OPERATION_2_MUX===========================================================================================================================
  assign op2 = (id_ex_reg.op2_sel) ? id_ex_reg.imm_ex : op2_forward;
//==================ALU=====================================================================================================================================
  alu alu (
    .i_op_a      (op1                 ),
    .i_op_b      (op2                 ),
    .br_unsign_i (id_ex_reg.br_unsign ),
    .i_alu_op    (id_ex_reg.alu_opcode),
    .o_alu_data  (rd_data_o           )
  );
  assign mem_forward_data = (id_ex_reg.inst[`OPCODE] == IITYPE || id_ex_reg.inst[`OPCODE] == IJTYPE) ? pc4_ex : ex_mem_reg.alu_result;
  //==================VECTOR_FORWARDING_MUX===========================================================================================================================
    always_comb begin : vector_forwarding_mux
      vop1_forward = 64'b0;
      vop2_forward = 64'b0;
      case (vrs1_forwarding_sel)
        2'b00:   vop1_forward = id_ex_reg.vrs1_data;
        2'b01:   vop1_forward = wb_vdata_o; 
        2'b10:   vop1_forward = ex_mem_reg.valu_result;
        default: vop1_forward = 64'b0;
      endcase

      case (vrs2_forwarding_sel)
        2'b00:   vop2_forward = id_ex_reg.vrs2_data;
        2'b01:   vop2_forward = wb_vdata_o;   
        2'b10:   vop2_forward = ex_mem_reg.valu_result;
        default: vop2_forward = 64'b0;
      endcase
    end
  //==================VECTOR OPERATION_1_MUX===========================================================================================================================
    always_comb begin
      case (id_ex_reg.vop1_sel)
        2'b00:   vop1 = {8{op1_forward[7:0]}};       // rs1 broadcasting
        2'b01:   vop1 = vop1_forward; 
        2'b10:   vop1 = id_ex_reg.vimm_ex;            // imm5: Mở rộng dấu 5-bit thành 8-bit, rồi nhân bản 8 lần
        default: vop1 = 64'd0;
      endcase
    end
  //==================VECTOR OPERATION_2_MUX===========================================================================================================================
    assign vop2 = vop2_forward;   	     
  //==================VECTOR-ALU=====================================================================================================================================
    vector_alu vector_alu (
                            .i_vrs1_data   (vop1                  ),
                            .i_vrs2_data   (vop2                  ),
                            .i_valu_unsign (id_ex_reg.valu_unsign ),
                            .i_valu_opcode (id_ex_reg.valu_opcode ),
                            .o_alu_result  (vrd_data_o             )
                          );
//==================MEM_STAGE========================================================================================================================
   always_comb begin: input_mem_stage_reg
    ex_mem_next.inst          = id_ex_reg.inst;
    ex_mem_next.pc            = id_ex_reg.pc;
    // data scalar
    ex_mem_next.rs2_data      = op2_forward;
    ex_mem_next.alu_result    = rd_data_o;
    // data vector
    ex_mem_next.vrs2_data     = vop2_forward;
    ex_mem_next.vrs3_data     = vs3_data;
    ex_mem_next.valu_result   = vrd_data_o;
    ex_mem_next.vlen_set      = id_ex_reg.vlen_set;
    // addr
    ex_mem_next.rd_addr       = id_ex_reg.inst[`RD_ADDR];
    ex_mem_next.func3         = id_ex_reg.inst[`FUNC3];
    // signal control scalar
    ex_mem_next.mems_wren     = id_ex_reg.mems_wren;
    ex_mem_next.mems_rden     = id_ex_reg.mems_rden;
    ex_mem_next.scalar_wren   = id_ex_reg.scalar_wren;
    ex_mem_next.scalar_wb     = id_ex_reg.scalar_wb;
    // signal control vector
    ex_mem_next.memv_wren     = id_ex_reg.memv_wren;
    ex_mem_next.memv_rden     = id_ex_reg.memv_rden;
    ex_mem_next.vlen_enb      = id_ex_reg.vlen_enb;
    ex_mem_next.vector_enb    = id_ex_reg.vector_enb;
    ex_mem_next.vector_wren   = id_ex_reg.vector_wren;
    ex_mem_next.vector_wb     = id_ex_reg.vector_wb;
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
    vrs2_mem_debug = vop2_forward;
    valu_mem_debug = ex_mem_reg.valu_result;
    vlen_mem_debug = ex_mem_reg.vlen_enb;
    vector_wren_mem_debug = ex_mem_reg.vector_wb;
  end
//==================LSU=====================================================================================================================================
  always_comb begin
  // has rs2's data if stype to store rs2's data to mem
    wr_data_scalar = 32'b0;
    wr_data_vector = 64'b0; 
    if      (ex_mem_reg.inst[`OPCODE] == STYPE)  wr_data_scalar = ex_mem_reg.rs2_data;
    else if (ex_mem_reg.inst[`OPCODE] == VSTORE) wr_data_vector = ex_mem_reg.vrs2_data;  // vs3 is the data which address is vload[11:7]
  end

  lsu lsu (
    .i_clk          (i_clk                ),
    .i_reset        (i_reset              ),
    .i_lsu_addr     (ex_mem_reg.alu_result),
    .i_scalar_stdata(wr_data_scalar       ),
    .i_vector_stdata(wr_data_vector       ),
    .i_vlen_en      (ex_mem_reg.vlen_enb  ),
    .i_scalar_wren  (ex_mem_reg.mems_wren ),
    .i_scalar_rden  (ex_mem_reg.mems_rden ),
    .i_vector_wren  (ex_mem_reg.memv_wren ),
    .i_vector_rden  (ex_mem_reg.memv_rden ),
    .i_inst         (ex_mem_reg.inst      ),
    .i_io_sw        (i_io_sw              ),
    .i_uart_rx      (i_uart_rx            ),
    .o_io_hex0      (o_io_hex0            ),
    .o_io_hex1      (o_io_hex1            ),
    .o_io_hex2      (o_io_hex2            ),
    .o_io_hex3      (o_io_hex3            ),
    .o_io_hex4      (o_io_hex4            ),
    .o_io_hex5      (o_io_hex5            ),
    .o_io_hex6      (o_io_hex6            ),
    .o_io_hex7      (o_io_hex7            ),
    .o_uart_tx      (o_uart_tx            ),
    .o_scalar_lddata(read_data_scalar     ),
    .o_vector_lddata(read_data_vector     ),
    .o_io_ledr      (o_io_ledr            ),
    .o_io_ledg      (o_io_ledg            ),
    .o_io_lcd       (o_io_lcd             )
  );

//==================WB_STAGE========================================================================================================================
  always_comb begin: input_wb_stage_reg
   	mem_wb_next.inst             = ex_mem_reg.inst;
		mem_wb_next.pc               = ex_mem_reg.pc;
    // data scalar
    mem_wb_next.rs2_data         = ex_mem_reg.rs2_data;
    mem_wb_next.alu_result       = ex_mem_reg.alu_result;
    mem_wb_next.read_data_scalar = read_data_scalar;
    // data vector
    mem_wb_next.valu_result      = ex_mem_reg.valu_result;
    mem_wb_next.vrs2_data        = ex_mem_reg.vrs2_data;
    mem_wb_next.vlen_set         = ex_mem_reg.vlen_set;
    mem_wb_next.read_data_vector = read_data_vector;
    // addr
    mem_wb_next.rd_addr          = ex_mem_reg.inst[`RD_ADDR];
    mem_wb_next.func3            = ex_mem_reg.inst[`FUNC3];
    // signal control
    mem_wb_next.scalar_wren      = ex_mem_reg.scalar_wren;
    mem_wb_next.scalar_wb        = ex_mem_reg.scalar_wb;
    mem_wb_next.vlen_enb         = ex_mem_reg.vlen_enb;
    mem_wb_next.vector_enb       = ex_mem_reg.vector_enb;
    mem_wb_next.vector_wren      = ex_mem_reg.vector_wren;
    mem_wb_next.vector_wb        = ex_mem_reg.vector_wb;
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
    alu_wb_debug     = mem_wb_reg.alu_result;
    valu_wb_debug    = mem_wb_reg.valu_result;
    rs2_debug        = mem_wb_reg.rs2_data;
    vlen_wb_debug    = mem_wb_reg.vlen_enb;
    scalar_wren_wb_debug    = mem_wb_reg.vector_wb;
    memdata_wb_debug    = mem_wb_reg.read_data_vector;
  end
//==================SCALAR_WRITEBACK=============================================================================================================================
  always_comb begin : scalar_write_back
    wb_data_o = 32'b0;
    if(mem_wb_reg.inst[`RD_ADDR] == 5'b00000) begin
      wb_data_o = 32'b0;
    end else if (mem_wb_reg.inst[6:0] == VECTOR && mem_wb_reg.inst[`FUNC3] == 3'b111) begin
      wb_data_o = mem_wb_reg.vlen_set;
    end else if (mem_wb_reg.scalar_wb) begin
      wb_data_o = mem_wb_reg.read_data_scalar;
    end else if (~mem_wb_reg.scalar_wb) begin
      wb_data_o = mem_wb_reg.alu_result;
    end
  end
//==================VECTOR_WRITEBACK=============================================================================================================================
  always_comb begin : vector_write_back
    wb_vdata_o = 64'b0;
    if      (mem_wb_reg.vector_wb)  wb_vdata_o = mem_wb_reg.read_data_vector; 
    else if (~mem_wb_reg.vector_wb) wb_vdata_o = mem_wb_reg.valu_result; 
  end

  assign o_insn_vld = mem_wb_valid;
  assign o_pc_debug = (o_insn_vld) ? mem_wb_reg.pc : 32'b0;

endmodule