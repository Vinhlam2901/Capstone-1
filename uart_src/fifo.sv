//===========================================================================================================
// Project         : UART & RVV
// Module          : UART RX FIFO
// Author          : Chau Tran Vinh Lam
// Create date     : 18/1/2026
// Updated date    : 31/01/2025
//=============================================================================================================
// import package_param::*;
module fifo #(
  parameter DATA_WIDTH = 8,
  parameter ADDR_WIDTH = 4  // 2^4 = 16 phần tử (Depth)
)(
  input   wire                  i_clk,
  input   wire                  ni_rst,
  input   wire                  fifo_en,
  input   wire                  i_wren,
  input   wire                  i_rden,
  input   wire [DATA_WIDTH-1:0] wrdata,
  output  wire [DATA_WIDTH-1:0] rddata,
  output  reg                   o_full,
  output  reg                   o_empty
);
  reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];
  reg [ADDR_WIDTH:0]   wr_ptr, rd_ptr, ptr_wraddr, ptr_rdaddr;             // 1 extend bit to check the phase of ptr
  reg [ADDR_WIDTH:0]   element_count;
  reg                  wr_en, rd_en;

  initial begin
    for (int i = 0; i < (1<<ADDR_WIDTH); i++) begin
      mem[i] = {DATA_WIDTH{1'b0}};
    end
  end
  // logic combination for checking i_wren
  always_comb begin
    element_count = wr_ptr - rd_ptr;

    if (fifo_en) begin
        o_full = (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) && 
                 (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);
    end else begin
        // Mode 0: Full khi ĐÃ CÓ 1 phần tử (Hành vi 16450)
        // Lúc này nó ép CPU/UART TX phải đợi cho đến khi 1 byte này được lấy ra
        o_full = (element_count >= 1);
    end
    wr_en = i_wren && ~o_full;
    rd_en = i_rden && ~o_empty;

    ptr_wraddr = (wr_en) ? (wr_ptr + 1) : wr_ptr;
    ptr_rdaddr = (rd_en) ? (rd_ptr + 1) : rd_ptr;

    o_empty = (rd_ptr == wr_ptr);
  end

  always_ff @( posedge i_clk or negedge ni_rst ) begin
    if(~ni_rst) begin
        wr_ptr <= '0;
        rd_ptr <= '0;
    end else begin
        wr_ptr <= ptr_wraddr;
        rd_ptr <= ptr_rdaddr;
    end
  end

  always_ff @(posedge i_clk) begin: write_port
      if (wr_en) begin
        mem[wr_ptr[ADDR_WIDTH-1:0]] <= wrdata; 
      end
  end

  assign rddata = mem[rd_ptr[ADDR_WIDTH-1: 0]];

endmodule