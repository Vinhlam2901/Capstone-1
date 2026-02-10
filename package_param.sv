package package_param;
   parameter RTYPE  = 7'b0110011;
   parameter ITYPE  = 7'b0010011;
   parameter IITYPE = 7'b1100111;
   parameter ILTYPE = 7'b0000011;
   parameter IJTYPE = 7'b1101111;
   parameter STYPE  = 7'b0100011;
   parameter BTYPE  = 7'b1100011;
   parameter U1TYPE = 7'b0110111;
   parameter U2TYPE = 7'b0010111;
/*BAUDRATE: number of bit in 1s is [number_of_baud]
f_fpga = CLK_FPGA
f_baud = BAUD_x   (with x = 4800, 9600, 19200)
counter = COUNTER_x = CLK_FPGA / BAUD_x
*/
   parameter int WIDTH = 32;
   parameter int CLK_FPAA       = 50_000_000;
   parameter int BAUD_4800      = 4800;
   parameter int BAUD_9600      = 9600;
   parameter int BAUD_19200     = 19200;
   parameter int COUNTER_4800   = 10417; // 14 bits
   parameter int WIDTH_4800     = 14;
   parameter int COUNTER_9600   = 5208;  // 13 bits
   parameter int WIDTH_9600     = 13;
   parameter int COUNTER_19200  = 2604;  // 12 bits
   parameter int WIDTH_19200    = 12;
   parameter int COUNTER_115200 = 434;  // 12 bits
   parameter int WIDTH_115200   = 9;

   `define OPCODE       6:0
   `define RD_ADDR      11:7
   `define FUNC3        14:12
   `define RS1_ADDR     19:15
   `define RS2_ADDR     24:20
   `define FUNC7        31:25
   `define IF_ID_WIDTH  64
   `define ID_EX_WIDTH  250
   `define EX_MEM_WIDTH 128
   `define MEM_WB_WIDTH 128
//==================STRUCT=============================================================================================================
  typedef logic [31:0] word_t;
  typedef logic [4:0]  addr_t;

  typedef struct packed {
    word_t pc;
    word_t inst;
    logic  o_insn_vld;
    logic  pred_taken;
  } if_id_reg_t;

  typedef struct packed {
    word_t      pc;
    word_t      inst;
    word_t      rs1_data;
    word_t      rs2_data;
    word_t      imm_ext;

    addr_t      rs1_addr;
    addr_t      rs2_addr;
    addr_t      rd_addr;

    logic       o_insn_vld;
    logic       pred_taken;
    logic [3:0] alu_opcode;
    logic       br_unsign;
    logic       op1_sel;
    logic       op2_sel;    // alu_src
    logic       mem_wren;
    logic       mem_rden;
    logic       branch_signal;
    logic       jmp_signal;
    logic       rd_wren;
    logic [1:0] mem_to_reg;
  } id_ex_reg_t;

  typedef struct packed {
    word_t      pc;
    word_t      inst;
    word_t      alu_result;
    word_t      rs2_data;

    addr_t      rd_addr;

    logic       o_insn_vld;
    logic       mem_wren;
    logic       mem_rden;
    logic       branch_signal;
    logic       jmp_signal;

    logic       rd_wren;
    logic [1:0] mem_to_reg;
  } ex_mem_reg_t;

  typedef struct packed {
    word_t      pc4;
    word_t      alu_result;
    word_t      rs2_data;
    word_t      inst;
    word_t      read_data;

    addr_t      rd_addr;

    logic       o_insn_vld;
    logic       rd_wren;
    logic [1:0] mem_to_reg;
  } mem_wb_reg_t;
// Register
// LCR - Line Control Reg - Đây là thanh ghi "cài đặt cấu hình"
   typedef struct packed {
      logic       dlab;         // Bit 7: Divisor Latch Access Bit
      logic       set_break;    // Bit 6: Break Control
      logic       force_parity; // Bit 5
      logic       even_parity;  // Bit 4: EPS
      logic       parity_en;    // Bit 3: PEN
      logic       stop_bits;    // Bit 2: STB
      logic [1:0] word_len;     // Bit 1:0: WLS (2 bit)
   } lcr_t;
// RHR - Receiver Holding Register
   typedef struct packed {
      logic [7:0] received_data;     // Bit 7:0:
   } rhr_t;
// THR - Transmit Holding Register
   typedef struct packed {
      logic [7:0] transmit_data;     // Bit 7:0:
   } thr_t;
// IER - Interrupt Enable Register
   typedef struct packed {
      logic       dma_txend;      // Bit 7
      logic       dma_rxend;      // Bit 6
      logic [1:0] reseverd;       // Bit 5, 4 = 0
      logic       modem_status;   // Bit 3:
      logic       rx_line_status; // Bit 2
      logic       thr_empty;      // Bit 1
      logic       data_ready;     // Bit 0
   } ier_t;
// ISR - Interrupt Status Register
   typedef struct packed {
      logic       tx_fifo_en;    // Bit 7
      logic       rx_fifo_en;    // Bit 6
      logic       dma_tx_end;    // Bit 5
      logic       dma_rx_end;    // Bit 4
      logic [2:0] itr_iden_code; // Bit 3, 2, 1
      logic       itr_status;    // Bit 0
   } isr_t;
// FCR - FIFO Control Register 
   typedef struct packed {
      logic [1:0] rx_trig_lvl; // Bit 7, 6
      logic       reserved;    // Bit 5
      logic       dma_end_en;  // Bit 4
      logic       dma_mode;    // Bit 3
      logic       tx_fifo_rst; // Bit 2
      logic       rx_fifo_rst; // Bit 1
      logic       fifo_en;     // Bit 0
   } fcr_t;
// MCR - Modem Control Register
   typedef struct packed {
      logic [2:0] reserved;  // Bit 7, 6, 5
      logic       loop_back; // Bit 4
      logic       out2;      // Bit 3
      logic       out1;      // Bit 2
      logic       rts;       // Bit 1
      logic       dtr;       // Bit 0
   } mcr_t;
// LSR - Line Status Register - Đây là "bảng thông báo" trạng thái
   typedef struct packed {
      logic       fifo_data_err; // Bit 7
      logic       tx_empty;      // Bit 6
      logic       thr_empty;     // Bit 5
      logic       break_itr;     // Bit 4
      logic       frame_err;     // Bit 3
      logic       parity_err;    // Bit 2
      logic       overrun_err;   // Bit 1
      logic       data_ready;    // Bit 0
   } lsr_t;
// MSR - Modem Status Register
   typedef struct packed {
      logic       cd;               // Bit 7
      logic       ri;               // Bit 6
      logic       dsr;              // Bit 5
      logic       cts;              // Bit 4
      logic       delta_cd;         // Bit 3
      logic       trailing_edge_ri; // Bit 2
      logic       delta_dsr;        // Bit 1
      logic       delta_cts;        // Bit 0
   } msr_t;
// SPR - Scratch Pad Register
   typedef struct packed {
      logic [7:0] user_data;
   } spr_t;
// DLL - Divisor Latch Least signif. byte
   typedef struct packed {
      logic [7:0] lsb_baud_div;
   } dll_t;
// DLM - Divisor Latch Most signif. byte
   typedef struct packed {
      logic [7:0] msb_baud_div;
   } dlm_t;
// PSD - Prescaler Division
   typedef struct packed {
      logic [3:0] reserved;
      logic [3:0] prescaler_factor;
   } psd_t;
endpackage
