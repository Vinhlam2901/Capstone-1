//===========================================================================================================
// Project         : UART & RVV
// Module          : Hazard Detection for Scalar & Vector
// File            : hazard_detect.sv
// Author          : Chau Tran Vinh Lam - vinhlamchautran572@gmail.com
// Create date     : 24/03/2026
// Updated date    : 24/03/2026
//============================================================================================================
import package_param::*;

module hazard_detect (
  input  wire [4:0]  id_rs1_addr,
  input  wire [4:0]  id_rs2_addr,
  input  wire [4:0]  ex_rs1_addr,
  input  wire [4:0]  ex_rs2_addr,
  input  wire [4:0]  ex_rd_addr,
  input  wire        ex_mems_rden,
  input  wire [4:0]  mem_rd_addr,
  input  wire        mem_scalar_wren,
  input  wire [4:0]  wb_rd_addr,
  input  wire        wb_scalar_wren, 
  input  wire [4:0]  id_vrs1_addr,
  input  wire [4:0]  id_vrs2_addr,
  input  wire [4:0]  ex_vrs1_addr,
  input  wire [4:0]  ex_vrs2_addr,
  input  wire [4:0]  ex_vrd_addr,
  input  wire        ex_mem_vrden,
  input  wire [4:0]  mem_vrd_addr,
  input  wire        mem_vector_wren,
  input  wire [4:0]  wb_vrd_addr,
  input  wire        wb_vector_wren,
  output reg  [1:0]  vrs1_forwarding_sel,
  output reg  [1:0]  vrs2_forwarding_sel,
  output reg  [1:0]  rs1_forwarding_sel,
  output reg  [1:0]  rs2_forwarding_sel,
  output reg         vector_stall,
  output reg         scalar_stall
);

//=====================SCALAR===========================================================================================================================
  //==================FORWARDING_CONTROL===========================================================================================================================
  always_comb begin : scalar_forwarding_detect
    rs1_forwarding_sel = 2'b00;
    rs2_forwarding_sel = 2'b00;

    if (mem_scalar_wren && (mem_rd_addr != 5'b0) && (mem_rd_addr == ex_rs1_addr)) begin
      rs1_forwarding_sel = 2'b10;
    end else if (wb_scalar_wren && (wb_rd_addr != 5'b0) && (wb_rd_addr == ex_rs1_addr)) begin
      rs1_forwarding_sel = 2'b01;
    end

    if (mem_scalar_wren && (mem_rd_addr != 5'b0) && (mem_rd_addr == ex_rs2_addr)) begin
      rs2_forwarding_sel = 2'b10;
    end else if (wb_scalar_wren && (wb_rd_addr != 5'b0) && (wb_rd_addr == ex_rs2_addr)) begin
      rs2_forwarding_sel = 2'b01;
    end
  end

  //==================STALL_CONTROL===============================================================================================================================================================================================================
  always_comb begin : scalar_stall_detect
    scalar_stall = 1'b0;
    
    // Load-Use Hazard:
    if(ex_mems_rden && (ex_rd_addr != 5'b0) && 
      ((ex_rd_addr == id_rs1_addr) || (ex_rd_addr == id_rs2_addr))) begin
        scalar_stall = 1'b1;
    end
  end

//=====================VECTOR===========================================================================================================================
  //==================FORWARDING_CONTROL===========================================================================================================================
  always_comb begin : vector_forwarding_detect
    vrs1_forwarding_sel = 2'b00;
    vrs2_forwarding_sel = 2'b00;

    if (mem_vector_wren && (mem_vrd_addr != 5'b0) && (mem_vrd_addr == ex_vrs1_addr)) begin
      vrs1_forwarding_sel = 2'b10;
    end else if (wb_vector_wren && (wb_vrd_addr != 5'b0) && (wb_vrd_addr == ex_vrs1_addr)) begin
      vrs1_forwarding_sel = 2'b01;
    end

    if (mem_vector_wren && (mem_vrd_addr != 5'b0) && (mem_vrd_addr == ex_vrs2_addr)) begin
      vrs2_forwarding_sel = 2'b10;
    end else if (wb_vector_wren && (wb_vrd_addr != 5'b0) && (wb_vrd_addr == ex_vrs2_addr)) begin
      vrs2_forwarding_sel = 2'b01;
    end
  end

  //==================STALL_CONTROL===============================================================================================================================================================================================================
  always_comb begin : vector_stall_detect
    vector_stall = 1'b0;
    // Load-Use Hazard
    if(ex_mem_vrden && (ex_vrd_addr != 5'b0) && 
      ((ex_vrd_addr == id_vrs1_addr) || (ex_vrd_addr == id_vrs2_addr))) begin
        vector_stall = 1'b1;
    end
  end
endmodule