`timescale 1ns/1ps

// ==============================================================================
// 1. DRIVER MODULE
// ==============================================================================
module driver_fwd (
  input  logic        i_clk  ,
  input  logic        i_reset,
  output logic [31:0] i_io_sw
);

  initial begin
    i_io_sw = 32'h12345678;
  end

endmodule : driver

// ==============================================================================
// 2. SCOREBOARD MODULE (Logic gốc của bạn)
// ==============================================================================
module scoreboard_fwd (
  input  logic         i_clk     ,
  input  logic         i_reset   ,
  // Input peripherals
  input  logic [31:0]  i_io_sw   ,
  // Output peripherals
  input  logic [31:0]  o_io_ledr ,
  input  logic [31:0]  o_io_ledg ,
  input  logic [ 6:0]  o_io_hex0 ,
  input  logic [ 6:0]  o_io_hex1 ,
  input  logic [ 6:0]  o_io_hex2 ,
  input  logic [ 6:0]  o_io_hex3 ,
  input  logic [ 6:0]  o_io_hex4 ,
  input  logic [ 6:0]  o_io_hex5 ,
  input  logic [ 6:0]  o_io_hex6 ,
  input  logic [ 6:0]  o_io_hex7 ,
  input  logic [31:0]  o_io_lcd  ,
  // Debug
  input  logic         o_mispred ,
  input  logic [31:0]  o_pc_debug,
  input  logic         o_insn_vld
);


  real num_cycle;      // Number of execution cycles
  real num_insn;       // Number of valid instructions
  real num_ctrl;       // Number of control transfer instructions
  real num_mispred;    // Number of Misprediction
  real ipc;            // Instructino Per Cycle
  real misprd_rate;    // Misprediction Rate

  // Display test name
  initial begin
    $display("\nPIPELINE - ISA tests\n");
  end


  always @(negedge i_clk) begin : counters
      if (!i_reset) begin
        num_cycle   <= '0;
        num_ctrl    <= '0;
        num_insn    <= '0;
        num_mispred <= '0;
      end
      else begin
        num_cycle   <=              num_cycle   + 1;
        num_insn    <= o_insn_vld ? num_insn    + 1 : num_insn;
        num_mispred <= o_mispred  ? num_mispred + 1 : num_mispred;
      end
  end


  always @(negedge i_clk) begin : debug
      if (o_insn_vld && (o_pc_debug == 32'h18)) begin
          $write("%s", o_io_ledr[7:0]);
      end
  end


  always @(negedge i_clk) begin : result
      if (o_insn_vld && ((o_pc_debug == 32'h1c) || (o_pc_debug == 32'h20))) begin
        $display("\n=================== Result ===================");
        if (num_cycle != 0) $display("Total Clock Cycles Executed = %1.0f", num_cycle);
        else                $display("Total Clock Cycles Executed = N/A");

        if (num_insn  != 0) $display("Total Instructions Executed = %1.0f", num_insn);
        else                $display("Total Instructions Executed = N/A");

        if (num_cycle != 0) $display("Total Branch Mispredictions = %1.0f", num_mispred);
        else                $display("Total Branch Mispredictions = N/A");
        $display("\n----------------------------------------------");
        if (num_cycle != 0) $display("Instruction Per Cycle (IPC) = %1.2f", num_insn/num_cycle);
        else                $display("Instruction Per Cycle (IPC) = N/A");
        $display("\nEND of ISA tests\n");
        $finish;
      end
  end



endmodule : scoreboard

// ==============================================================================
// 3. TOP LEVEL TESTBENCH
// ==============================================================================
`define RESET_PERIOD 51
`define CLOCK_PERIOD 2
`define TIMEOUT      50_000

module tbench_fwd;

  // Clock and reset generator
  logic clk;
  logic rstn;

  initial tsk_clock_gen(clk , `CLOCK_PERIOD);
  initial tsk_reset    (rstn, `RESET_PERIOD);
  initial tsk_timeout  (`TIMEOUT);
  // TASK: Clock Generator
  task automatic tsk_clock_gen(ref logic i_clk, input int CLOCK_PERIOD);
    begin
      i_clk = 1'b0;
      forever #(CLOCK_PERIOD) i_clk = !i_clk;
    end
  endtask

  // TASK: Reset is low active for a period of "RESET_PERIOD"
  task automatic tsk_reset(ref logic i_reset, input int RESET_PERIOD);
    begin
      i_reset = 1'b0; // Easter Egg
      #(RESET_PERIOD);
      i_reset = 1'b1; //
    end
  endtask

  // TASK: Timeout, assume after a period of "TIMEOUT",
  // the design is supposed to be "PASSED"
  task automatic tsk_timeout(input int TIMEOUT);
    begin
      #TIMEOUT;
      $display("\nTimeout...\n");
      $finish;
    end
  endtask
  // Wave dumping
  initial begin: proc_dump_shm
      $shm_open("wave.shm");
      $shm_probe(pipeline_fwd, "AS");// ASM 
  end

  logic [31:0]  pc_debug;
  logic [31:0]  io_sw  ;
  logic [31:0]  io_lcd ;
  logic [31:0]  io_ledr;
  logic [31:0]  io_ledg;
  logic [ 6:0]  io_hex0;
  logic [ 6:0]  io_hex1;
  logic [ 6:0]  io_hex2;
  logic [ 6:0]  io_hex3;
  logic [ 6:0]  io_hex4;
  logic [ 6:0]  io_hex5;
  logic [ 6:0]  io_hex6;
  logic [ 6:0]  io_hex7;
  logic         mispred ;
  logic         insn_vld;

  pipelined_fwd pipeline_fwd (
    .i_clk     (clk      ),
    .i_reset   (rstn     ),
    // Input peripherals
    .i_io_sw   (io_sw    ),
    // Output peripherals
    .o_io_lcd  (io_lcd   ),
    .o_io_ledr (io_ledr  ),
    .o_io_ledg (io_ledg  ),
    .o_io_hex0 (io_hex0  ),
    .o_io_hex1 (io_hex1  ),
    .o_io_hex2 (io_hex2  ),
    .o_io_hex3 (io_hex3  ),
    .o_io_hex4 (io_hex4  ),
    .o_io_hex5 (io_hex5  ),
    .o_io_hex6 (io_hex6  ),
    .o_io_hex7 (io_hex7  ),
    // Debug
    .o_mispred (mispred  ),
    .o_pc_debug(pc_debug ),
    .o_insn_vld(insn_vld )
  );

  driver_fwd driver (
    .i_clk  (clk   ),
    .i_reset(rstn  ),
    .i_io_sw(io_sw )
  );

  scoreboard_fwd  scoreboard(
    .i_clk     (clk      ),
    .i_reset   (rstn     ),
    // Input peripherals
    .i_io_sw   (io_sw    ),
    // Output peripherals
    .o_io_lcd  (io_lcd   ),
    .o_io_ledr (io_ledr  ),
    .o_io_ledg (io_ledg  ),
    .o_io_hex0 (io_hex0  ),
    .o_io_hex1 (io_hex1  ),
    .o_io_hex2 (io_hex2  ),
    .o_io_hex3 (io_hex3  ),
    .o_io_hex4 (io_hex4  ),
    .o_io_hex5 (io_hex5  ),
    .o_io_hex6 (io_hex6  ),
    .o_io_hex7 (io_hex7  ),
    // Debug
    .o_mispred (mispred  ),
    .o_pc_debug(pc_debug ),
    .o_insn_vld(insn_vld )
  );


endmodule