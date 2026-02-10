//===========================================================================================================
// Project         : UART Protocol
// Module          : UART 16550 IP
// File            : uart_ip.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 21/12/2025
// Updated date    : 10/02/2025
//=============================================================================================================
import package_param::*;
module uart_ip (
  input  wire       i_clk,
  input  wire       ni_rst,
  //uP interface
  input  wire [7:0] i_data,         // data write from laptop
  input  wire [2:0] i_addr,         // select uart's registers
  input  wire       i_cs1,          // chip select 1
  input  wire       i_cs2,          // chip select 2
  input  wire       ni_cs3,         // chip select 3 (negative)
  input  wire       i_ior,          // read_en
  input  wire       ni_ior,         // ~read_en
  input  wire       i_iow,          // write_en
  input  wire       ni_iow,         // write_en (neg)
  output reg  [7:0] o_data,         // data read
  output reg        o_out_vld,      // out valid
  // dma input flags - Direct Memory Access: uart can receive data without cpu process each byte
  input  wire       i_dma_rxend,    // flag when receive data finised
  input  wire       i_dma_txend,    // flag when transmit data finised
  // dma control output
  output reg        o_rxrdy,        // ready to send received data to mem
  output reg        no_rxrdy,       // ready to send received data to mem (neg)
  output reg        o_txrdy,        // ready to receive data from mem
  output reg        no_txrdy,       // ready to receive data from mem (neg)
  // modem control input - read by core
  input  wire       ni_cts,         // clear to send neg flag
  input  wire       ni_dsr,         // data set ready neg flag
  input  wire       ni_ri,          // ring indicator neg flag
  input  wire       ni_dcd,         // data career dectect neg flag
  // modem control output - control by core
  output reg        no_dtr,         // data terminal ready neg flag 
  output reg        no_rts,         // request to send neg flag
  output reg        no_out1,
  output reg        no_out2,
  // serial communication signal
  input  wire       i_rxd,          // assert when no communication - connect to rx pin
  output wire       o_rxd           // assert when no communication - connect to tx pin
);
// addr [2:0]
// 000: RHR Receiver Holding Register - Read Only - holding received data
// 000: THR Transmitter Holding Register - Write Only - holding transmitted data
// 001: IER (Interrupt Enable Register)
// 010: ISR (Interrupt Status Register)
// 010: FCR (FIFO Control Register) - Write Only
// 011: LCR (Line Control Register)
// 100: MCR - Modem Control Register
// 101: LSR (Line Status Register)
// 110: MSR - Modem Status Register
// 111: SPR - Scratch Pad Register
// 000 - DLAB = 1: DLL - Divisor Latch LSB
// 001 - DLAB = 1: DLM - Divisor Latch MSB
// 101 - DLAB = 1: PSD - Prescaler Division
//================================DECLARATION=============================================================================
  reg  [15:0] divisor;
  reg         baudrate_tick;
  reg         lsr_oe_reg;

  lsr_t       lsr_wire;
  ier_t       ier_reg;
  lcr_t       lcr_reg;
  fcr_t       fcr_reg;
  mcr_t       mcr_reg;
  msr_t       msr_reg;
  spr_t       spr_reg;
  dll_t       dll_reg;
  dlm_t       dlm_reg;
  psd_t       psd_reg;
  
  wire  [7:0] fifo_tx_data;
  wire  [7:0] fifo_rx_data;
  wire  [7:0] core_rx_rddata;
  wire  [7:0] core_tx_wrdata;
  wire        chip_sel;
  wire        read_en;
  wire        write_en;
  wire        framing_err;
  wire        fifo_tx_empty;
  wire        fifo_tx_full;
  wire        fifo_rx_empty;
  wire        fifo_rx_full;
  wire        fifo_tx_wren;
  wire        fifo_tx_rden;
  wire        fifo_rx_rden;
  wire        tx_done;
  wire        rx_done;
//========================INSTANTIAION===============================================================================
  baudrate_counter #(.WIDTH(16)) baudrate_16x (
    .i_clk    (i_clk),
    .ni_rst   (ni_rst),
    .i_divisor(divisor),
    .o_tick   (baudrate_tick)
  );

  uart_rx rx (
    .i_clk         (i_clk),
    .ni_rst        (ni_rst),
    .i_rx_signal   (i_rxd),
    .i_s_tick      (baudrate_tick),
    .o_dout        (fifo_rx_data),
    .o_rx_done_tick(rx_done),
    .o_framing_err (framing_err)
  );

  uart_tx tx (
    .i_clk         (i_clk),
    .ni_rst        (ni_rst),
    .i_s_tick      (baudrate_tick),
    .i_fifo_empty  (fifo_tx_empty),
    .i_fifo_data   (fifo_tx_data),
    .o_fifo_rden   (fifo_tx_rden),
    .o_tx_serial   (o_rxd),
    .o_tx_done_tick(tx_done)
  );

  fifo #( .DATA_WIDTH(8), .ADDR_WIDTH(4)) fifo_rx (
    .i_clk    (i_clk),
    .ni_rst   (ni_rst && ~fcr_reg.rx_fifo_rst),
    .fifo_en  (fcr_reg.fifo_en),
    .i_wren   (rx_done),                // uart_rx write enable
    .i_rden   (fifo_rx_rden),           // core read enable
    .wrdata   (fifo_rx_data),           // uart_rx write
    .rddata   (core_rx_rddata),         // core read
    .o_full   (fifo_rx_full),
    .o_empty  (fifo_rx_empty)
  );

  fifo #( .DATA_WIDTH(8), .ADDR_WIDTH(4)) fifo_tx (
    .i_clk    (i_clk),
    .ni_rst   (ni_rst && ~fcr_reg.tx_fifo_rst),
    .fifo_en  (fcr_reg.fifo_en),        
    .i_wren   (fifo_tx_wren),           // core write enable
    .i_rden   (fifo_tx_rden),              // uart_tx read enable
    .wrdata   (i_data),                 // core write
    .rddata   (fifo_tx_data),           // uart_tx read
    .o_full   (fifo_tx_full),
    .o_empty  (fifo_tx_empty)
  );
