//===========================================================================================================
// Project         : Single Cycle of RISV - V
// Module          : Load Store Unit
// File            : lsu.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 9/9/2025
// Updated date    : 6/11/2025 - Finished
//============================================================================================================
module lsu (
  input  wire        i_clk,
  input  wire        i_reset,

  input  wire [31:0] i_lsu_addr,
  input  wire [31:0] i_st_data,
  input  wire        i_lsu_wren,
  input  wire        i_lsu_rden,
  input  wire [2:0]  i_func3,

  input  wire [31:0] i_io_sw,

  output reg  [6:0]  o_io_hex0,
  output reg  [6:0]  o_io_hex1,
  output reg  [6:0]  o_io_hex2,
  output reg  [6:0]  o_io_hex3,
  output reg  [6:0]  o_io_hex4,
  output reg  [6:0]  o_io_hex5,
  output reg  [6:0]  o_io_hex6,
  output reg  [6:0]  o_io_hex7,

  output reg  [31:0] o_ld_data,

  output reg  [31:0] o_io_ledr,

  output reg  [31:0] o_io_ledg,

  output reg  [31:0] o_io_lcd
);

//====================================DECLARATION==============================================================
  wire        is_ledr;
  wire        is_ledg;
  wire        is_hex03;
  wire        is_hex47;
  wire        is_lcd;
  wire        is_sw;

  wire        is_dmem;
  wire        is_out;
  wire        is_in;

  wire [15:0] dmem_ptr;

  reg         mem_wren;
  reg         mem_rden;

  reg         is_sbyte;
  reg         is_ubyte;
  reg         is_shb;
  reg         is_uhb;
  reg         is_word;

  reg  [31:0] dmem;

  reg  [31:0] ledr_next, ledg_next, lcd_next;
  reg  [6:0]  hex0_next, hex1_next, hex2_next, hex3_next;
  reg  [6:0]  hex4_next, hex5_next, hex6_next, hex7_next;

  reg  [31:0] st_wdata;
  reg  [15:0] halfword_out;
  reg  [7:0]  byte_out;

  reg  [3:0]  bmask_align;
  reg  [3:0]  bmask_misalign;

