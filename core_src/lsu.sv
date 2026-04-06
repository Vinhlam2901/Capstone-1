  //===========================================================================================================
  // Project         : UART & RVV
  // Module          : Load Store Unit
  // File            : lsu.sv
  // Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
  // Create date     : 12/12/2025
  // Updated date    : 06/04/2026
  //============================================================================================================
  import package_param::*;
  module lsu (
    input  wire        i_clk,
    input  wire        i_reset,

    input  wire [31:0] i_inst,
    input  wire [31:0] i_lsu_addr,
    input  wire        i_scalar_wren,
    input  wire        i_scalar_rden,
    input  wire [31:0] i_scalar_stdata,
    
    input  wire        i_vector_wren,
    input  wire        i_vector_rden,
    input  wire [7:0]  i_vlen_en,
    input  wire [63:0] i_vector_stdata,
    
    input  wire        i_uart_rx,
    input  wire [31:0] i_io_sw,
    
    output wire        o_uart_tx,
    output reg  [6:0]  o_io_hex0,
    output reg  [6:0]  o_io_hex1,
    output reg  [6:0]  o_io_hex2,
    output reg  [6:0]  o_io_hex3,
    output reg  [6:0]  o_io_hex4,
    output reg  [6:0]  o_io_hex5,
    output reg  [6:0]  o_io_hex6,
    output reg  [6:0]  o_io_hex7,
    
    output reg  [31:0] o_io_ledr,
    
    output reg  [31:0] o_io_ledg,
    
    output reg  [31:0] o_io_lcd,
    
    output reg  [31:0] o_scalar_lddata,
    output reg  [63:0] o_vector_lddata
    
  );

  //====================================DECLARATION==============================================================
    wire        is_ledr;
    wire        is_ledg;
    wire        is_hex03;
    wire        is_hex47;
    wire        is_lcd;
    wire        is_sw;
    wire        is_uart;    // chip select
    wire        is_dmem;
    wire        is_out;
    wire        is_in;
    wire        is_io;

    wire [7:0]  uart_rdata;
    wire [15:0] dmem_ptr;

    reg         is_sbyte;
    reg         is_ubyte;
    reg         is_shb;
    reg         is_uhb;
    reg         is_word;
    reg         is_vstore;
    reg         is_vload;
    
    reg         mem_wren;

    reg  [31:0] dmem_scalar;
    reg  [63:0] dmem_vector;

    reg  [31:0] ledr_next, ledg_next, lcd_next;
    reg  [6:0]  hex0_next, hex1_next, hex2_next, hex3_next;
    reg  [6:0]  hex4_next, hex5_next, hex6_next, hex7_next;

    reg  [31:0] scalar_wdata;
    reg  [63:0] vector_wdata;
    reg  [15:0] halfword_out;
    reg  [7:0]  byte_out;

    reg  [7:0]  base_mask;
    reg  [7:0]  bmask_align;
    reg  [7:0]  bmask_misalign;
    reg  [15:0] shifted_mask;

  //====================================CODE====================================================================
    always_comb begin
      is_ubyte       = 1'b0;
      is_sbyte       = 1'b0;
      is_uhb         = 1'b0;
      is_shb         = 1'b0;
      is_word        = 1'b0;
      is_vstore      = 1'b0;
      is_vload       = 1'b0;
      bmask_align    = 4'b0;
      bmask_misalign = 4'b0;
      case (i_inst[`FUNC3])
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
      case (i_inst[`OPCODE])
        VSTORE:  is_vstore = 1'b1;
        VLOAD :  is_vload  = 1'b1;
        default: begin
                 is_vstore = 1'b0;
                 is_vload  = 1'b0;
        end   
      endcase
    
      if      (is_word)            base_mask = 8'b0000_1111;
      else if (is_shb || is_uhb)   base_mask = 8'b0000_0011;
      else if (is_sbyte||is_ubyte) base_mask = 8'b0000_0001;
      else                         base_mask = 8'b0000_0000;

      shifted_mask   = {8'b0, base_mask} << i_lsu_addr[2:0];
      bmask_align    = shifted_mask[7:0];  
      bmask_misalign = shifted_mask[15:8];
    end

    assign dmem_ptr =  i_lsu_addr[15:0];
    assign is_dmem  = ~i_lsu_addr[28];                                                  // 0x0000 -> bit 28 == 0
    assign is_out   = (i_lsu_addr[28] && ~i_lsu_addr[16]);                              // 0x1000 -> a[28] & ~a[16]
    assign is_in    = (i_lsu_addr[28] &&  i_lsu_addr[16]);                              // 0x1001 -> a[28] & a[16]
    // PRIPHERAL
    assign is_ledr  = is_out && (~i_lsu_addr[14] && ~i_lsu_addr[13] && ~i_lsu_addr[12]); // 0x1000_0xxx
    assign is_ledg  = is_out && (~i_lsu_addr[14] && ~i_lsu_addr[13] &&  i_lsu_addr[12]); // 0x1000_1xxx
    assign is_hex03 = is_out && (~i_lsu_addr[14] &&  i_lsu_addr[13] && ~i_lsu_addr[12]); // 0x1000_2xxx
    assign is_hex47 = is_out && (~i_lsu_addr[14] &&  i_lsu_addr[13] &&  i_lsu_addr[12]); // 0x1000_3xxx
    assign is_lcd   = is_out && ( i_lsu_addr[14] && ~i_lsu_addr[13] && ~i_lsu_addr[12]); // 0x1000_4xxx
    assign is_sw    = is_in  && ( i_lsu_addr[16] && ~i_lsu_addr[13]                   ); // 0x1001_0xxx
    // UART
    assign is_uart  = (i_lsu_addr[28] &&  i_lsu_addr[17]);                               // 0x1002 -> a[28] & a[17]

    uart_ip uart_dut (
                      .i_clk (i_clk), 
                      .ni_rst(i_reset),
                      .i_data(i_scalar_stdata[7:0]), 
                      .i_addr(i_lsu_addr[2:0]),
                      .i_cs1 (is_uart), 
                      .i_cs2 (1'b1), 
                      .ni_cs3(1'b0),
                      .i_ior (i_scalar_rden), 
                      .ni_ior(~i_scalar_rden),
                      .i_iow (i_scalar_wren), 
                      .ni_iow(~i_scalar_wren),
                      .o_data(uart_rdata), 
                      .i_rxd (i_uart_rx), 
                      .o_txd (o_uart_tx),
                      .ni_cts(1'b0)
                    );
    memory memory (
                  .i_clk           (i_clk          ),
                  .i_reset         (i_reset        ),
                  .i_func3         (i_inst[`FUNC3] ),
                  .i_addr          (dmem_ptr       ),
                  .i_scalar_wdata  (i_scalar_stdata),
                  .i_vector_wdata  (i_vector_stdata),
                  .i_vlen_en       (i_vlen_en      ),
                  .i_bmask_align   (bmask_align    ),
                  .i_bmask_misalign(bmask_misalign ),
                  .i_scalar_wren   (mem_wren       ),
                  .i_scalar_rden   (i_scalar_rden  ),
                  .i_vector_wren   (i_vector_wren  ),
                  .i_vector_rden   (i_vector_rden  ),
                  .o_scalar_rdata  (dmem_scalar    ),
                  .o_vector_rdata  (dmem_vector    )
                );
      
  always_comb begin : ld_data
    mem_wren     = 1'b0;
    scalar_wdata = i_scalar_stdata;
    vector_wdata = i_vector_stdata;
    if (i_scalar_wren && is_dmem) begin
      if   (bmask_align == 8'b0000_0000)  mem_wren = 1'b0;
      else                                mem_wren = 1'b1;
    end
    if (i_scalar_rden) begin
      if      (is_dmem) o_scalar_lddata = dmem_scalar;
      else if (is_sw)   o_scalar_lddata = i_io_sw;
      else if (is_uart) o_scalar_lddata = {{24{1'b0}}, uart_rdata};
      else              o_scalar_lddata = 32'b0;
    end
    if   (i_vector_rden) o_vector_lddata = dmem_vector;
    else                 o_vector_lddata = 64'b0;
    end
//=========================STORE=======================================
    always_ff @(posedge i_clk) begin: st_data
      if (~i_reset) begin
        o_io_ledr <= 32'b0;
        o_io_ledg <= 32'b0;
        o_io_lcd  <= 32'b0;
        o_io_hex0 <= 7'b1111111;
        o_io_hex1 <= 7'b1111111;
        o_io_hex2 <= 7'b1111111;
        o_io_hex3 <= 7'b1111111;
        o_io_hex4 <= 7'b1111111;
        o_io_hex5 <= 7'b1111111;
        o_io_hex6 <= 7'b1111111;
        o_io_hex7 <= 7'b1111111;
end else if (i_scalar_wren) begin
      if (is_ledr) begin
        if (bmask_align[0] | bmask_align[4]) o_io_ledr[ 7: 0] <= i_scalar_stdata[ 7: 0];
        if (bmask_align[1] | bmask_align[5]) o_io_ledr[15: 8] <= i_scalar_stdata[15: 8];
        if (bmask_align[2] | bmask_align[6]) o_io_ledr[23:16] <= i_scalar_stdata[23:16];
        if (bmask_align[3] | bmask_align[7]) o_io_ledr[31:24] <= i_scalar_stdata[31:24];
      end
      if (is_ledg) begin
        if (bmask_align[0] | bmask_align[4]) o_io_ledg[ 7: 0] <= i_scalar_stdata[ 7: 0];
        if (bmask_align[1] | bmask_align[5]) o_io_ledg[15: 8] <= i_scalar_stdata[15: 8];
        if (bmask_align[2] | bmask_align[6]) o_io_ledg[23:16] <= i_scalar_stdata[23:16];
        if (bmask_align[3] | bmask_align[7]) o_io_ledg[31:24] <= i_scalar_stdata[31:24];
      end
      if (is_lcd) begin
        if (bmask_align[0] | bmask_align[4]) o_io_lcd[ 7: 0] <= i_scalar_stdata[ 7: 0];
        if (bmask_align[1] | bmask_align[5]) o_io_lcd[15: 8] <= i_scalar_stdata[15: 8];
        if (bmask_align[2] | bmask_align[6]) o_io_lcd[23:16] <= i_scalar_stdata[23:16];
        if (bmask_align[3] | bmask_align[7]) o_io_lcd[31:24] <= i_scalar_stdata[31:24];
      end
      if (is_hex03) begin
        case (bmask_align[3:0] | bmask_align[7:4])
          4'b0001: o_io_hex0 <= i_scalar_stdata[6:0];
          4'b0010: o_io_hex1 <= i_scalar_stdata[6:0];
          4'b0100: o_io_hex2 <= i_scalar_stdata[6:0];
          4'b1000: o_io_hex3 <= i_scalar_stdata[6:0];
          4'b0011: begin 
                   o_io_hex0 <= i_scalar_stdata[6:0]; 
                   o_io_hex1 <= i_scalar_stdata[14:8]; 
                  end
          4'b1100: begin 
                   o_io_hex2 <= i_scalar_stdata[6:0]; 
                   o_io_hex3 <= i_scalar_stdata[14:8]; 
                  end
          4'b1111: begin
                   o_io_hex0 <= i_scalar_stdata[6:0];
                   o_io_hex1 <= i_scalar_stdata[14:8];
                   o_io_hex2 <= i_scalar_stdata[22:16];
                   o_io_hex3 <= i_scalar_stdata[30:24];
          end
        endcase
      end
      if (is_hex47) begin
        case (bmask_align[3:0] | bmask_align[7:4])
          4'b0001: o_io_hex4       <= i_scalar_stdata[6:0];
          4'b0010: o_io_hex5       <= i_scalar_stdata[6:0];
          4'b0100: o_io_hex6       <= i_scalar_stdata[6:0];
          4'b1000: o_io_hex7       <= i_scalar_stdata[6:0];
          4'b0011: begin 
                   o_io_hex4 <= i_scalar_stdata[6:0]; 
                   o_io_hex5 <= i_scalar_stdata[14:8]; 
                  end
          4'b1100: begin 
                   o_io_hex6 <= i_scalar_stdata[6:0]; 
                   o_io_hex7 <= i_scalar_stdata[14:8]; 
                  end
          4'b1111: begin
                   o_io_hex4 <= i_scalar_stdata[6:0];
                   o_io_hex5 <= i_scalar_stdata[14:8];
                   o_io_hex6 <= i_scalar_stdata[22:16];
                   o_io_hex7 <= i_scalar_stdata[30:24];
          end
        endcase
      end

    end
  end

  endmodule