//===========================================================================================
  assign chip_sel     = i_cs1    && i_cs2         && ~ni_cs3;
  assign read_en      = chip_sel && i_ior         && ~ni_ior;
  assign write_en     = chip_sel && i_iow         && ~ni_iow;
  assign fifo_tx_wren = write_en && ~lcr_reg.dlab && (i_addr == 3'b000);
  assign fifo_rx_rden = read_en  && ~lcr_reg.dlab && (i_addr == 3'b000);
  
  assign divisor      = {dlm_reg.msb_baud_div, dll_reg.lsb_baud_div};

  assign o_txrdy  = ~fifo_tx_full; 
  assign no_txrdy = fifo_tx_full;  // Active Low
  
  assign lsr_wire.overrun_err   = lsr_oe_reg;         // ready to sent to rx_fifo from rx
  assign lsr_wire.data_ready    = ~fifo_rx_empty;     // ready to sent to rx_fifo from rx
  assign lsr_wire.thr_empty     = fifo_tx_empty;   
  assign lsr_wire.parity_err    = 1'b0;                  // Chưa implement Parity
  assign lsr_wire.frame_err     = framing_err; // Đã nối dây framing_err
  assign lsr_wire.break_itr     = 1'b0;
  assign lsr_wire.tx_empty      = fifo_tx_empty && tx_done; // Bit 6: TEMT (Cả FIFO và Shift Reg rỗng)
  assign lsr_wire.fifo_data_err = 1'b0;

  always_ff @(posedge i_clk or negedge ni_rst) begin
    if (!ni_rst) begin
       lsr_oe_reg <= 1'b0;
    end else begin
      if (read_en && (i_addr == 3'b101)) begin
        lsr_oe_reg <= 1'b0; // Đọc thì xóa
      end else if (rx_done && fifo_rx_full) begin
        lsr_oe_reg <= 1'b1; // Tràn thì set
      end
    end
  end
  always_ff @(posedge i_clk or negedge ni_rst) begin: write_reg 
    if (!ni_rst) begin
      ier_reg <= '0;
      lcr_reg <= '0;
      fcr_reg <= '0;
      mcr_reg <= '0;
      spr_reg <= '0;
      dll_reg <= '0;
      dlm_reg <= '0;
      psd_reg <= '0;
    end else begin      
      if (fcr_reg.rx_fifo_rst) begin
        fcr_reg.rx_fifo_rst <= 1'b0;
      end
      if (fcr_reg.tx_fifo_rst) begin
        fcr_reg.tx_fifo_rst <= 1'b0;
      end
      if (write_en) begin
        case (i_addr)
          3'b000: begin
              if(lcr_reg.dlab) begin
                dll_reg <= dll_t'(i_data);          // strict type for struct dll
              end
          end 
          3'b001: begin
              if(lcr_reg.dlab) begin
                dlm_reg <= dlm_t'(i_data);          // strict type for struct dlm
              end else if (~lcr_reg.dlab) begin                
                ier_reg <= ier_t'(i_data);          // strict type for struct ier
              end
          end
          3'b010: begin             
              fcr_reg <= fcr_t'(i_data);          // strict type for struct lcr
          end
          3'b011: begin            
              lcr_reg <= lcr_t'(i_data);          // strict type for struct lcr
          end
          3'b100: begin            
              mcr_reg <= mcr_t'(i_data);          // strict type for struct mcr
          end
          3'b111: begin            
              spr_reg <= spr_t'(i_data);          // strict type for struct spr
          end
          default: ;
       endcase
      end
    end
  end

  always_comb begin : read_reg
    o_data = 8'h00;
    if (read_en) begin
      case (i_addr)
        3'b000: begin
           if (~lcr_reg.dlab) begin
              o_data = core_rx_rddata;
           end else begin
              o_data = dll_reg.lsb_baud_div;
           end
        end
        3'b001: begin
           if (~lcr_reg.dlab) begin
                 o_data = ier_reg;
           end else begin
                 o_data = dlm_reg.msb_baud_div;
           end
        end
        3'b011:  o_data = lcr_reg;
        3'b100:  o_data = mcr_reg;    
        3'b101:  o_data = lsr_wire;   
        3'b110:  o_data = msr_reg;   
        3'b111:  o_data = spr_reg;      
        default: o_data = 8'h00;
      endcase
    end
  end
endmodule