//====================================CODE====================================================================
  always_comb begin
    is_ubyte = 1'b0;
    is_sbyte = 1'b0;
    is_uhb   = 1'b0;
    is_shb   = 1'b0;
    is_word  = 1'b0;
    bmask_align = 4'b0;
    bmask_misalign = 4'b0;
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
    if( is_sbyte || is_ubyte) begin : bmask_align_sort
      case (i_lsu_addr[1:0])                      // check number of immediate
        2'b00: begin
                bmask_align    = 4'b0001;                 // byte 1
                bmask_misalign = 4'b0000;
               end
        2'b01: begin
                bmask_align    = 4'b0010;                 // byte 2
                bmask_misalign = 4'b0000;
               end
        2'b10: begin
                bmask_align    = 4'b0100;                 // byte 3
                bmask_misalign = 4'b0000;
               end
        2'b11: begin
                bmask_align    = 4'b1000;                 // byte 4
                bmask_misalign = 4'b0000;
               end
        default: begin
                bmask_align    = 4'b0000;
                bmask_misalign = 4'b0000;
               end
      endcase
    end else if ( is_shb || is_uhb) begin
      case (i_lsu_addr[1:0])                      // check number of immediate
        2'b00: begin
                bmask_align    = 4'b0011;                 // byte 1, 2
                bmask_misalign = 4'b0000;
               end
        2'b01: begin
                bmask_align    = 4'b0110;
                bmask_misalign = 4'b0000;
               end
        2'b10: begin
                bmask_align    = 4'b1100;                 // byte 3, 4
                bmask_misalign = 4'b0000;
               end
        2'b11: begin
                bmask_align    = 4'b1000;
                bmask_misalign = 4'b0001;
               end
        default: begin
                bmask_align    = 4'b0000;
                bmask_misalign = 4'b0000;
        end
      endcase
    end else if (is_word) begin
      case(i_lsu_addr[1:0])
          2'b00: begin
              bmask_align    = 4'b1111;
              bmask_misalign = 4'b0000;
          end
          2'b01: begin
              bmask_align    = 4'b1110;
              bmask_misalign = 4'b0001;
          end
          2'b10: begin
              bmask_align    = 4'b1100;
              bmask_misalign = 4'b0011;
          end
          2'b11: begin
              bmask_align    = 4'b1000;
              bmask_misalign = 4'b0111;
          end
        default: begin
              bmask_align    = 4'b0000;
              bmask_misalign = 4'b0000;
          end
      endcase
    end
  end

  assign dmem_ptr  =  i_lsu_addr[15:0];
  assign is_dmem   =  ~i_lsu_addr[28];                           //0000 -> bit 28 == 0
  assign is_out    =  (i_lsu_addr[28] && ~(i_lsu_addr[16])); //1000 -> a[28] & ~a[16]
  assign is_in     =  (i_lsu_addr[28] &&   i_lsu_addr[16] ); //1001 -> a[28] & a[16]

  assign is_ledr   = is_out && (~i_lsu_addr[14] && ~i_lsu_addr[13] && ~i_lsu_addr[12]); // 0x1000_0xxx
  assign is_ledg   = is_out && (~i_lsu_addr[14] && ~i_lsu_addr[13] &&  i_lsu_addr[12]); // 0x1000_1xxx
  assign is_hex03  = is_out && (~i_lsu_addr[14] &&  i_lsu_addr[13] && ~i_lsu_addr[12]); // 0x1000_2xxx
  assign is_hex47  = is_out && (~i_lsu_addr[14] &&  i_lsu_addr[13] &&  i_lsu_addr[12]); // 0x1000_3xxx
  assign is_lcd    = is_out && ( i_lsu_addr[14] && ~i_lsu_addr[13] && ~i_lsu_addr[12]); // 0x1000_4xxx
  assign is_sw     = is_in  && ( i_lsu_addr[16] && ~i_lsu_addr[13]                  ); // 0x1001_0xxx

  memory memory (
                .i_clk  (i_clk                  ),
                .i_reset(i_reset                ),
                .i_func3(i_func3                ),
                .i_addr (dmem_ptr               ),
                .i_wdata(i_st_data              ),
                .i_bmask_align(bmask_align      ),
                .i_bmask_misalign(bmask_misalign),
                .i_wren (mem_wren               ),
                .i_rden (i_lsu_rden             ),
                .o_rdata(dmem                   )
              );

  always_comb begin : st_data
    mem_wren  = 1'b0;
    st_wdata  = i_st_data;

    ledr_next = o_io_ledr;
    ledg_next = o_io_ledg;
    lcd_next  = o_io_lcd;
    hex0_next = o_io_hex0; hex1_next = o_io_hex1;
    hex2_next = o_io_hex2; hex3_next = o_io_hex3;
    hex4_next = o_io_hex4; hex5_next = o_io_hex5;
    hex6_next = o_io_hex6; hex7_next = o_io_hex7;

    if(is_dmem) begin
      if(i_lsu_wren) begin
        mem_wren = 1'b1;
        case (bmask_align)
          4'b0000: mem_wren = 1'b0;
          4'b0001,
          4'b0010,
          4'b0100: st_wdata = {24'b0, i_st_data[7:0]        };
          4'b1000: st_wdata =         i_st_data;
          4'b0011: st_wdata = {16'b0, i_st_data[15:0]       };
          4'b1100: st_wdata = {       i_st_data[15:0], 16'b0};
          4'b1111: st_wdata =         i_st_data;
          default: begin
                   st_wdata = 32'b0;
                   mem_wren = 1'b0;
          end
        endcase
      end else begin
        o_ld_data = dmem;
      end
    end else if (i_lsu_wren && is_ledr) begin
        ledr_next = st_wdata;
    end else if (i_lsu_wren && is_ledg) begin
        ledg_next = st_wdata;
    end else if (i_lsu_wren && is_hex03) begin
          case (bmask_align)
            4'b0000: begin
              hex0_next = 7'b1111111;
              hex1_next = 7'b1111111;
              hex2_next = 7'b1111111;
              hex3_next = 7'b1111111;
            end
            4'b0001: hex0_next = st_wdata[6:0];
            4'b0010: hex1_next = st_wdata[6:0];
            4'b0100: hex2_next = st_wdata[6:0];
            4'b1000: hex3_next = st_wdata[6:0];
            4'b0011: begin
              hex0_next = st_wdata[6:0];
              hex1_next = st_wdata[14:8];
              hex2_next = 7'b0;
              hex3_next = 7'b0;
            end
            4'b1100: begin
              hex0_next = 7'b0;
              hex1_next = 7'b0;
              hex2_next = st_wdata[6:0];
              hex3_next = st_wdata[14:8];
            end
            4'b1111: begin
              hex0_next = st_wdata[6:0];
              hex1_next = st_wdata[14:8];
              hex2_next = st_wdata[22:16];
              hex3_next = st_wdata[30:24];
            end
            default: begin
              hex0_next = 7'b1111111;
              hex1_next = 7'b1111111;
              hex2_next = 7'b1111111;
              hex3_next = 7'b1111111;
            end
          endcase
      end else if (is_hex47 && i_lsu_wren) begin
        case (bmask_align)
          4'b0000: begin
            hex4_next = 7'b1111111;
            hex5_next = 7'b1111111;
            hex6_next = 7'b1111111;
            hex7_next = 7'b1111111;
          end
          4'b0001: hex4_next = st_wdata[6:0];
          4'b0010: hex5_next = st_wdata[6:0];
          4'b0100: hex6_next = st_wdata[6:0];
          4'b1000: hex7_next = st_wdata[6:0];
          4'b0011: begin
            hex4_next = st_wdata[6:0];
            hex5_next = st_wdata[14:8];
            hex6_next = 7'b0;
            hex7_next = 7'b0;
          end
          4'b1100: begin
            hex4_next = 7'b0;
            hex5_next = 7'b0;
            hex6_next = st_wdata[6:0];
            hex7_next = st_wdata[14:8];
          end
          4'b1111: begin
            hex4_next = st_wdata[6:0];
            hex5_next = st_wdata[14:8];
            hex6_next = st_wdata[22:16];
            hex7_next = st_wdata[30:24];
          end
          default: begin
            hex4_next = 7'b1111111;
            hex5_next = 7'b1111111;
            hex6_next = 7'b1111111;
            hex7_next = 7'b1111111;
          end
        endcase
      end else if (i_lsu_wren && is_lcd) begin
        lcd_next = st_wdata;
      end else if (~i_lsu_wren && is_sw) begin
        o_ld_data = i_io_sw;
      end
    end

  always_ff @(posedge i_clk) begin
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
    end else if (i_lsu_wren) begin
      o_io_ledr <= ledr_next;
      o_io_ledg <= ledg_next;
      o_io_lcd  <= lcd_next;
      o_io_hex0 <= hex0_next;
      o_io_hex1 <= hex1_next;
      o_io_hex2 <= hex2_next;
      o_io_hex3 <= hex3_next;
      o_io_hex4 <= hex4_next;
      o_io_hex5 <= hex5_next;
      o_io_hex6 <= hex6_next;
      o_io_hex7 <= hex7_next;
    end
end

endmodule
