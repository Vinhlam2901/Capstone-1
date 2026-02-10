//===========================================================================================================
// Project         : Single Cycle of RISV - V
// Module          : Memory
// File            : memory.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 21/10/2025
// Updated date    : 5/12/2025
//=============================================================================================================
module memory (
 input  wire         i_clk,
 input  wire         i_reset,
 input  wire  [2:0]  i_func3,
 input  wire  [15:0] i_addr,
 input  wire  [31:0] i_wdata,
 input  wire  [3:0]  i_bmask_align,
 input  wire  [3:0]  i_bmask_misalign,
 input  wire         i_wren,
 input  wire         i_rden,
 output reg   [31:0] o_rdata
);
  integer  i;
  reg  [31:0] mem          [0: 16383]; // 2kB
  reg  [31:0] mem_st_align;
  reg  [31:0] mem_st_misalign;
  reg  [31:0] mem_ld_align;
  reg  [31:0] mem_ld_misalign;
  wire [31:0] mem_addr;
  wire [31:0] mem_addr_plus1;
  reg         is_sbyte;
  reg         is_ubyte;
  reg         is_shb;
  reg         is_uhb;
  reg         is_word;

  assign mem_addr = {18'b0 , i_addr[15:2]};

  full_adder_32bit fa (
    .A_i(mem_addr        ),
    .Y_i(32'd1           ),
    .C_i(1'b0            ),
    .Sum_o(mem_addr_plus1),
    .c_o(                )
  );

  always_comb begin
    mem_st_align    = 32'b0;
    mem_st_misalign = 32'b0;
    case (i_bmask_align)
      4'b0001: mem_st_align    = {24'b0, i_wdata[ 7:0]       };
      4'b0010: mem_st_align    = {16'b0, i_wdata[ 7:0], 8'b0 };
      4'b0100: mem_st_align    = {8'b0 , i_wdata[ 7:0], 16'b0};
      4'b1000: mem_st_align    = {       i_wdata[ 7:0], 24'b0};
      4'b0011: mem_st_align    = {16'b0, i_wdata[15:0]       };
      4'b1100: mem_st_align    = {       i_wdata[15:0], 16'b0};
      4'b1110: mem_st_align    = {       i_wdata[23:0], 8'b0 };
      4'b1111: mem_st_align    =         i_wdata;
      default: mem_st_align    = 32'b0;
    endcase
    case (i_bmask_misalign)
      4'b0000: mem_st_misalign = 32'b0;
      4'b0001: mem_st_misalign = (i_bmask_align[2])?{24'b0, i_wdata[31:24]}:{24'b0, i_wdata[15:8]};
      4'b0011: mem_st_misalign = {16'b0, i_wdata[31:16]};
      4'b0111: mem_st_misalign = {8'b0 , i_wdata[31:8]};
      default: mem_st_misalign = 32'b0;
    endcase
  end

  always_comb begin
    is_ubyte = 1'b0;
    is_sbyte = 1'b0;
    is_uhb   = 1'b0;
    is_shb   = 1'b0;
    is_word  = 1'b0;
    case (i_func3)
      3'b000: is_sbyte = 1'b1;
      3'b001: is_shb   = 1'b1;
      3'b010: is_word  = 1'b1;
      3'b100: is_ubyte = 1'b1;
      3'b101: is_uhb   = 1'b1;
      default: begin
              is_ubyte = 1'b0;
              is_sbyte = 1'b0;
              is_uhb   = 1'b0;
              is_shb   = 1'b0;
              is_word  = 1'b0;
              end
    endcase
  end

  always_ff @(posedge i_clk) begin : mem_align_store
    if (~i_reset) begin : reset
      o_rdata <= 32'b0;
      for(i = 0; i <= 4095; i = i + 1) begin
        mem[i] <= 32'b0;
      end
    end else if (i_wren) begin
      if (i_bmask_align[0])    mem[mem_addr      ][7 :0 ] <= mem_st_align[ 7:0 ];
      if (i_bmask_align[1])    mem[mem_addr      ][15:8 ] <= mem_st_align[15:8 ];
      if (i_bmask_align[2])    mem[mem_addr      ][23:16] <= mem_st_align[23:16];
      if (i_bmask_align[3])    mem[mem_addr      ][31:24] <= mem_st_align[31:24];
      if (i_bmask_misalign[0]) mem[mem_addr_plus1][7 :0 ] <= mem_st_misalign[ 7:0 ];
      if (i_bmask_misalign[1]) mem[mem_addr_plus1][15:8 ] <= mem_st_misalign[15:8 ];
      if (i_bmask_misalign[2]) mem[mem_addr_plus1][23:16] <= mem_st_misalign[23:16];
      if (i_bmask_misalign[3]) mem[mem_addr_plus1][31:24] <= mem_st_misalign[31:24];
    end else if (i_rden) begin
      mem_ld_align    = mem[mem_addr];
      mem_ld_misalign = mem[mem_addr_plus1];
      if(is_word) begin
        case(i_addr[1:0])
          2'b00:   o_rdata <=                         mem_ld_align;
          2'b01:   o_rdata <= {mem_ld_misalign[ 7:0], mem_ld_align[31:8 ]};
          2'b10:   o_rdata <= {mem_ld_misalign[15:0], mem_ld_align[31:16]};
          2'b11:   o_rdata <= {mem_ld_misalign[23:0], mem_ld_align[31:24]};
          default: o_rdata <= 32'b0;
        endcase
      end
    
      if(is_shb) begin
        case(i_addr[1:0])
          2'b00:   o_rdata <= {{16{mem_ld_align[15]}}  ,                       mem_ld_align[15:0 ]};
          2'b01:   o_rdata <= {{16{mem_ld_align[23]}}  ,                       mem_ld_align[23:8 ]};
          2'b10:   o_rdata <= {{16{mem_ld_align[31]}}  ,                       mem_ld_align[31:16]};
          2'b11:   o_rdata <= {{16{mem_ld_misalign[7]}}, mem_ld_misalign[7:0], mem_ld_align[31:24]};
          default: o_rdata <= 32'b0;
        endcase
      end
    
      if(is_uhb) begin
        case(i_addr[1:0])
          2'b00:   o_rdata <= {16'b0,                       mem_ld_align[15:0 ]};
          2'b01:   o_rdata <= {16'b0,                       mem_ld_align[23:8 ]};
          2'b10:   o_rdata <= {16'b0,                       mem_ld_align[31:16]};
          2'b11:   o_rdata <= {16'b0, mem_ld_misalign[7:0], mem_ld_align[31:24]};
          default: o_rdata <= 32'b0;
        endcase
      end
    
      if(is_sbyte) begin
        case(i_addr[1:0])
          2'b00:   o_rdata <= {{24{mem_ld_align[7]}} , mem_ld_align[ 7:0 ]};
          2'b01:   o_rdata <= {{24{mem_ld_align[15]}}, mem_ld_align[15:8 ]};
          2'b10:   o_rdata <= {{24{mem_ld_align[23]}}, mem_ld_align[23:16]};
          2'b11:   o_rdata <= {{24{mem_ld_align[31]}}, mem_ld_align[31:24]};
          default: o_rdata <= 32'b0;
        endcase
      end
    
      if(is_ubyte) begin
        case(i_addr[1:0])
          2'b00:   o_rdata <= {24'b0, mem_ld_align[ 7:0 ]};
          2'b01:   o_rdata <= {24'b0, mem_ld_align[15:8 ]};
          2'b10:   o_rdata <= {24'b0, mem_ld_align[23:16]};
          2'b11:   o_rdata <= {24'b0, mem_ld_align[31:24]};
          default: o_rdata <= 32'b0;
        endcase
      end
    end
  end
endmodule
