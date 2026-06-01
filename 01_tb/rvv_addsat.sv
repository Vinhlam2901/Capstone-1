`timescale 1ns/1ps

module rvv_addsat;

  // ===================================================================
  // 1. CẤU HÌNH THÔNG SỐ (PARAMETERS)
  // ===================================================================
  parameter CLK_FREQ   = 50_000_000;
  parameter BAUD_RATE  = 3125000; // Fast-forward Baudrate
  parameter BIT_PERIOD = 1_000_000_000 / BAUD_RATE;

  // ===================================================================
  // 2. KHAI BÁO TÍN HIỆU & BIẾN MÔ PHỎNG
  // ===================================================================
  logic clk;
  logic rst_n;
  logic rx;
  logic tx;

  // Biến cho Scoreboard & File I/O
  integer in_file_id, out_file_id, scan_result;
  logic [7:0] img_byte;
  logic [7:0] tx_data;
  
  logic [7:0] gold_mem [0:63]; 
  integer rcv_count = 0;
  integer err_count = 0;
  integer total_test_bytes = 64; // Dùng biến này cho linh hoạt
  
  logic [7:0] expected_val;      // Giá trị kỳ vọng (Gốc + 10)
  // ===================================================================
  // 3. INSTANTIATE MODULE TOP (Thay tên nếu cần)
  // ===================================================================
  pipelined_fwd u_soc (
      .i_clk(clk),
      .i_reset(rst_n),
      .i_uart_rx(rx),
      .o_uart_tx(tx)
  );

  // ===================================================================
  // 4. CLOCK & WAVEFORM
  // ===================================================================
  initial begin
    clk = 0;
    forever #10 clk = ~clk; // Clock 50MHz (Chu kỳ 20ns)
  end

  initial begin
    $shm_open("wave.vcd");
    $shm_probe(rvv_addsat, "ASM");
  end

  // ===================================================================
  // 5. TASK: GỬI 1 BYTE QUA UART RX (Mô phỏng máy tính truyền xuống)
  // ===================================================================
  task send_uart_byte(input logic [7:0] data_byte);
    integer i;
    begin
      rx = 1'b0; #(BIT_PERIOD); // Start bit
      for (i = 0; i < 8; i = i + 1) begin
        rx = data_byte[i]; #(BIT_PERIOD); // 8 Data bits
      end
      rx = 1'b1; #(BIT_PERIOD); // Stop bit
      #(BIT_PERIOD * 2);        // Khoảng nghỉ giữa các byte
    end
  endtask

  // ===================================================================
  // 6. KHỐI THEO DÕI UART TX (MONITOR & SCOREBOARD)
  // ===================================================================
  initial begin
    out_file_id = $fopen("output_dog_addsat.hex", "w");
    forever begin
      @(negedge tx);
      #(BIT_PERIOD / 2); #(BIT_PERIOD);
      for (int i = 0; i < 8; i++) begin
        tx_data[i] = tx; #(BIT_PERIOD);
      end
      
      $fwrite(out_file_id, "%02x\n", tx_data);
      
      if (rcv_count < total_test_bytes) begin
        expected_val = 8'hFF;
        if (tx_data !== expected_val) begin
          $display("[%0t] [ERROR] Pixel %0d | Expect: %02x | Actually: %02x", $time, rcv_count, expected_val, tx_data);
          err_count++;
        end 
      end
      rcv_count++;
    end
  end

  // Luồng chạy chính
  initial begin
    rst_n = 0; rx = 1'b1;
    $readmemh("../01_tb/image_test/dog_correct.hex", gold_mem);
    #100 rst_n = 1; #5000;

    $display("\n[INFO] BAT DAU TRUYEN %0d BYTES...", total_test_bytes);
    
    in_file_id = $fopen("../01_tb/image_test/dog_correct.hex", "r");
    // Chỉ đọc đúng 64 dòng đầu tiên của file
    for (int j = 0; j < total_test_bytes; j++) begin
        scan_result = $fscanf(in_file_id, "%h\n", img_byte);
        if (scan_result == 1) send_uart_byte(img_byte);
    end
    $fclose(in_file_id);
    
    $display("[INFO] DA TRUYEN XONG! Cho RVV xu ly...");

    fork
      wait(rcv_count == total_test_bytes);
      #3500000; // Giảm Timeout xuống 1ms vì 64 byte rất nhanh
    join_any
    disable fork;

    $display("\n==================================================");
    $display(" Tong so byte nhan tu TX    : %0d / %0d", rcv_count, total_test_bytes);
    $display(" Tong so byte BI SAI DATA   : %0d", err_count);
    if (rcv_count == total_test_bytes && err_count == 0)
      $display(" RESULT : *** [ PASS ] ***");
    else
      $display(" RESULT : *** [ FAIL ] ***");
    $display("==================================================\n");
    $finish; 
  end

endmodule